import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:rxdart/rxdart.dart';

import 'call_history_service.dart';

enum CallType { voice, video }

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();

  factory AgoraService() => _instance;

  AgoraService._internal();

  RtcEngine? _engine;
  String? currentChannel;
  String? currentUserId;
  String? receiverUserId;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoEnabled = false;
  bool _isCaller = false;
  final _remoteUserJoinedController = BehaviorSubject<bool>.seeded(false);
  final _callDurationController = BehaviorSubject<Duration>.seeded(
      Duration.zero);
  final _remoteVideoStreamController = BehaviorSubject<Map<int, bool>>.seeded(
      {});
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;
  final CallHistoryService _callHistoryService = CallHistoryService();

  static const String _functionUrl =
      'https://us-central1-zodify-6ff17.cloudfunctions.net/generateRtcToken';
  static const String _apiKey = 'k9m4p7q2r8t3w6z1';

// Getters
  RtcEngine? get engine => _engine;

  Stream<bool> get remoteUserJoined => _remoteUserJoinedController.stream;

  Stream<Duration> get callDuration => _callDurationController.stream;

  Stream<Map<int, bool>> get remoteVideoStream =>
      _remoteVideoStreamController.stream;

  bool get isCaller => _isCaller;

  bool get isMuted => _isMuted;

  bool get isSpeakerOn => _isSpeakerOn;

  bool get isVideoEnabled => _isVideoEnabled;

  bool get isRemoteUserJoined => _remoteUserJoinedController.value;

  Map<int, bool> get currentRemoteVideoState =>
      _remoteVideoStreamController.value;

  void updateRemoteVideoStream(int remoteUid, bool videoEnabled) {
    debugPrint(
        'Updating remote video stream: UID=$remoteUid, VideoEnabled=$videoEnabled');
    _remoteVideoStreamController.add({remoteUid: videoEnabled});
  }

  static const String appId = '2a536a0b8d1f4270b7ee8606e5c5ca1c';

  Future<void> initialize(CallType callType) async {
// Destroy existing engine if it exists
    if (_engine != null) {
      debugPrint('Destroying existing Agora engine...');
      try {
        await _engine!.leaveChannel();
        if (_isVideoEnabled) {
          await _engine!.stopPreview();
          await _engine!.disableVideo();
        }
        await _engine!.disableAudio();
        _engine!.unregisterEventHandler(RtcEngineEventHandler());
        await _engine!.release(sync: true);
        debugPrint('Agora engine released successfully');
      } catch (e) {
        debugPrint('Error releasing Agora engine: $e');
      }
      _engine = null;
      _isVideoEnabled = false;
    }

    if (appId.isEmpty || appId == 'YOUR_AGORA_APP_ID') {
      throw Exception('Invalid Agora App ID. Please provide a valid App ID.');
    }

// Request permissions
    final permissions = [Permission.microphone];
    if (callType == CallType.video) {
      permissions.add(Permission.camera);
    }
    final statuses = await permissions.request();
    if (!statuses[Permission.microphone]!.isGranted) {
      throw Exception('Microphone permission denied');
    }
    if (callType == CallType.video && !statuses[Permission.camera]!.isGranted) {
      throw Exception('Camera permission denied');
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
                'Joined channel: ${connection.channelId}, uid: ${connection
                    .localUid}, elapsed: $elapsed');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined: $remoteUid, channel: ${connection
                .channelId}, localUid: ${connection.localUid}');
            _remoteUserJoinedController.add(true);
            if (callType == CallType.video) {
              updateRemoteVideoStream(remoteUid, true);
            }
            _startCallDurationTimer();
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('Remote user offline: $remoteUid, reason: $reason');
            _remoteUserJoinedController.add(false);
            if (callType == CallType.video) {
              updateRemoteVideoStream(remoteUid, false);
            }
            _stopCallDurationTimer();
            if (currentUserId == null || receiverUserId == null ||
                currentChannel == null) {
              debugPrint('Error: Missing required fields for call history');
              return;
            }
            debugPrint('Saving call history: ended');
            _callHistoryService.saveCallHistory(
              callerName: "Test",
              callerId: currentUserId!,
              receiverId: receiverUserId!,
              channelName: currentChannel!,
              callType: _isVideoEnabled ? 'video' : 'voice',
              status: 'ended',
              durationSeconds: _callDuration.inSeconds,
            );
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora error: $err, $msg');
          },
          onAudioMixingFinished: () {
            debugPrint('Audio mixing finished');
          },
          onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid,
              RemoteVideoState state, RemoteVideoStateReason reason,
              int elapsed) {
            if (callType == CallType.video) {
              debugPrint(
                  'Remote video state changed: $remoteUid, state: $state, reason: $reason');
              bool isVideoOn = state ==
                  RemoteVideoState.remoteVideoStateDecoding ||
                  state == RemoteVideoState.remoteVideoStateStarting;
              updateRemoteVideoStream(remoteUid, isVideoOn);
            }
          },
        ),
      );

