import 'package:astrology_app/main.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/services/agora_services.dart';
import 'package:astrology_app/services/user_service.dart';

class OngoingVideoCallScreen extends StatefulWidget {
  final String receiverId;
  final String channelName;
  final String? receiverImageUrl;
  final bool isCaller;

  const OngoingVideoCallScreen({
    super.key,
    required this.receiverId,
    required this.channelName,
    this.receiverImageUrl,
    required this.isCaller,
  });

  @override
  State<OngoingVideoCallScreen> createState() => _OngoingVideoCallScreenState();
}

class _OngoingVideoCallScreenState extends State<OngoingVideoCallScreen> {
  final AgoraService _agoraService = AgoraService();
  final UserService _userService = UserService();
  String _receiverName = 'Astrologer';
  String _callDuration = '00:00';
  bool _isCallJoined = false;
  bool _remoteUserJoined = false;
  bool _remoteVideoOn = false;
  int? _remoteUid;
  Offset _localVideoPosition = const Offset(16, 80);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
        'Initializing OngoingVideoCallScreen: channel=${widget.channelName}, isCaller=${widget.isCaller}');
    _initialize();
    _setupListeners();
  }

  void _setupListeners() {
    _agoraService.callDuration.listen((duration) {
      if (mounted) {
        setState(() {
          final minutes = duration.inMinutes.toString().padLeft(2, '0');
          final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
          _callDuration = '$minutes:$seconds';
        });
      }
    });

    _agoraService.remoteUserJoined.listen((joined) {
      debugPrint('remoteUserJoined event: $joined');
      if (mounted) {
        setState(() {
          _remoteUserJoined = joined;
          debugPrint('Updated _remoteUserJoined: $_remoteUserJoined');
        });
        if (!joined && _isCallJoined) {
          debugPrint('Remote user left, ending call');
          _agoraService.leaveCall();
          Navigator.pop(context);
        }
      }
    });

    _agoraService.remoteVideoStream.listen((videoState) {
      debugPrint('remoteVideoStream event: $videoState');
      if (mounted && videoState.isNotEmpty) {
        setState(() {
          final newUid = videoState.keys.first;
          final newVideoOn = videoState[newUid] ?? false;
          if (_remoteUid != newUid || _remoteVideoOn != newVideoOn) {
            _remoteUid = newUid;
            _remoteVideoOn = newVideoOn;
            debugPrint(
                'Updated remote video: UID=$_remoteUid, VideoOn=$_remoteVideoOn');
          }
        });
      }
    });
  }

  Future<void> _initialize() async {
    try {
// Fetch receiver details
      final user = await _userService.getUserDetails(widget.receiverId);
      if (user != null && mounted) {
        setState(() {
          _receiverName = user.name ?? 'Astrologer';
        });
      }

// Check initial remote user state
      if (_agoraService.isRemoteUserJoined) {
        setState(() {
          _remoteUserJoined = true;
        });
      }

// Initialize and join call if not already joined
      if (_agoraService.currentChannel != widget.channelName) {
        await _agoraService.initialize(CallType.video);
        await _agoraService.joinCall(
          widget.channelName,
          userStore.user!.id!,
          CallType.video,
          isCaller: widget.isCaller,
          receiverId: widget.receiverId,
        );
        debugPrint(
            'Joined call: channel=${widget.channelName}, isCaller=${widget.isCaller}');
        setState(() {
          _isCallJoined = true;
        });
      } else {
        debugPrint('Already in channel: ${widget.channelName}');
        setState(() {
          _isCallJoined = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing video call: $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isCallJoined) {
      _agoraService.leaveCall();
      debugPrint('Left call and cleaned up resources');
    }
    debugPrint('OngoingVideoCallScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
// Remote Video (Full Screen)
          _buildRemoteVideo(),

// Local Video (Draggable Preview)
          /*if (_isCallJoined)*/ _buildLocalVideo(),

// Header with call info
          _buildHeader(),

// Control buttons
          _buildControlBar(),

// Loading Indicator
          if (!_isCallJoined)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if(_remoteUid != null){
      return AgoraVideoView(
        controller: VideoViewController.remote(

          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    }
    return SizedBox();

    final condition = _remoteUserJoined && _remoteVideoOn && _remoteUid != null;
    debugPrint(
        'Building remote video: UID=$_remoteUid, Joined=$_remoteUserJoined, VideoOn=$_remoteVideoOn, Condition=$condition');
    return condition
        ?
    AgoraVideoView(
            controller: VideoViewController.remote(

              rtcEngine: _agoraService.engine!,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: widget.channelName),
            ),
          )
        : Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.receiverImageUrl != null)
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(widget.receiverImageUrl!),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    _remoteUserJoined
                        ? 'Waiting for video...'
                        : 'Connecting...',
                    style: AppTextStyles.bodyMedium(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _receiverName,
                    style: AppTextStyles.heading1(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildLocalVideo() {
    return Positioned(
      left: _localVideoPosition.dx,
      top: _localVideoPosition.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _localVideoPosition += details.delta;
            _localVideoPosition = Offset(
              _localVideoPosition.dx
                  .clamp(0, MediaQuery.of(context).size.width - 120),
              _localVideoPosition.dy
                  .clamp(0, MediaQuery.of(context).size.height - 160),
            );
          });
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragging ? Colors.blue : Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: _agoraService.isVideoEnabled
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _agoraService.engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _receiverName,
                style: AppTextStyles.heading1(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _callDuration,
                style: AppTextStyles.bodyMedium(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
                isActive: !_agoraService.isMuted,
                onPressed: () {
                  _agoraService.toggleMute();
                  setState(() {});
                },
              ),
              _ControlButton(
                icon: _agoraService.isSpeakerOn
                    ? Icons.volume_up
                    : Icons.volume_off,
                isActive: _agoraService.isSpeakerOn,
                onPressed: () {
                  _agoraService.toggleSpeaker();
                  setState(() {});
                },
              ),
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
              _ControlButton(
                icon: Icons.switch_camera,
                isActive: true,
                onPressed: _agoraService.switchCamera,
              ),
              _ControlButton(
                icon: Icons.call_end,
                isActive: true,
                color: Colors.red,
                onPressed: () {
                  _agoraService.leaveCall();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
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
    return IconButton(
      icon: Icon(icon, color: color, size: 28),
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
        ),
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
      ),
    );
  }
}
