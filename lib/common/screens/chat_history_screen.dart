import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../client/model/chat_model.dart';
import '../../client/model/user_model.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../utils/app_text_styles.dart';
import 'chat_message_screen.dart';

class ChatHistoryScreen extends StatelessWidget {

  ChatHistoryScreen({super.key,});
  final messageService = MessageService();
  final userService = UserService();
  final String currentUserId = userStore.user!.id!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        leading: BackButton(color: AppColors.textWhite,),
        title: Text('Chat History',style: TextStyle(color:AppColors.textWhite),),
        backgroundColor: Colors.grey[900],
      ),
      body:  StreamBuilder<List<ChatModel>>(
        stream: messageService.getUserChatsHistory(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.zodiacGold,
                ));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading chats',
                style: TextStyle(color: AppColors.textWhite),
              ),
            );
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'No chats found',
                style: TextStyle(color: AppColors.textWhite),
              ),
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participants
                  .firstWhere((id) => id != currentUserId);

              return FutureBuilder<UserModel?>(
                future: userService.getUserDetails(otherUserId),
                builder: (context, userSnapshot) {
                  String userName = '';
                  String userId = '';
                  bool isOnline = false;
                  String? imageUrl = '';

                  if (userSnapshot.connectionState ==
                      ConnectionState.done) {
                    if (userSnapshot.hasData) {
                      userId = userSnapshot.data!.id!;
                      userName = userSnapshot.data!.name!;
                      isOnline =
                          userSnapshot.data!.isOnline ?? false;
                      imageUrl = userSnapshot.data!.userProfile;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primaryLight
                                .withOpacity(0.2),
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl == null
                                ? const FaIcon(
                                FontAwesomeIcons.userAstronaut,
                                color: AppColors.zodiacGold)
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryDark,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        userName,
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        chat.lastMessage,
                        style: AppTextStyles.captionText(
                          color: AppColors.textWhite70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(
                                chat.lastMessageTime.toDate()),
                            style: AppTextStyles.captionText(
                              color: AppColors.textWhite70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        MessageService messageService =
                        MessageService();
                        final chatId =
                        messageService.generateChatId(
                            userStore.user!.id!, userId);
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (context) {
                            return ChatMessageScreen(
                                chatId: chatId, receiverId: userId,isHistoryMode:true);
                          },
                        ));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
