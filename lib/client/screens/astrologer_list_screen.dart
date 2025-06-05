import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/common/utils/constants.dart';
import 'package:astrology_app/common/utils/images.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../astrologer/screens/astrologer_profile_screen.dart';
import '../../common/screens/calling_screen.dart';
import '../../common/screens/chat_message_screen.dart';
import '../../common/screens/video_call_screen.dart';
import '../../main.dart';
import '../../services/message_service.dart';
import '../model/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_intake_screen.dart';

class AstrologerListScreen extends StatefulWidget {
  String? route;
  AstrologerListScreen({super.key, this.route});

  @override
  State<AstrologerListScreen> createState() => _AstrologerListScreenState();
}

class _AstrologerListScreenState extends State<AstrologerListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _astrologersFuture=[];
  int selectedSkill=-1;

  @override
  void initState() {
    super.initState();
    print("LISTCalled:::${widget.route}");
    _fetchAstrologers();
  }


  @override
  void dispose() {
    super.dispose();
    _astrologersFuture.clear();
  } // final List<Map<String, dynamic>> astrologers = [
  //  _fetchAstrologers({String? skill}) async {
  //    QuerySnapshot<Map<String, dynamic>> querySnapshot;
  //   try {
  //     if(skill!=null){
  //       querySnapshot = await _firestore
  //           .collection('users')
  //           .where('astrologerProfile', isNotEqualTo: null)
  //           .where('astrologerProfile.status', isEqualTo: 'approved')
  //           .where('astrologerProfile.isOnline', isEqualTo: true)
  //           .where('astrologerProfile.skills', arrayContains: '$skill')
  //           .get();
  //     }else{
  //       querySnapshot = await _firestore
  //           .collection('users')
  //           .where('astrologerProfile', isNotEqualTo: null)
  //           .where('astrologerProfile.status', isEqualTo: 'approved')
  //           .where('astrologerProfile.isOnline', isEqualTo: true)
  //           .get();
  //     }
  //     print("CheckCount::::${querySnapshot.docs.length}");
  //     var tempList= querySnapshot.docs
  //         .map((doc) => UserModel.fromJson(doc.data()))
  //         .toList();
  //
  //     if(widget.route=="chat"){
  //       print("CASE1");
  //       _astrologersFuture = tempList.where((element) =>
  //       element.astrologerProfile?.availability?.available_for_chat == true
  //       ).toList();
  //       setState(() {
  //
  //       });
  //     }else if(widget.route=="call"){
  //       print("CASE2");
  //       tempList.forEach((element) {
  //         if(element.astrologerProfile!.availability!=null && element.astrologerProfile!.availability!.available_for_call==true){
  //           _astrologersFuture.add(element);
  //         }
  //       },);
  //     }else if(widget.route=="video"){
  //       print("CASE3");
  //       tempList.forEach((element) {
  //         if(element.astrologerProfile!.availability!=null && element.astrologerProfile!.availability!.available_for_video==true){
  //           _astrologersFuture.add(element);
  //         }
  //       },);
  //     }else{
  //       _astrologersFuture=tempList;
  //     }
  //     setState(() {
  //
  //     });
  //   } catch (e,s) {
  //     debugPrint('Error fetching astrologers: $e:::$s');
  //     return [];
  //   }
  // }

  _fetchAstrologers({String? skill}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot;

      if (skill != null) {
        querySnapshot = await _firestore
            .collection('users')
            .where('astrologerProfile', isNotEqualTo: null)
            .where('astrologerProfile.status', isEqualTo: 'approved')
            .where('astrologerProfile.skills', arrayContains: skill)
            .get();
      } else {
        querySnapshot = await _firestore
            .collection('users')
            .where('astrologerProfile', isNotEqualTo: null)
            .where('astrologerProfile.status', isEqualTo: 'approved')
            .get();
      }
      print("CheckCount::::${querySnapshot.docs.length}");

      final tempList = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();

      if (widget.route == "chat") {
        print("CASE1");
        _astrologersFuture = tempList.where((element) =>
        element.astrologerProfile?.availability?.available_for_chat == true
        ).toList();

      } else if (widget.route == "call") {
        print("CASE2");
        _astrologersFuture = tempList.where((element) =>
        element.astrologerProfile?.availability?.available_for_call == true
        ).toList();
      } else if (widget.route == "video") {
        print("CASE3");
        _astrologersFuture = tempList.where((element) =>
        element.astrologerProfile?.availability?.available_for_video == true
        ).toList();
      } else {
        _astrologersFuture = tempList;
      }

      setState(() {});
    } catch (e, s) {
      debugPrint('Error fetching astrologers: $e:::$s');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: widget.route==null?BackButton(color: Colors.white,onPressed: (){
          Navigator.pop(context);
        },):SizedBox(),
        title: Text(
          'Astrologer List', // Your app name
          style: AppTextStyles.heading2(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.black,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/user_profile');
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://img.freepik.com/free-psd/spectacular-flight-vivid-green-bird_191095-78393.jpg'),
            ),
          ),
          SizedBox(width: 16),
        ],
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
        child: Column(
          children: [
            // Filter Chips
            Container(
              height: 50,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChipWidget(label: "All",isSelected:selectedSkill==-1,onTapCall:(){
                    selectedSkill=-1;
                    _fetchAstrologers();
                  }),
                  for(int i=0;i<AppConstants.astrologySkills.length;i++)
                  FilterChipWidget(label: AppConstants.astrologySkills[i],isSelected:i==selectedSkill,onTapCall:(){
                    selectedSkill=i;
                    _fetchAstrologers(skill: AppConstants.astrologySkills[i]);
                  }),
                ],
              ),
            ),
            Divider(color: Colors.white30,),
            // Astrologer List
            Expanded(
              child: ListView.builder(
                itemCount: _astrologersFuture.length,
                itemBuilder: (context, index) {
                  final astro = _astrologersFuture[index];
                  return AstrologerCard(astro: astro);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  bool? isSelected;
  var onTapCall;
  FilterChipWidget({required this.label,this.isSelected, required this.onTapCall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          onTapCall();
        },
        child: Chip(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)
          ),
          label: Text(label),
          backgroundColor: isSelected==true?AppColors.primaryLight:Colors.grey,
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class AstrologerCard extends StatelessWidget {
  final UserModel astro;

  const AstrologerCard({required this.astro});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return AstrologerProfileScreen(astrologerId: astro.id!, isUserInteraction: true);
          },
        ));
      },
      child: Card(
        color: Colors.grey.withOpacity(0.4),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                // crossAxisAlignment: CrossAxisAlignment.,
                children: [
                  // Profile Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      astro.astrologerProfile!.imageUrl??'https://img.freepik.com/free-psd/spectacular-flight-vivid-green-bird_191095-78393.jpg',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              children: [
                                Text(astro.name.toString(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                if(astro.astrologerProfile!.status==AstrologerStatus.approved)
                                SizedBox(width: 6),
                                if(astro.astrologerProfile!.status==AstrologerStatus.approved)
                                Icon(Icons.verified, color: Colors.green, size: 16),
                              ],
                            ),
                            Text(
                              astro.isOnline==true? "Online" : "Offline",
                              style: TextStyle(
                                  color: Colors.greenAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.menu_book_sharp,color:Colors.grey),
                            Expanded(
                              child: Text(
                                astro.astrologerProfile!.skills!.join(','),maxLines: 2,overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.language,color:Colors.grey),
                            Expanded(
                              child: Text(
                                '${astro.languages!.join(',')}',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.timelapse_sharp,color:Colors.grey),
                            Text(
                              astro.astrologerProfile!.yearsOfExperience.toString(),
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹ 10',
                              style: TextStyle(color: Colors.white),
                            ),

                            Text(
                              'Wait = 3m',
                              style: TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // // Status
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 4.0),
                  //   child: Column(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     mainAxisSize: MainAxisSize.max,
                  //     crossAxisAlignment: CrossAxisAlignment.end,
                  //     children: [
                  //       Text(
                  //         astro['isOnline'] ? "Online" : "Offline",
                  //         style: TextStyle(
                  //             color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  //       ),
                  //       SizedBox(height: 4),
                  //       Text(
                  //         'Wait = ${astro['waitTime']}',
                  //         style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  //       ),
                  //     ],
                  //   ),
                  // )
                ],
              ),
              Divider(color: Colors.grey[700], height: 20),
              if(astro.astrologerProfile!.availability!=null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if(astro.astrologerProfile!.availability!.available_for_chat)
                  _buildActionButton(Icons.chat, "Chat",onClick: (){
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                      builder: (context) {
                        return ChatIntakeFormScreen(astrologerDetails: astro,);
                      },
                    ));
                  }),
                  if(astro.astrologerProfile!.availability!.available_for_call)
                  _buildActionButton(Icons.call, "Call",onClick:(){
                    MessageService messageService = MessageService();
                    String chatId=messageService.generateChatId(userStore.user!.id!, astro.id??'');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallingScreen(
                          receiverId: astro.id??'',
                          receiverImageUrl: astro.astrologerProfile?.imageUrl??'',
                          isVideoCall: false,
                          channelName: 'call_${chatId}',
                        ),
                      ),
                    );
                  }),
                  if(astro.astrologerProfile!.availability!.available_for_video)
                  _buildActionButton(Icons.video_call, "Video Call", onClick: (){
                    MessageService messageService = MessageService();
                    String chatId=messageService.generateChatId(userStore.user!.id!, astro.id??'');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoCallingScreen(
                          receiverId: astro.id??'',
                          receiverImageUrl: astro.astrologerProfile?.imageUrl??'',
                          channelName: 'call_${chatId}',
                        ),
                      ),
                    );
                  }),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {var onClick}) {
    return ElevatedButton.icon(
      onPressed:  () {
        onClick();
      } ,
      icon: Icon(icon, size: 18,color:Colors.green),
      label: Text(label,style: TextStyle(color: Colors.green),),
      style: ElevatedButton.styleFrom(
        backgroundColor:Colors.grey[800],
        foregroundColor:Colors.white,
        disabledForegroundColor: Colors.white54,
        disabledBackgroundColor: Colors.grey[800],
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: TextStyle(fontSize: 12,),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
