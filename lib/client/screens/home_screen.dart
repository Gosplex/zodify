import 'package:astrology_app/client/screens/user_profile_screen.dart';
import 'package:astrology_app/client/screens/wallet_history_screen.dart';
import 'package:astrology_app/common/utils/constants.dart';
import 'package:astrology_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../../astrologer/screens/astrologer_profile_screen.dart';
import '../../common/screens/chat_history_screen.dart';
import '../../common/screens/chat_message_screen.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../common/utils/images.dart';
import '../../main.dart';
import '../../services/auth_services.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../model/user_model.dart';
import 'add_money_screen.dart';
import 'astrologer_list_screen.dart';
import 'chat_intake_screen.dart';

class HomeScreen extends StatefulWidget {
   HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<UserModel>> _astrologersFuture;
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    initializeNotifications();
    _astrologersFuture = _fetchAstrologers();
    _userService.updateUserStatus(userStore.user!.id!, true, "User");
  }

  Future<void> initializeNotifications() async {
    try {
      debugPrint('Initializing notifications in HomeScreen...');
      await _notificationService.initialize(navigatorKey);
      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<List<UserModel>> _fetchAstrologers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('astrologerProfile', isNotEqualTo: null)
          .where('astrologerProfile.status', isEqualTo: 'approved')
          .where('astrologerProfile.isOnline', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching astrologers: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    Color backgroundWhiteOpacity = Colors.white.withOpacity(0.3);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.primaryDark2,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          }, // Add settings functionality
        ),
        title: Text(
          'ZODIFY', // Your app name
          style: AppTextStyles.heading2(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (context) => AddMoneyScreen(),));
              Navigator.push(context, MaterialPageRoute(builder: (context) => WalletHistoryScreen(),));
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white60,
                border: Border.all(color: Colors.white,),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                spacing: 2,
                children: [
                  Icon(Icons.wallet,size:14,color:AppColors.primary),
                  Padding(
                    padding:EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(true?CommonUtilities.formatCurrency(
                        userStore.user?.walletBalance):"₹ ${userStore.user?.walletBalance}",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),),
                  ),
                  Icon(Icons.add_circle,size:14,color:AppColors.primary)
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/user_profile');
              }, // Add profile tap functionality
              child: Observer(
                builder: (context) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage: userStore.user?.userProfile != null &&
                            userStore.user!.userProfile!.isNotEmpty
                        ? NetworkImage(userStore.user!.userProfile!)
                        : AssetImage(
                            AppImages.ic_male,
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.ic_user_dashboard_background),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54, // Adjust opacity (0-255)
              BlendMode.darken,
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding + 20),
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              // Add space below app bar
              const SizedBox(height: kToolbarHeight + 60),
              StreamBuilder(stream:  FirebaseFirestore.instance
                  .collection('chat_requests')
                  .where('userId', isEqualTo: userStore.user?.id??'')
                  .where('status', whereIn: ['pending', 'accepted'])
                  .snapshots(), builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }
                final requests = snapshot.data!.docs;
                String name=requests[0].data()['astrologerName']??'Astrologer-XYZ';
                String currentStatus=requests[0].data()['status']??'Astrologer-XYZ';
                return Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1), // Light yellow background
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.yellow[700],
                            child: const Icon(Icons.person, size: 30, color: Colors.brown),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("$name",
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                    currentStatus=="accepted"?"Start Chat":
                                    "Waiting To Astrologer Accept.",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: (){
                              print("CheckData CHAT REQ::${requests[0].data()}");
                              if(requests[0].data()['status']=="accepted"){
                                MessageService messageService =
                                MessageService();
                                final chatId =
                                messageService.generateChatId(
                                    userStore.user!.id!, requests[0].data()['astrologerId']);
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) {
                                    return ChatMessageScreen(
                                        chatId: chatId, receiverId: requests[0].data()['astrologerId']);
                                  },
                                ));
                              }else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Waiting For Astrologer to accept your chat request')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blue, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                            child: const Text("Chat",
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                        child:Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey,width: 1.5),
                              shape: BoxShape.circle
                          ),
                          child: Lottie.asset(
                            "assets/animations/alert.json",
                            width: 24,
                            height: 24,
                          ),
                        ),
                        top:0,
                        right:10
                    )
                  ],
                );
              },),

              // Semi-transparent search bar
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: backgroundWhiteOpacity,
              //       borderRadius: BorderRadius.circular(10),
              //       border: Border.all(
              //         color: Colors.white.withOpacity(0.3),
              //         width: 1,
              //       ),
              //     ),
              //     child: TextField(
              //       style: AppTextStyles.bodyMedium(color: Colors.white),
              //       decoration: InputDecoration(
              //         hintText: 'Search astrologers, horoscopes...',
              //         hintStyle: AppTextStyles.bodyMedium(
              //           color: Colors.white.withOpacity(0.7),
              //         ),
              //         suffixIcon: Icon(
              //           FontAwesomeIcons.search,
              //           size: 24,
              //           color: Colors.white.withOpacity(0.7),
              //         ),
              //         border: InputBorder.none,
              //         contentPadding: const EdgeInsets.symmetric(
              //           vertical: 16,
              //           horizontal: 20,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              SizedBox(height: 12,),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatHistoryScreen(),));
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24,vertical: 0),
                  padding: EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.2), // Semi-transparent fill
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueGrey.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Circular Icon Container with matching color
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueGrey.withOpacity(0.3), // More transparent version
                          border: Border.all(
                            color: Colors.blueGrey,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                            FontAwesomeIcons.comments,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                       SizedBox(width: 16),
                      // Feature Name with colored background
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Chat History",
                              style: AppTextStyles.bodyMedium(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Live Astrologers Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Astrologers',
                      style: AppTextStyles.heading2(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) =>AstrologerListScreen() ,));
                        // AstrologerListScreen
                        // Handle "View All" tap
                      },
                      child: Text(
                        'View All',
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.primaryDark2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Astrologers List (Horizontal Scroll)
              SizedBox(
                height: 140,
                child: FutureBuilder<List<UserModel>>(
                  future: _astrologersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Show shimmer during loading
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(left: 24),
                        itemCount: 5,
                        // Number of shimmer placeholders
                        itemBuilder: (context, index) =>
                            _buildAstrologerCardShimmer(index),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading astrologers',
                          style: AppTextStyles.bodyMedium(color: Colors.white),
                        ),
                      );
                    }
                    final astrologers = snapshot.data ?? [];
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 24),
                      itemCount: astrologers.length,
                      itemBuilder: (context, index) {
                        final astrologer = astrologers[index];
                        return _buildAstrologerCard(astrologer);
                      },
                    );
                  },
                ),
              ),
              // Rest of your dashboard content will go here,
              ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    child: Container(
                      // height: 150,
                      decoration: BoxDecoration(
                        color: backgroundWhiteOpacity,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 22, top: 8, bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '50% CASHBACK!',
                                  style: AppTextStyles.heading2(
                                    fontSize: 32,
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'On your next recharge',
                                  style: AppTextStyles.bodyMedium(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Space before button
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed("/wallet_transaction");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    shadowColor:
                                        AppColors.primaryLight.withOpacity(0.5),
                                  ),
                                  child: Text(
                                    'RECHARGE NOW',
                                    style: AppTextStyles.bodyMedium(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Coin Image - Positioned to overflow slightly
                          Positioned(
                            right: -15,
                            bottom: -15,
                            child: Image.asset(
                              AppImages.ic_coin,
                              width: 130,
                              height: 130,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Column(
                    children: [
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 24, right: 24),
                          children: [
                            _buildFeatureCircle(
                                Icon(FontAwesomeIcons.globe,
                                    color: Colors.white, size: 48),
                                "Daily Horoscope"),
                            _buildFeatureCircle(
                                Image.asset(AppImages.ic_free_kundli,
                                    width: 48),
                                "Free Kundli"),
                            _buildFeatureCircle(
                                Image.asset(AppImages.ic_kundli_match,
                                    width: 48),
                                "Kundli Match"),
                            _buildFeatureCircle(
                                Icon(FontAwesomeIcons.blog,
                                    color: Colors.white, size: 48),
                                "Astrology Blog"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Astrologers',
                                style: AppTextStyles.heading2(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (context) =>AstrologerListScreen() ,));
                                }, // Handle view all
                                child: Text(
                                  'View All',
                                  style: AppTextStyles.bodyMedium(
                                    color: AppColors.primaryDark2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Astrologers List
                      // Astrologers List
                      SizedBox(
                        height: 240,
                        child: FutureBuilder<List<UserModel>>(
                          future: _astrologersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.only(left: 24, right: 24),
                                itemCount: 5,
                                // Number of shimmer placeholders
                                itemBuilder: (context, index) =>
                                    _buildAstrologerBigCardShimmer(index),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading astrologers',
                                  style: AppTextStyles.bodyMedium(
                                      color: Colors.white),
                                ),
                              );
                            }
                            final astrologers = snapshot.data ?? [];
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.only(left: 24, right: 24),
                              itemCount: astrologers.length,
                              itemBuilder: (context, index) {
                                final astrologer = astrologers[index];
                                return _buildAstrologerBigCard(astrologer);
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[900], // Dark background
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey[850]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userStore.user?.name??"GuestUser",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    userStore.user?.email??'user@example.com',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.white),
              title: Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(),));
                // Navigate to profile screen
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.history, color: Colors.white),
            //   title: Text('Swith to', style: TextStyle(color: Colors.white)),
            //   onTap: () {
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => ChatHistoryScreen(),));
            //   },
            // ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Perform logout
                CommonUtilities.showCustomDialog(
                  context: context,
                  icon: Icons.power_settings_new,
                  message: 'Are you sure you want to log out?',
                  firstButtonText: 'Cancel',
                  firstButtonCallback: () {},
                  secondButtonText: 'Log Out',
                  secondButtonCallback: () async {
                    await AuthService().signOut(
                      callback: (success, error) {
                        if (success) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                                (route) => false,
                          );
                        } else {
                          CommonUtilities.showError(context, error!);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Reusable circle widget
  Widget _buildFeatureCircle(Widget visualContent, String text) {
    // Split text into words for line breaking
    final words = text.split(' ');

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primaryDark2,
                  AppColors.primaryLight,
                ],
                stops: [0.0, 1.0], // Smooth transition
              ),
            ),
            child: Center(child: visualContent),
          ),
          const SizedBox(height: 8),
          Column(
            children: words
                .map((word) => Text(
                      word,
                      style: AppTextStyles.bodyMedium(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologerBigCard(UserModel astrologer) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // IMAGE CONTAINER
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: astrologer.astrologerProfile?.imageUrl != null &&
                              astrologer.astrologerProfile!.imageUrl!.isNotEmpty
                          ? NetworkImage(
                              astrologer.astrologerProfile!.imageUrl!)
                          : const AssetImage(AppImages.ic_male),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // CONTENT BELOW IMAGE
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        astrologer.astrologerProfile!.name! ?? 'Unknown',
                        style: AppTextStyles.bodyMedium(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs 10/min', // Example pricing logic
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.accentAmber,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (context) {
                                return ChatIntakeFormScreen(astrologerDetails: astrologer,);
                              },
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.3),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Chat Now',
                            style: AppTextStyles.bodyMedium(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologerBigCardShimmer(int index) {
    return Container(
      width: 160, // Fixed width for horizontal scrolling
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          // MAIN OUTER CONTAINER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[800]!.withOpacity(0.3),
              highlightColor: Colors.grey[600]!.withOpacity(0.5),
              child: Column(
                children: [
                  // IMAGE PLACEHOLDER
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),

                  // CONTENT BELOW IMAGE
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // NAME PLACEHOLDER
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // PRICE PLACEHOLDER
                        Container(
                          width: 60,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // BUTTON PLACEHOLDER
                        Container(
                          width: double.infinity,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
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

  Widget _buildAstrologerCard(UserModel astrologer) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return AstrologerProfileScreen(astrologerId: astrologer.id!, isUserInteraction: true);
          },
        ));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Image with Border
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipOval(
              child: Image(
                image: astrologer.astrologerProfile?.imageUrl != null &&
                    astrologer.astrologerProfile!.imageUrl!.isNotEmpty
                    ? NetworkImage(astrologer.astrologerProfile!.imageUrl!)
                    : const AssetImage(AppImages.ic_women_profile),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset(AppImages.ic_women_profile, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Astrologer Name - Now with text wrapping
          SizedBox(
            width: 120, // Match the image width
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                astrologer.astrologerProfile!.name!,
                style: AppTextStyles.bodyMedium(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2, // Allow up to 2 lines
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologerCardShimmer(int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile Image Placeholder
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryLight.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[800]!.withOpacity(0.3),
            highlightColor: Colors.grey[600]!.withOpacity(0.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Name Placeholder
        Shimmer.fromColors(
          baseColor: Colors.grey[800]!.withOpacity(0.3),
          highlightColor: Colors.grey[600]!.withOpacity(0.5),
          child: Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
