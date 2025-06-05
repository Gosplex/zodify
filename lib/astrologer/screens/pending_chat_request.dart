import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../client/model/chat_request_model.dart';
import '../../client/model/user_model.dart';
import '../../common/screens/chat_list_screen.dart';
import '../../common/screens/chat_message_screen.dart';
import '../../common/utils/images.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';

class ChatRequestsListScreen extends StatefulWidget {
  const ChatRequestsListScreen({Key? key}) : super(key: key);

  @override
  State<ChatRequestsListScreen> createState() => _ChatRequestsListScreenState();
}

class _ChatRequestsListScreenState extends State<ChatRequestsListScreen> with SingleTickerProviderStateMixin{
  bool _isProcessing = false;
  final UserService _userService = UserService();
  final MessageService _messageService = MessageService();
  late TabController tabController;


  @override
  Widget build(BuildContext context) {

    final String currentUserId = userStore.user?.id ?? '';
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.white,),
        title: Text('Chat', style: TextStyle(color: AppColors.textWhite)),
        bottom: PreferredSize(preferredSize: Size(double.infinity, 48), child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            // border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(12)
          ),
          child: TabBar(
            controller: tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(),
              dividerHeight: 0,
              onTap: (value) {
                setState(() {

                });
              },
            isScrollable: false,
              padding: EdgeInsets.zero,
              labelColor: Colors.grey,
              tabAlignment: TabAlignment.fill,
              tabs: [
                Container(
                    decoration: tabController.index!=0?null:BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16)
                    ),
                    width: double.infinity,
                    child: Center(child: Text("Active Chat",style: TextStyle(color: AppColors.textWhite,fontSize: 16,fontWeight: FontWeight.w900),))),
                Container(
                    decoration: tabController.index==0?null:BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16)
                    ),
                    width: double.infinity,
                    child: Center(child: Text("Chat Requests",style: TextStyle(color: AppColors.textWhite,fontSize: 16,fontWeight: FontWeight.w900),))),
                // Icon(Icons.cabin),
                // Icon(Icons.abc),
              ],
          ),
        )),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.ic_background_astrologer),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54,
              BlendMode.darken,
            ),
          ),
        ),
        child:TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: tabController,
          children: [
            ChatListScreen(),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_requests')
                    .where('astrologerId', isEqualTo: currentUserId)
                    .where('status', isEqualTo: 'pending') // Only show pending requests
                // .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  print("CheckUserID:::${currentUserId}");
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No chat requests',style: TextStyle(color: AppColors.textWhite),));
                  }

                  final requests = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = requests[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final userName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outlined),
                                SizedBox(width: 8,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName,style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500),),
                                    Row(
                                      children: [
                                        Text(data['gender'].toString(),style: TextStyle(fontSize: 12,color: Colors.grey,fontWeight: FontWeight.w500),),
                                        Text(" | ",style: TextStyle(fontSize: 12,color: Colors.grey,fontWeight: FontWeight.w500),),
                                        Text("DOB:"+data['dob'].toString(),style: TextStyle(fontSize: 12,color: Colors.grey,fontWeight: FontWeight.w500),),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(onPressed: (){
                                  _acceptRequest(reqID: data['id'], userId: data['userId']);
                                }, icon: Icon(Icons.done,color: Colors.green,)),
                                IconButton(onPressed: (){
                                  _rejectRequest(reqID: data['id'], userId: data['userId']);
                                }, icon: Icon(Icons.close,color: Colors.red,)),
                              ],
                            )
                          ],
                        ),
                      );
                      // return ListTile(
                      //   leading: const CircleAvatar(child: Icon(Icons.person)),
                      //   title: Text(userName.isNotEmpty ? userName : 'User ${data['userId']}'),
                      //   subtitle: Text('Requested at: ${data['createdAt'].toDate()}'),
                      //   trailing: const Icon(Icons.chevron_right),
                      //
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (_) => AcceptRejectScreen(
                      //           requestId: doc.id,
                      //           userId: data['userId'],
                      //           requestData: data,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // );
                    },
                  );
                },
              ),
            ),
          ],
        )
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    tabController=TabController(length: 2, vsync: this);
  }

  Future<bool> _checkUserActive(String userId) async {
    try {
      final UserModel? user = await _userService.getUserDetails(userId);
      return user != null && (user.isOnline ?? false);
    } catch (e) {
      debugPrint('Error checking user status: $e');
      return false;
    }
  }

  Future<void> _acceptRequest({required String reqID,required String userId}) async {
    setState(() => _isProcessing = true);

    try {
      final isUserActive = await _checkUserActive(userId);

      if (!isUserActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('User is not active. Request rejected automatically')),
        );
        await _rejectRequest(reqID: reqID,userId: userId);
        return;
      }

      await FirebaseFirestore.instance
          .collection('chat_requests')
          .doc(reqID)
          .update({'status': 'accepted'});
      DocumentSnapshot<Map<String, dynamic>> b1=await FirebaseFirestore.instance
          .collection('chat_requests')
          .doc(reqID)
          .get();
      String msg1="";
      final chatRequest = ChatRequest.fromJson(b1.data() as Map<String, dynamic>);
      msg1+="USER: ${chatRequest.firstName} ${chatRequest.lastName}\n";
      msg1+="GENDER: ${chatRequest.gender}\n";
      msg1+="RELATION SHIP STATUS: ${chatRequest.relationshipStatus}\n";
      msg1+="OCCUPATION: ${chatRequest.occupation}\n";
      msg1+="POB: ${chatRequest.birthPlace}\n";
      msg1+="DOB: ${chatRequest.dob}\n";
      if(chatRequest.tob!=null){
        msg1+="TOB: ${chatRequest.tob}\n";
      }
        msg1+="TOPIC: ${chatRequest.topic}\n";


      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatMessageScreen(
            chatId: _messageService.generateChatId(userStore.user!.id!, userId,),
            initialMsg:msg1,
            receiverId: userId,
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

  Future<void> _rejectRequest({required String reqID,required String userId}) async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('chat_requests')
          .doc(reqID)
          .update({'status': 'rejected'});

      // Send rejection notification
      await _sendRejectNotification(reqID: reqID,userId:userId );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendRejectNotification({required String reqID,required String userId}) async {
    try {
      // Get user's FCM token from Firestore
      final UserModel? user = await _userService.getUserDetails(userId);

      final fcmToken = user!.fcmToken;

      if (fcmToken == null) return;

      await NotificationService().sendGenericNotification(
        fcmToken: fcmToken,
        title: 'Chat Request Rejected',
        body: 'Your chat request has been rejected.',
        type: 'chat_rejected',
        data: {
          'requestId': reqID,
        },
      );
    } catch (e) {
      debugPrint('Error sending reject notification: $e');
    }
  }


}
