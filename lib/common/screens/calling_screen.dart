import 'dart:async';
import 'package:astrology_app/main.dart';
import 'package:flutter/material.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/services/user_service.dart';
import '../../services/agora_services.dart';
import '../../services/notification_service.dart';
import 'ongoing_call_screen.dart';

class CallingScreen extends StatefulWidget {
  final String receiverId;
  final String channelName;
  final String? receiverImageUrl;
  final bool isVideoCall;

  const CallingScreen({
    super.key,
    required this.receiverId,
    required this.channelName,
    this.receiverImageUrl,
    this.isVideoCall = false,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final AgoraService _agoraService = AgoraService(); // Singleton instance
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  String? _beepFilePath;
  String _receiverName = 'Astrologer';
  CallStatus _callStatus = CallStatus.connecting;
  String _statusText = 'Calling...';
  Duration _callDuration = Duration.zero;
  late Timer _callTimer;
  Timer? _beepTimer;
  Timer? _timeoutTimer;
  bool _isBeeping = false;

  @override
  void initState() {
    super.initState();
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
    _stopBeeping();
    if (_callStatus != CallStatus.connected) {
      _cleanupResources();
    }
    // Do not dispose AgoraService singleton here to avoid affecting other screens
    super.dispose();
  }

  void _startBeeping() {
    if (_isBeeping) return;
    _isBeeping = true;
    _beepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _playBeep();
    });
    debugPrint('Started periodic beeping');
  }

  Future<void> _playBeep() async {
    if (!_isBeeping) {
      debugPrint('Beep skipped: not beeping');
      return;
    }
    try {
      _beepFilePath ??= await _agoraService
          .getAssetFilePath('assets/audio/phone_call_beep.mp3');
      debugPrint('Playing beep: $_beepFilePath');
      await _agoraService.startBeepAudioMixing(_beepFilePath!);
      debugPrint('Beep played successfully');
    } catch (e, stackTrace) {
      debugPrint('Beep error: $e\nStackTrace: $stackTrace');
    }
  }

  Future<void> _stopBeeping() async {
    if (!_isBeeping) {
      debugPrint('Stop beeping skipped: not beeping');
      return;
    }
    _isBeeping = false;
    _beepTimer?.cancel();
    _beepTimer = null;
    try {
      await _agoraService.stopBeepAudioMixing();
      debugPrint('Stopped beeping');
    } catch (e) {
      debugPrint('Stop beep error: $e');
    }
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
          _statusText =
              widget.isVideoCall ? 'Ringing for video call...' : 'Ringing...';
        });
        _startBeeping();
      }

      await _agoraService.initialize(CallType.voice);

      if (receiver?.fcmToken != null) {
        await _notificationService.sendCallNotification(
            receiverId: widget.receiverId,
            channelName: widget.channelName,
            callerName: userStore.user!.name!,
            callerImageUrl: userStore.user!.userProfile ?? "",
            fcmToken: receiver!.fcmToken!,
            callerFcmToken: userStore.user!.fcmToken!,
            callerId: userStore.user!.id!,
            callType: CallType.voice);
      }

      print("Before remoteUserJoined");

      _agoraService.remoteUserJoined.listen(
        (joined) {
          print("Listening... ${joined}");
          if (joined && mounted) {
            setState(() {
              _callStatus = CallStatus.connected;
              _statusText = 'Connected';
            });
            _stopBeeping();
            _timeoutTimer?.cancel();
            _callTimer.cancel();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OngoingCallScreen(
                      receiverId: widget.receiverId,
                      channelName: widget.channelName,
                      isVideoCall: widget.isVideoCall,
                      receiverImageUrl: widget.receiverImageUrl,
                    ),
                  ),
                );
              } else {
                debugPrint("NOT MOUNTED");
              }
            });
          }
        },
        onError: (error) {
          print("Error::: $error");
          _handleError(error.toString());
        },
        onDone: () {
          debugPrint('remoteUserJoined stream closed');
        },
      );

      await _agoraService.joinCall(
        widget.channelName,
        userStore.user!.id!,
        CallType.voice,
      );
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    if (mounted) {
      setState(() {
        _callStatus = CallStatus.failed;
        _statusText = 'Call failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
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
    await _stopBeeping();
    if (mounted) {
      setState(() {
        _callStatus = CallStatus.ending;
        _statusText = 'Ending call...';
      });
    }
    await _cleanupResources();
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
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark.withOpacity(0.9),
                  AppColors.primaryDark.withOpacity(0.95),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _endCall,
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            widget.isVideoCall ? 'Video Call' : 'Voice Call',
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
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_callStatus == CallStatus.ringing)
                          PulseAnimation(
                            child: _buildProfileAvatar(180),
                          )
                        else
                          _buildProfileAvatar(180),
                        const SizedBox(height: 32),
                        Text(
                          _receiverName,
                          style: AppTextStyles.heading1(
                            color: Colors.white,
                            fontSize: 28,
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.red,
                        onPressed: _endCall,
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_callStatus == CallStatus.connecting)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: widget.receiverImageUrl != null
            ? Image.network(
                widget.receiverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Icon(
          widget.isVideoCall ? Icons.videocam : Icons.person,
          size: 60,
          color: Colors.white70,
        ),
      ),
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

class PulseAnimation extends StatefulWidget {
  final Widget child;

  const PulseAnimation({super.key, required this.child});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
