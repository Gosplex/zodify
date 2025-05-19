import 'package:astrology_app/common/utils/constants.dart';
import 'package:astrology_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../client/model/user_model.dart';
import '../../services/preference_services.dart';
import '../utils/app_text_styles.dart';
import '../utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateBasedOnAuthStatus();
      }
    });
  }


  // Determine navigation based on auth and Firestore document existence
  Future<void> _navigateBasedOnAuthStatus() async {
    try {
      // Check Firebase auth status
      User? user = FirebaseAuth.instance.currentUser;


      if (user != null) {
        // User is authenticated
        await PreferenceService.setLoggedIn(true, userId: user.uid);

        // Check if user document exists in Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          try {
            UserModel userModel = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
            _navigateToHomeScreen(userType: userModel.userType!, userModel: userModel);
          } catch (e, s) {
            debugPrint("Catch block==  $s");
            Navigator.pushReplacementNamed(
                context, '/client_registration');
          }
        } else {
          // Scenario 1: User is signed up but no document (not registered)
          Navigator.pushReplacementNamed(
              context, '/client_registration');
        }
      } else {
        // Scenario 3: User is not signed up
        await PreferenceService.clear();
        _navigateToLoginScreen();
      }
    } catch (e) {
      // Handle errors (e.g., Firestore offline) by navigating to login
      await PreferenceService.clear();
      _navigateToLoginScreen();
    }
  }

  // Navigation methods (replace with your actual routes)
  void _navigateToLoginScreen() {
    Navigator.pushReplacementNamed(context, '/login');
  }


  void _navigateToHomeScreen({required UserType userType, required UserModel userModel}) {
    if (userType == UserType.user) {
      userStore.updateUserData(userModel);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      userStore.updateUserData(userModel);
      Navigator.pushReplacementNamed(context, '/astrologer_home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Zodiac Wheel Icon
                      const Icon(
                        Icons.cyclone,
                        size: 80,
                        color: AppColors.zodiacGold,
                      ),
                      const SizedBox(height: 20),

                      // App Name
                      Text(
                        'Zodify',
                        style: AppTextStyles.heading1(
                          color: AppColors.textWhite,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      // Tagline
                      Text(
                        'Discover Your Cosmic Blueprint',
                        style: AppTextStyles.horoscopeText(
                          color: AppColors.textWhite70,
                          fontSize: 18,
                        ),
                      ),

                      // Loading Indicator
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
