import 'dart:ui';
import 'package:astrology_app/common/extensions/string_extensions.dart';
import 'package:astrology_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../client/model/user_model.dart';
import '../../client/screens/chat_intake_screen.dart';
import '../../common/screens/calling_screen.dart';
import '../../common/screens/chat_message_screen.dart';
import '../../common/screens/video_call_screen.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/images.dart';
import '../../main.dart';
import '../../services/message_service.dart';

class AstrologerProfileScreen extends StatefulWidget {
  final String astrologerId;
  final bool isUserInteraction;

  const AstrologerProfileScreen(
      {super.key, required this.astrologerId, required this.isUserInteraction});

  @override
  State<AstrologerProfileScreen> createState() =>
      _AstrologerProfileScreenState();
}

class _AstrologerProfileScreenState extends State<AstrologerProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<UserModel> _astrologerFuture;
  late TabController _tabController;
  bool isOnline = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _astrologerFuture = _fetchAstrologer();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<UserModel> _fetchAstrologer() async {
    final doc =
    await _firestore.collection('users').doc(widget.astrologerId).get();
    if (!doc.exists) {
      throw Exception('Astrologer not found');
    }
    final data = doc.data() as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        isOnline = data['astrologerProfile']?['isOnline'] ?? false;
      });
    }
    return UserModel.fromJson(data);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.zodiacGold.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.solidStar,
                  color: AppColors.zodiacGold,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '4.5',
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            icon: const FaIcon(
              FontAwesomeIcons.triangleExclamation,
              color: Colors.yellow,
              size: 18,
            ),
          ),
          Visibility(
            visible: widget.isUserInteraction == true ? false : true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 8.0),
              child: SizedBox(
                width: 80,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.3,
                      child: CupertinoSwitch(
                        value: isOnline,
                        activeTrackColor: Colors.green,
                        inactiveTrackColor: Colors.red,
                        onChanged: (value) async {
                          setState(() {
                            isOnline = value;
                          });
                          await _userService.updateAstrologerStatus(
                              widget.astrologerId, value, "Astrologer");
                        },
                      ),
                    ),
                    // Positioned(
                    //   bottom: 0,
                    //   child: Text(
                    //     isOnline ? 'ONLINE' : 'OFFLINE',
                    //     style: AppTextStyles.captionText(
                    //       color: isOnline ? Colors.green[100]! : Colors.red[100]!,
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.w600,
                    //       letterSpacing: 0.5,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Blurred Background (Profile Image)
          FutureBuilder<UserModel>(
            future: _astrologerFuture,
            builder: (context, snapshot) {
              ImageProvider imageProvider =
              const AssetImage(AppImages.ic_background_user);
              if (snapshot.hasData &&
                  snapshot.data!.astrologerProfile != null &&
                  snapshot.data!.astrologerProfile!.imageUrl!.isNotEmpty) {
                imageProvider =
                    NetworkImage(snapshot.data!.astrologerProfile!.imageUrl!);
              }

              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.7),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
          // Body Content
          SafeArea(
            child: FutureBuilder<UserModel>(
              future: _astrologerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.zodiacGold,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading profile',
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.textWhite,
                      ),
                    ),
                  );
                }
                final astrologer = snapshot.data!;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Main Body Container
                    Container(
                      margin: const EdgeInsets.only(top: 80),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 90),
                          // Space for overlapping profile image
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                astrologer.astrologerProfile!.name
                                    .capitalizeFirstWord(),
                                style: AppTextStyles.heading2(
                                  color: AppColors.textWhite,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Image.asset(AppImages.ic_checkmark),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Left: 75 mins
                              Column(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.message,
                                    color: AppColors.textWhite,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '75 mins',
                                    style: AppTextStyles.bodyMedium(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              // Vertical Divider
                              Container(
                                height: 40,
                                width: 1,
                                color: AppColors.zodiacGold.withOpacity(0.5),
                                margin:
                                const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              // Center: 5.3M Followers
                              Column(
                                children: [
                                  Text(
                                    '5.3M',
                                    style: AppTextStyles.bodyMedium(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Followers',
                                    style: AppTextStyles.captionText(
                                      color: AppColors.textWhite70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              // Vertical Divider
                              Container(
                                height: 40,
                                width: 1,
                                color: AppColors.zodiacGold.withOpacity(0.5),
                                margin:
                                const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              // Right: 234 mins
                              Column(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.phone,
                                    color: AppColors.textWhite,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '234 mins',
                                    style: AppTextStyles.bodyMedium(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pricing Button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 48, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '₹25',
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textWhite70,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹20',
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Follow Button
                              GestureDetector(
                                onTap: () {
                                  // Add follow logic here
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 48, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Follow',
                                    style: AppTextStyles.bodyMedium(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Guiding you through the stars ✨ Personalized astrology for clarity, love & success 🌙',
                              style: AppTextStyles.bodyMedium(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TabBar(
                            controller: _tabController,
                            indicator: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.zodiacGold,
                                  width: 3,
                                ),
                              ),
                            ),
                            labelColor: AppColors.textWhite,
                            unselectedLabelColor: AppColors.textWhite70,
                            tabs: const [
                              Tab(
                                icon: Icon(
                                  Icons.dashboard,
                                  size: 24,
                                ),
                              ),
                              Tab(
                                icon: FaIcon(
                                  FontAwesomeIcons.video,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                GridView.builder(
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 4 / 5,
                                    crossAxisSpacing: 0,
                                    mainAxisSpacing: 0,
                                  ),
                                  itemCount: 9,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://i.pravatar.cc/1080?img=${index +
                                                10}',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Videos Grid
                                GridView.builder(
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 4 / 5,
                                    crossAxisSpacing: 0,
                                    mainAxisSpacing: 0,
                                  ),
                                  itemCount: 9,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://i.pravatar.cc/1080?img=$index',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Profile Image (Half overlapping)
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight,
                            width: 4,
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
                          child: Image(
                            image: astrologer.astrologerProfile != null &&
                                astrologer
                                    .astrologerProfile!.imageUrl!.isNotEmpty
                                ? NetworkImage(
                                astrologer.astrologerProfile!.imageUrl!)
                                : const AssetImage(AppImages.ic_male),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  AppImages.ic_male,
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                      ),
                    ),
                    // Action Buttons (Chat, Call, Video)
                    if(astrologer.astrologerProfile!.availability!=null)
                    Visibility(
                      visible: widget.isUserInteraction,
                      child: Positioned(
                        bottom: 36,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Chat Button
                            if(astrologer.astrologerProfile!.availability!.available_for_chat)
                            GestureDetector(
                              onTap: () {
                                MessageService messageService = MessageService();
                                String chatId=messageService.generateChatId(userStore.user!.id!, astrologer.id??'');
                                // Navigator.of(context)
                                //     .push(MaterialPageRoute(
                                //   builder: (context) {
                                //     return ChatMessageScreen(
                                //       chatId: chatId,  receiverId: astrologer.id??'',);
                                //   },
                                // ));
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) {
                                    return ChatIntakeFormScreen(
                                        astrologerDetails: astrologer);
                                  },
                                ));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff764BFA),
                                      Color(0xffA968F6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xffA968F6).withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.solidComment,
                                      color: AppColors.textWhite,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Chat',
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Call Button
                            if(astrologer.astrologerProfile!.availability!.available_for_call)
                            GestureDetector(
                              onTap: () {
                                // Add call logic here
                                MessageService messageService = MessageService();
                                String chatId=messageService.generateChatId(userStore.user!.id!, astrologer.id??'');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CallingScreen(
                                      receiverId: astrologer.id??'',
                                      receiverImageUrl: astrologer.astrologerProfile?.imageUrl??'',
                                      isVideoCall: false,
                                      channelName: 'call_${chatId}',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff764BFA),
                                      Color(0xffA968F6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xffA968F6).withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.phone,
                                      color: AppColors.textWhite,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Call',
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Video Button
                            if(astrologer.astrologerProfile!.availability!.available_for_video)
                            GestureDetector(
                              onTap: () {
                                // Add video logic here
                                MessageService messageService = MessageService();
                                String chatId=messageService.generateChatId(userStore.user!.id!, astrologer.id??'');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoCallingScreen(
                                      receiverId: astrologer.id??'',
                                      receiverImageUrl: astrologer.astrologerProfile?.imageUrl??'',
                                      channelName: 'call_${chatId}',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff764BFA),
                                      Color(0xffA968F6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xffA968F6).withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.video,
                                      color: AppColors.textWhite,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Video',
                                      style: AppTextStyles.bodyMedium(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}