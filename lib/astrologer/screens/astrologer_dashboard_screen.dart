import 'package:astrology_app/astrologer/screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../common/screens/chat_list_screen.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/images.dart';

class AstrologerDashboardScreen extends StatefulWidget {
  const AstrologerDashboardScreen({super.key});

  @override
  State<AstrologerDashboardScreen> createState() => _AstrologerDashboardScreenState();
}

class _AstrologerDashboardScreenState extends State<AstrologerDashboardScreen> {

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    // const ChatListScreen(), // Placeholder for Chat screen
    const SizedBox(), // Placeholder for Live screen
    const SizedBox(), // Placeholder for Live screen
    const SizedBox(), // Placeholder for Calls screen
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
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
                  Icons.live_tv_rounded,
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
                  Icons.live_tv_rounded,
                  size: 24,
                  color: AppColors.textWhite,
                ),
              ),
              label: 'Live',
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
              label: 'Calls',
            ),
          ],
        ),
      ),
    );
  }
}
