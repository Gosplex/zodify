import 'package:astrology_app/client/model/user_model.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/main.dart';
import 'package:astrology_app/services/message_service.dart';
import 'package:astrology_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/screens/chat_message_screen.dart';
import '../../services/notification_service.dart';

class AcceptRejectScreen extends StatefulWidget {
  final String requestId;
  final String userId;
  final Map<String, dynamic> requestData;

  const AcceptRejectScreen({
    Key? key,
    required this.requestId,
    required this.userId,
    required this.requestData,
  }) : super(key: key);

  @override
  State<AcceptRejectScreen> createState() => _AcceptRejectScreenState();
}

class _AcceptRejectScreenState extends State<AcceptRejectScreen> {
  bool _isProcessing = false;
  final UserService _userService = UserService();
  final MessageService _messageService = MessageService();

  Future<bool> _checkUserActive() async {
    try {
      final UserModel? user = await _userService.getUserDetails(widget.userId);
      return user != null && (user.isOnline ?? false);
    } catch (e) {
      debugPrint('Error checking user status: $e');
      return false;
    }
  }

  Future<void> _sendAcceptNotification() async {
    try {
      // Get user's FCM token from Firestore

      final UserModel? user = await _userService.getUserDetails(widget.userId);

      final fcmToken = user!.fcmToken;
      if (fcmToken == null) return;

      await NotificationService().sendGenericNotification(
        fcmToken: fcmToken,
        title: 'Chat Request Accepted',
        body: 'Your chat request has been accepted. Tap to chat now!',
        type: 'chat_accepted',
        data: {
          'requestId': widget.requestId,
          'screen': 'chat_screen',
        },
      );
    } catch (e) {
      debugPrint('Error sending accept notification: $e');
    }
  }

  Future<void> _sendRejectNotification() async {
    try {
      // Get user's FCM token from Firestore
      final UserModel? user = await _userService.getUserDetails(widget.userId);

      final fcmToken = user!.fcmToken;

      if (fcmToken == null) return;

      await NotificationService().sendGenericNotification(
        fcmToken: fcmToken,
        title: 'Chat Request Rejected',
        body: 'Your chat request has been rejected.',
        type: 'chat_rejected',
        data: {
          'requestId': widget.requestId,
        },
      );
    } catch (e) {
      debugPrint('Error sending reject notification: $e');
    }
  }

  Future<void> _acceptRequest() async {
    setState(() => _isProcessing = true);

    try {
      final isUserActive = await _checkUserActive();

      if (!isUserActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('User is not active. Request rejected automatically')),
        );
        await _rejectRequest();
        return;
      }

      await FirebaseFirestore.instance
          .collection('chat_requests')
          .doc(widget.requestId)
          .update({'status': 'accepted'});

      // Send acceptance notification
      await _sendAcceptNotification();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatMessageScreen(
            chatId: _messageService.generateChatId(userStore.user!.id!, widget.userId),
            receiverId: widget.userId,
          ),
        ),
      );

      // Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectRequest() async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('chat_requests')
          .doc(widget.requestId)
          .update({'status': 'rejected'});

      // Send rejection notification
      await _sendRejectNotification();

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        '${widget.requestData['firstName'] ?? ''} ${widget.requestData['lastName'] ?? ''}'
            .trim();

    if (widget.requestData.isEmpty) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.zodiacGold)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_waiting_bg.gif',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New Chat Request',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName.isNotEmpty ? userName : 'User ${widget.userId}',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (_isProcessing) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _acceptRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Accept',
                                style: GoogleFonts.exo2(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _rejectRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.times,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reject',
                                style: GoogleFonts.exo2(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
