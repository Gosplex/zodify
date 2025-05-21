import 'package:astrology_app/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../client/model/user_model.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../common/utils/images.dart';
import '../../services/auth_services.dart';
import '../../services/notification_service.dart';
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardItem> dashboardItems = [
      DashboardItem(
        FontAwesomeIcons.commentDots,
        'Chat',
        Colors.purple,
            () {},
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
      backgroundColor: AppColors.primaryDark,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.power_settings_new,
            color: Colors.red,
            size: 24,
          ),
          onPressed: () {
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
    );
  }

  Widget _buildFeatureCard(DashboardItem item) {
    return GestureDetector(
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
