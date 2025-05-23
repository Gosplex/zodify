import 'package:astrology_app/common/screens/chat_message_screen.dart';
import 'package:astrology_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/common/utils/images.dart';
import 'package:astrology_app/client/model/chat_model.dart';
import 'package:astrology_app/services/message_service.dart';
import 'package:astrology_app/services/user_service.dart';

import '../../client/model/user_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final messageService = MessageService();
    final userService = UserService();
    final String currentUserId = userStore.user!.id!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Chats',
          style: AppTextStyles.heading2(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(AppImages.ic_background_user),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.zodiacGold.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: AppTextStyles.bodyMedium(
                            color: AppColors.textWhite70),
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.textWhite70),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style:
                          AppTextStyles.bodyMedium(color: AppColors.textWhite),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ChatModel>>(
                    stream: messageService.getUserChats(currentUserId),
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
                                            chatId: chatId, receiverId: userId);
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
