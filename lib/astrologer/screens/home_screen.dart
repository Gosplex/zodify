import 'package:astrology_app/astrologer/screens/pending_chat_request.dart';
import 'package:astrology_app/client/screens/user_profile_screen.dart';
import 'package:astrology_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../client/model/user_model.dart';
import '../../client/screens/user_dashboard_screen.dart';
import '../../common/screens/chat_history_screen.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../common/utils/images.dart';
import '../../services/auth_services.dart';
import '../../services/notification_service.dart';
import '../../services/preference_services.dart';
import '../../services/user_service.dart';
import 'astrologer_profile_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  bool isCallEnabled = false;
  bool isChatEnabled = false;
  bool isVideoEnabled = false;
  final GlobalKey<ScaffoldState> _scaffoldKeyAstro = GlobalKey<ScaffoldState>();
  Future<void> initializeNotifications() async {
    try {
      debugPrint('Initializing notifications in HomeScreen...');
      await _notificationService.initialize(navigatorKey);
      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  void initState() {
    initializeNotifications();
    _userService.updateUserStatus(userStore.user!.id!, true, "Astrologer");
    _userService.getAstrologerAvailability(userStore.user!.id!,).then((value1) {
      isCallEnabled=value1['available_for_call'];
      isVideoEnabled=value1['available_for_video'];
      isChatEnabled=value1['available_for_chat'];
      setState(() {

      });
    },);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardItem> dashboardItems = [
      DashboardItem(
        FontAwesomeIcons.commentDots,
        'Chat',
        Colors.purple,
            () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRequestsListScreen(),));
            },
      ),
      DashboardItem(
        FontAwesomeIcons.comments,
        'Chat History',
        Colors.blueGrey,
            () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatHistoryScreen(),));
        },
      ),
      DashboardItem(
        FontAwesomeIcons.phone,
        'Calls',
        Colors.blue,
            () {},
      ),
      DashboardItem(
        FontAwesomeIcons.video,
        'Go Live',
        Colors.red,
            () {},
      ),
      DashboardItem(
        FontAwesomeIcons.tag,
        'Offers',
        Colors.orange,
            () {},
      ),
      DashboardItem(
        FontAwesomeIcons.star,
        'My Reviews',
        Colors.yellow,
            () {},
      ),
      DashboardItem(
        FontAwesomeIcons.headset,
        'Support',
        Colors.green,
            () {},
      ),
      DashboardItem(
        FontAwesomeIcons.wallet,
        'Wallet',
        Colors.teal,
            () {},
      ),
      DashboardItem(
        FontAwesomeIcons.gear,
        'Settings',
        Colors.grey,
            () {},
      ),
      DashboardItem(
        FontAwesomeIcons.userCheck,
        'Profile',
        Colors.indigoAccent,
            () {
          debugPrint("Clicked");
          // Use the current context if available, otherwise fall back to navigatorKey
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AstrologerProfileScreen(
                  astrologerId: userStore.user!.id!,
                  isUserInteraction: false,
                ),
              ),
            );
          } else {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => AstrologerProfileScreen(
                  astrologerId: userStore.user!.id!,
                  isUserInteraction: false,
                ),
              ),
            );
          }
        },
      ),
    ];
    return Scaffold(
      key: _scaffoldKeyAstro,
      backgroundColor: AppColors.primaryDark,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () {
            _scaffoldKeyAstro.currentState?.openDrawer();
          }, // Add settings functionality
        ),
        title: Text(
          '${userStore.user!.name!.split(' ')[0].toUpperCase()} ASTROLOGER',
          style: AppTextStyles.heading2(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {},
              icon:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
          ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 5, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              children:[
                SizedBox(
                  height:32
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SwitchListTile(
                        title: Text('Enable Call',style: TextStyle(color: Colors.white),),
                        value: isCallEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            isCallEnabled = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: Text('Enable Chat',style: TextStyle(color: Colors.white),),
                        value: isChatEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            isChatEnabled = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: Text('Enable Video',style: TextStyle(color: Colors.white),),
                        value: isVideoEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            isVideoEnabled = value;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                        child: ElevatedButton(onPressed: (){
                          _userService.updateAstrologerAvailability(userStore.user!.id!,user_availability:{
                            "available_for_call":isCallEnabled,
                            "available_for_video":isVideoEnabled,
                            "available_for_chat":isChatEnabled,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Status Updated Successfully')),
                          );
                        }, child: Text("Save")),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: dashboardItems.length,
                  itemBuilder: (context, index) {
                    return _buildFeatureCard(dashboardItems[index]);
                  },
                )
              ]
            ),
          )
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(hideAstroBtn: true,),));
                // Navigate to profile screen
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.white),
              title: Text('Switch To User', style: TextStyle(color: Colors.white)),
              onTap: () async{
                await PreferenceService.setVal(key: "user_mode", val: "user");
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserDashboardScreen(),));
              },
            ),
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

  Widget _buildFeatureCard(DashboardItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            item.onPressed.call();
          },
          child: Container(
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2), // Semi-transparent fill
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.color.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Icon Container with matching color
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withOpacity(0.3), // More transparent version
                    border: Border.all(
                      color: item.color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Feature Name with colored background
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.name,
                    style: AppTextStyles.bodyMedium(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if(item.name=="Chat")
        StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('chat_requests')
        .where('astrologerId', isEqualTo: userStore?.user?.id)
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
      if(snapshot.data!=null && snapshot.data!.docs.isNotEmpty){
        return  Positioned(
            child:Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle
              ),
              child: Lottie.asset(
                "assets/animations/alert.json",
                width: 24,
                height: 24,
              ),
            ),
            top:0,
            right:0
        );
      }
      return SizedBox();
          },
        )
      ],
    );
  }
}

class DashboardItem {
  final IconData icon;
  final String name;
  final Color color;
  final VoidCallback onPressed;

  DashboardItem(this.icon, this.name, this.color, this.onPressed);
}
