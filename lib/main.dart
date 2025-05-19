import 'package:astrology_app/common/store/user_store.dart';
import 'package:astrology_app/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'astrologer/screens/astrologer_dashboard_screen.dart';
import 'astrologer/screens/astrologer_registration_screen.dart';
import 'client/screens/chat_intake_screen.dart';
import 'client/screens/edit_user_profile.dart';
import 'client/screens/user_dashboard_screen.dart';
import 'client/screens/user_profile_screen.dart';
import 'client/screens/user_registration_screen.dart';
import 'client/screens/wallet_history_screen.dart';
import 'common/screens/chat_list_screen.dart';
import 'common/screens/login_screen.dart';
import 'common/screens/splash_screen.dart';
import 'common/screens/user_registration_choice_screen.dart';
import 'common/store/app_store.dart';
import 'firebase_options.dart';

AppStore appStore = AppStore();
UserStore userStore = UserStore();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  SystemUIConfig.setGlobalUI();
  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Astrology App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const UserDashboardScreen(),
        '/astrologer_home': (context) => const AstrologerDashboardScreen(),
        '/astrologer_registration': (context) =>
        const AstrologerRegistrationScreen(),
        '/client_registration': (context) => const UserRegistrationScreen(),
        '/registration_choice': (context) =>
        const UserRegistrationChoiceScreen(),
        '/user_profile': (context) => const UserProfileScreen(),
        '/wallet_transaction': (context) => const WalletHistoryScreen(),
        '/user_edit_profile': (context) => const EditUserProfileScreen(),
        '/chat_list': (context) => const ChatListScreen(),
      },
      home: SplashScreen(),
    );
  }
}

class SystemUIConfig {
  static void setGlobalUI() {
    // Set the system UI mode to edge-to-edge for a fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Configure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ));
  }
}