// Enable audio for all call types
      await _engine!.enableAudio();
      debugPrint('Audio enabled for $callType');
// Enable video only for video calls
      if (callType == CallType.video) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
        _isVideoEnabled = true;
        debugPrint('Video enabled and preview started');
      }
      _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
// Ensure audio playback and background playing
      await _engine!.setParameters(
          '{"che.audio.allow.background.playing":true}');
      await _engine!.setParameters('{"che.audio.enable.local.playback":true}');
      debugPrint('Agora initialized successfully for $callType');
    } catch (e) {
      debugPrint('Failed to initialize Agora engine: $e');
      throw Exception('Failed to initialize Agora engine: $e');
    }
  }

  Future<void> joinCall(String channelName,
      String userId,
      CallType callType, {
        String? token,
        bool isCaller = false,
        String? receiverId,
      }) async {
    if (_engine == null || _isVideoEnabled != (callType == CallType.video)) {
      await initialize(callType);
    }

    currentChannel = channelName;
    currentUserId = userId;
    receiverUserId = receiverId;
    _isCaller = isCaller;
    final uid = generateUid(userId);

    debugPrint(
        'Joining channel: $channelName with UID: $uid, callType: $callType');
    token ??=
    await getRtcToken(channelName: channelName, isPublisher: true, uid: uid);

    try {
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: callType == CallType.video,
          publishMicrophoneTrack: true,
          publishCameraTrack: callType == CallType.video,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      if (callType == CallType.video && !_isVideoEnabled) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
        _isVideoEnabled = true;
        debugPrint('Video enabled for joinCall');
      }

      debugPrint('Joined channel: $channelName with UID: $uid for $callType');
    } catch (e) {
      debugPrint('Failed to join channel: $e');
      throw Exception('Failed to join channel: $e');
    }
  }

  Future<void> leaveCall() async {
    if (_engine == null) return;
    try {
      await _engine!.stopAudioMixing();
      if (_isVideoEnabled) {
        await _engine!.stopPreview();
        await _engine!.disableVideo();
      }
      await _engine!.leaveChannel();
      debugPrint('Left channel successfully');
    } catch (e) {
      debugPrint('Failed to leave channel: $e');
    }
    currentChannel = null;
    currentUserId = null;
    receiverUserId = null;
    _isVideoEnabled = false;
    _stopCallDurationTimer();
    _remoteUserJoinedController.add(false);
  }

  void toggleMute() {
    if (_engine == null) return;
    _isMuted = !_isMuted;
    _engine!.muteLocalAudioStream(_isMuted);
    debugPrint('Mute toggled: $_isMuted');
  }

  void toggleSpeaker() {
    if (_engine == null) return;
    _isSpeakerOn = !_isSpeakerOn;
    _engine!.setEnableSpeakerphone(_isSpeakerOn);
    debugPrint('Speaker toggled: $_isSpeakerOn');
  }

  void toggleVideo() {
    if (_engine == null || !_isVideoEnabled) {
      debugPrint('Cannot toggle video: engine is null or video is disabled');
      return;
    }
    _isVideoEnabled = !_isVideoEnabled;
    _engine!.muteLocalVideoStream(!_isVideoEnabled);
    debugPrint('Video toggled: $_isVideoEnabled');
  }

  void switchCamera() {
    if (_engine == null || !_isVideoEnabled) {
      debugPrint('Cannot switch camera: engine is null or video is disabled');
      return;
    }
    try {
      _engine!.switchCamera();
      debugPrint('Camera switched successfully');
    } catch (e, stackTrace) {
      debugPrint('Error switching camera: $e\nStackTrace: $stackTrace');
    }
  }

  int generateUid(String userId) {
    try {
      return int.parse(userId);
    } catch (e) {
      return '${userId}_${DateTime
          .now()
          .millisecondsSinceEpoch}'.hashCode.abs() % 1000000;
    }
  }

  Future<String> getAssetFilePath(String assetPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${assetPath
          .split('/')
          .last}');
      if (!await file.exists()) {
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes);
      }
      if (!await file.exists()) {
        throw Exception('Failed to create beep audio file: ${file.path}');
      }
      return file.path;
    } catch (e) {
      debugPrint('Failed to get asset file path: $e');
      throw Exception('Failed to get asset file path: $e');
    }
  }

  Future<void> startBeepAudioMixing(String filePath) async {
    if (_engine == null) return;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Beep audio file does not exist: $filePath');
      }
      await _engine!.startAudioMixing(
        filePath: filePath,
        loopback: true,
        cycle: 1,
        startPos: 0,
      );
      debugPrint('Started audio mixing: $filePath');
    } catch (e) {
      debugPrint('Failed to start audio mixing: $e');
      throw Exception('Failed to start audio mixing: $e');
    }
  }

  Future<void> stopBeepAudioMixing() async {
    if (_engine == null) return;
    try {
      await _engine!.stopAudioMixing();
      debugPrint('Stopped audio mixing');
    } catch (e) {
      debugPrint('Failed to stop audio mixing: $e');
    }
  }

  void _startCallDurationTimer() {
    _stopCallDurationTimer();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration += const Duration(seconds: 1);
      _callDurationController.add(_callDuration);
    });
  }

  void _stopCallDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callDuration = Duration.zero;
    _callDurationController.add(Duration.zero);
  }

  void dispose() {
    _stopCallDurationTimer();
    _engine?.leaveChannel();
    _engine?.stopAudioMixing();
    if (_isVideoEnabled) {
      _engine?.stopPreview();
      _engine?.disableVideo();
    }
    if (_engine != null) {
      _engine!.unregisterEventHandler(RtcEngineEventHandler());
      _engine!.release(sync: true);
      _engine = null;
    }
    _remoteUserJoinedController.close();
    _callDurationController.close();
    _remoteVideoStreamController.close();
    currentChannel = null;
    currentUserId = null;
    receiverUserId = null;
    _isVideoEnabled = false;
    debugPrint('AgoraService disposed');
  }

  Future<String> getRtcToken({
    required String channelName,
    required int uid,
    required bool isPublisher,
    String tokenType = 'uid',
    int expiry = 100000,
  }) async {
    final role = isPublisher ? 'publisher' : 'subscriber';
    final url = Uri.parse(
      '$_functionUrl?channelName=$channelName&role=$role&tokenType=$tokenType&uid=$uid&expiry=$expiry',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'x-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rtcToken'];
      } else {
        final error = jsonDecode(response.body)['error'];
        throw Exception('Failed to get token: $error');
      }
    } catch (e) {
      throw Exception('Error fetching token: $e');
    }
  }
}