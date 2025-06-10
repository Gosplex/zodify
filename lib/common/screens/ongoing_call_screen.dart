import 'package:astrology_app/client/screens/user_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/services/user_service.dart';
import '../../services/agora_services.dart';

class OngoingCallScreen extends StatefulWidget {
  final String receiverId;
  final String channelName;
  final String? receiverImageUrl;
  final bool isVideoCall;

  const OngoingCallScreen({
    super.key,
    required this.receiverId,
    required this.channelName,
    this.receiverImageUrl,
    this.isVideoCall = false,
  });

  @override
  State<OngoingCallScreen> createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends State<OngoingCallScreen> {
  final AgoraService _agoraService = AgoraService(); // Singleton instance
  final UserService _userService = UserService();
  String _receiverName = 'Astrologer';
  String _receiverImage = '';
  String _callDuration = '00:00';
  bool _isCallJoined = false;

  @override
  void initState() {
    super.initState();
    _initialize();
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
      if (!joined && mounted) {
        Navigator.pop(context);
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
          _receiverImage = user.userProfile ?? widget.receiverImageUrl ?? '';
        });
      }

      // Check if already joined (e.g., from NotificationService)
      if (_agoraService.currentChannel != widget.channelName) {
        await _agoraService.initialize(CallType.voice);
        await _agoraService.joinCall(
          widget.channelName,
          widget.receiverId,
          CallType.voice,
        );
        setState(() {
          _isCallJoined = true;
        });
        debugPrint('Joined Agora call in OngoingCallScreen');
      } else {
        setState(() {
          _isCallJoined = true;
        });
        debugPrint('Already joined Agora call');
      }
    } catch (e) {
      debugPrint('Error initializing call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Future.delayed(const Duration(seconds: 2), () {
        //   if (mounted) Navigator.pop(context);
        // });
      }
    }
  }

  @override
  void dispose() {
    if (_isCallJoined) {
      _agoraService.leaveCall();
    }
    // Do not dispose AgoraService singleton here to avoid affecting other screens
    super.dispose();
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
        child: _receiverImage.isNotEmpty
            ? Image.network(
                _receiverImage,
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
                        onPressed: () {
                          _agoraService.leaveCall();
                          Navigator.pop(context);
                        },
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
                          Text(
                            _callDuration,
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
                        PulseAnimation(
                          child: _buildProfileAvatar(180),
                        ),
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
                          'Ongoing Call',
                          style: AppTextStyles.bodyMedium(
                            color: Colors.white70,
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.zodiacGold,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () {
                          setState(() {
                            _agoraService.toggleMute();
                          });
                        },
                        child: FaIcon(
                          _agoraService.isMuted
                              ? FontAwesomeIcons.microphoneSlash
                              : FontAwesomeIcons.microphone,
                          color: AppColors.textWhite,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.zodiacGold,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () {
                          setState(() {
                            _agoraService.toggleSpeaker();
                          });
                        },
                        child: FaIcon(
                          _agoraService.isSpeakerOn
                              ? FontAwesomeIcons.volumeHigh
                              : FontAwesomeIcons.volumeLow,
                          color: AppColors.textWhite,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () {
                          _agoraService.leaveCall();
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                              builder: (context) {
                                return UserDashboardScreen();
                              },
                            ));
                            // Navigator.pop(context);
                          } else {
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                              builder: (context) {
                                return UserDashboardScreen();
                              },
                            ));
                          }
                        },
                        child: const Icon(
                          Icons.call_end,
                          color: AppColors.textWhite,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!_isCallJoined)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
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
