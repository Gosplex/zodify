import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/screens/call_history_screen.dart';
import '../../common/screens/chat_list_screen.dart';
import '../../common/screens/live_streaming_screen.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/app_text_styles.dart';
import 'astrologer_list_screen.dart';
import 'home_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _currentIndex = 0;

  // final List<Widget> _screens = [
  //   const HomeScreen(),
  //   AstrologerListScreen(route:"chat"),
  //   AstrologerListScreen(route:"call"),
  //   AstrologerListScreen(route:"video"),
  // ];

  Widget getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen();
      case 1:
        return AstrologerListScreen(key: ValueKey('chat'), route: "chat");
      case 2:
        return AstrologerListScreen(key: ValueKey('call'), route: "call");
      case 3:
        return AstrologerListScreen(key: ValueKey('video'), route: "video");
      default:
        return HomeScreen();
    }
  }

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: getCurrentScreen(),
      // body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.textWhite,
          unselectedItemColor: AppColors.textWhite70,
          selectedLabelStyle: AppTextStyles.captionText(
            color: AppColors.textWhite,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.captionText(
            color: AppColors.textWhite70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.house_fill,
                  size: 24,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.house_fill,
                  size: 24,
                  color: AppColors.textWhite,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.bubble_left_fill,
                  size: 24,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    CupertinoIcons.bubble_left_fill,
                  size: 24,
                  color: AppColors.textWhite,
                ),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.phone_fill,
                  size: 24,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.phone_fill,
                  size: 24,
                  color: AppColors.textWhite,
                ),
              ),
              label: 'Call',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.videocam_circle_fill,
                  size: 24,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.videocam_circle_fill,
                  size: 24,
                  color: AppColors.textWhite,
                ),
              ),
              label: 'Video Call',
            ),
          ],
        ),
      ),
    );
  }
}