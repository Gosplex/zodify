import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/main.dart';
import 'package:astrology_app/services/agora_services.dart';
import 'package:astrology_app/services/notification_service.dart';
import 'package:astrology_app/services/user_service.dart';

import '../../services/call_history_service.dart';
import 'ongoing_video_calling_screen.dart';

class VideoCallingScreen extends StatefulWidget {
  final String receiverId;
  final String channelName;
  final String? receiverImageUrl;

  const VideoCallingScreen({
    super.key,
    required this.receiverId,
    required this.channelName,
    this.receiverImageUrl,
  });

  @override
  State<VideoCallingScreen> createState() => _VideoCallingScreenState();
}

class _VideoCallingScreenState extends State<VideoCallingScreen> {
  final AgoraService _agoraService = AgoraService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final CallHistoryService _callHistoryService = CallHistoryService();

  String _receiverName = 'Astrologer';
  CallStatus _callStatus = CallStatus.connecting;
  String _statusText = 'Ringing...';
  Duration _callDuration = Duration.zero;
  late Timer _callTimer;
  Timer? _timeoutTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print("CheckData::::${widget.channelName}");
    print("CheckData::::${widget.receiverId}");
    print("CheckData::::${widget.receiverImageUrl}");
    print("CheckData::::${widget.key}");
    _initializeCall();
    _startTimer();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_callStatus != CallStatus.connected && mounted) {
        _handleError('Call timed out: Receiver did not answer');
      }
    });
  }

  @override
  void dispose() {
    _callTimer.cancel();
    _timeoutTimer?.cancel();
    if (_callStatus != CallStatus.connected) {
      _cleanupResources();
    }
    super.dispose();
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStatus == CallStatus.ringing) {
        setState(() {
          _callDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _initializeCall() async {
    try {
      setState(() => _callStatus = CallStatus.connecting);

      final receiver = await _userService.getUserDetails(widget.receiverId);
      if (mounted) {
        setState(() {
          _receiverName = receiver?.name ?? 'Astrologer';
          _callStatus = CallStatus.ringing;
          _statusText = 'Ringing...';
        });
      }

      await _agoraService.initialize(CallType.video);
      setState(() => _isInitialized = true);

      if (receiver?.fcmToken != null) {
        await _notificationService.sendCallNotification(
          receiverId: widget.receiverId,
          channelName: widget.channelName,
          callerName: userStore.user!.name!,
          callerImageUrl: userStore.user!.userProfile ?? "",
          fcmToken: receiver!.fcmToken!,
          callerFcmToken: userStore.user!.fcmToken!,
          callerId: userStore.user!.id!,
          callType: CallType.video,
        );
      }

      debugPrint("Before remoteUserJoined");

      _agoraService.remoteUserJoined.listen((joined) {
        debugPrint("Remote user joined: $joined");
        if (joined && mounted) {
          setState(() {
            _callStatus = CallStatus.connected;
            _statusText = 'Connected';
          });
          _timeoutTimer?.cancel();
          _callTimer.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OngoingVideoCallScreen(
                    receiverId: widget.receiverId,
                    channelName: widget.channelName,
                    receiverImageUrl: widget.receiverImageUrl,
                    isCaller: true,
                  ),
                ),
              );
            }
          });
        }
      }, onError: (error) {
        debugPrint("Error: $error");
        _handleError(error.toString());
      });

      await _agoraService.joinCall(
        widget.channelName,
        userStore.user!.id!,
        CallType.video,
      );
    } catch (e, stackTrace) {
      debugPrint("Initialize call error: $e\nStackTrace: $stackTrace");
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    if (mounted) {
      setState(() {
        _callStatus = CallStatus.failed;
        _statusText = 'Call failed';
      });
      _callHistoryService.saveCallHistory(
        callerId: userStore.user!.id!,
        receiverId: widget.receiverId,
        channelName: widget.channelName,
        callType: 'video',
        status: 'failed',
        durationSeconds: _callDuration.inSeconds,
      );
      Future.delayed(const Duration(seconds: 2), () {

        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _cleanupResources() async {
    try {
      await _agoraService.leaveCall();
    } catch (e) {
      debugPrint('Error cleaning resources: $e');
    }
  }

  Future<void> _endCall() async {
    debugPrint('Ending call...');
    if (mounted) {
      setState(() {
        _callStatus = CallStatus.ending;
        _statusText = 'Ending call...';
      });
    }
    await _cleanupResources();
    await _callHistoryService.saveCallHistory(
      callerId: userStore.user!.id!,
      receiverId: widget.receiverId,
      channelName: widget.channelName,
      callType: 'video',
      status: 'ended',
      durationSeconds: _callDuration.inSeconds,
    );
    if (mounted) {
      debugPrint('Navigating back...');
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Local Video Preview (Full Screen)
          if (_isInitialized)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _agoraService.engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Semi-transparent Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // Call Information and Controls
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 30),
                        onPressed: _endCall,
                      ),
                      Column(
                        children: [
                          Text(
                            'Video Call',
                            style: AppTextStyles.bodyMedium(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          if (_callStatus == CallStatus.ringing)
                            Text(
                              _formatDuration(_callDuration),
                              style: AppTextStyles.bodyMedium(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 48), // Placeholder for symmetry
                    ],
                  ),
                ),

                // Call Info
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _receiverName,
                          style: AppTextStyles.heading1(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusText,
                          style: AppTextStyles.bodyMedium(
                            color: _callStatus == CallStatus.failed
                                ? Colors.red[300]!
                                : Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Control Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
                        isActive: !_agoraService.isMuted,
                        onPressed: () {
                          _agoraService.toggleMute();
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: _agoraService.isVideoEnabled
                            ? Icons.videocam
                            : Icons.videocam_off,
                        isActive: _agoraService.isVideoEnabled,
                        onPressed: () {
                          _agoraService.toggleVideo();
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: Icons.call_end,
                        isActive: true,
                        color: Colors.red,
                        onPressed: _endCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Indicator
          if (_callStatus == CallStatus.connecting && !_isInitialized)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: isActive
          ? Colors.white.withOpacity(0.2)
          : Colors.white.withOpacity(0.1),
      onPressed: onPressed,
      child: Icon(icon, color: color, size: 30),
    );
  }
}

enum CallStatus {
  connecting,
  ringing,
  connected,
  failed,
  ending,
}
