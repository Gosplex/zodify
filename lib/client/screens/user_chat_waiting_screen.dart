import 'dart:async';

import 'package:astrology_app/common/extensions/string_extensions.dart';
import 'package:astrology_app/common/screens/chat_message_screen.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/chat_request_model.dart';

class UserChatWaitingScreen extends StatefulWidget {
  final String chatRequestId;
  final String astrologerName;
  final String astrologerImageUrl;
  final String astrologerId;
  final String chatId;

  const UserChatWaitingScreen({
    super.key,
    required this.astrologerName,
    required this.astrologerImageUrl,
    required this.chatId,
    required this.chatRequestId,
    required this.astrologerId,
  });

  @override
  State<UserChatWaitingScreen> createState() => _UserChatWaitingScreenState();
}

class _UserChatWaitingScreenState extends State<UserChatWaitingScreen> {
  late StreamSubscription<DocumentSnapshot> _requestSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupRequestListener();
  }

  void _setupRequestListener() {
    debugPrint("Subscription");
    _requestSubscription = FirebaseFirestore.instance
        .collection('chat_requests')
        .doc(widget.chatRequestId)
        .snapshots()
        .listen((snapshot) {
      if (_isDisposed) return;

      if (snapshot.exists) {
        final chatRequest = ChatRequest.fromJson(snapshot.data() as Map<String, dynamic>);

        if (chatRequest.status == 'accepted') {
          _navigateToChatScreen();
        } else if (chatRequest.status == 'rejected') {
          _handleRejection();
        }
      }
    }, onError: (error) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    });
  }

  void _navigateToChatScreen() {
    if (_isDisposed) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatMessageScreen(
          chatId: widget.chatId,
          receiverId: widget.astrologerId,
        ),
      ),
    );
  }

  void _handleRejection() {
    if (_isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your chat request was rejected')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_waiting_bg.gif',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: NetworkImage(widget.astrologerImageUrl),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.astrologerName.capitalizeFirstWord(),
                    style: AppTextStyles.heading2(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Explore other astrologers while\nawaiting ${widget.astrologerName.split(' ')[0].capitalizeFirstWord()} to accept your chat',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.captionText(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      // Navigate to astrologer listing
                    },
                    child: Text(
                      'Browse Astrologers',
                      style: AppTextStyles.buttonText(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}