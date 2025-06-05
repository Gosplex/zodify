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
import '../utils/images.dart';
import 'chat_message_screen.dart';

class ChatHistoryScreen extends StatelessWidget {

  ChatHistoryScreen({super.key,});
  final messageService = MessageService();
  final userService = UserService();
  final String currentUserId = userStore.user!.id!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        leading: BackButton(color: AppColors.textWhite,),
        title: Text('Chat History',style: TextStyle(color:AppColors.textWhite),),
        backgroundColor: Colors.transparent,
      ),
      body:  Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.ic_background_user),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          StreamBuilder<List<ChatModel>>(
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

                      if(userSnapshot.data==null)return SizedBox();
                      return GestureDetector(
                        onTap: (){
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
                        child: Container(
                          margin:  EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            border: Border.all(color: Colors.purpleAccent,width: 0.4,strokeAlign: BorderSide.strokeAlignOutside),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Zodify",
                                style: AppTextStyles.bodyMedium(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          Text(
                          "${userSnapshot.data?.birthPlace}",
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                              Divider(height: 16,color: Colors.white38,),
                              Text(
                                "${DateFormat("dd MMM yyyy hh:mm a").format(DateTime.parse(userSnapshot.data!.createdAt.toString()))}",
                                style: AppTextStyles.bodyMedium(
                                  color: Colors.white,
                                  fontSize: 16,
                                  // fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 16,),
                              _buildRowView(key: "Name",value: userSnapshot.data!.name.toString()),
                              _buildRowView(key: "DOB",value: "${DateFormat("dd MMM yyyy hh:mm a").format(DateTime.parse(userSnapshot.data!.birthDate.toString()))}"),
                              _buildRowView(key: "POB",value: userSnapshot.data!.birthPlace.toString()),
                            ],
                          )
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  _buildRowView({required String key,required String value}) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.sizeOf(navigatorKey!.currentContext!).width/4.5,
          child: Text(
            "$key :",
            style: AppTextStyles.bodyMedium(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
