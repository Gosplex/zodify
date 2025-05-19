import 'package:astrology_app/common/screens/user_registration_choice_screen.dart';
import 'package:astrology_app/common/utils/common.dart';
import 'package:astrology_app/common/utils/constants.dart';
import 'package:astrology_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:pinput/pinput.dart';

import '../../astrologer/screens/astrologer_dashboard_screen.dart';
import '../../client/model/user_model.dart';
import '../../client/screens/user_dashboard_screen.dart';
import '../../services/auth_services.dart';
import '../../services/preference_services.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  int _resendTimeout = 120;
  String? _appSignature;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    CommonUtilities.showLoader(context);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null && mounted) {
        // Check if user exists in Firestore and get UserModel
        await AuthService().checkUserExists(
          callback: (exists, userModel) async {
            if (mounted && userModel != null) {
              final navigator = Navigator.of(context);

              if (exists) {
                await PreferenceService.setLoggedIn(true, userId: userModel.id);
                userStore.updateUserData(userModel);
                if (userModel.userType == UserType.user) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => UserDashboardScreen(),
                    ),
                        (route) => false,
                  );
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => AstrologerDashboardScreen(),
                    ),
                        (route) => false,
                  );
                }
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  navigator.pushReplacementNamed('/client_registration');
                });
              }
            }
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        CommonUtilities.showError(context, 'Error: ${e.message ?? 'Invalid OTP'}');
      }
    } finally {
      if (mounted) {
        CommonUtilities.removeLoader(context);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resendTimeout = 120);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${widget.phoneNumber}',
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.message}')),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            CommonUtilities.showSuccess(context, "OTP resent successfully!");
          }
        },
        forceResendingToken: widget.resendToken,
        codeAutoRetrievalTimeout: (_) {},
        timeout: const Duration(seconds: 120),
      );
    } catch (e) {
      if (mounted) {
        CommonUtilities.showError(context, "Failed to resend OTP");
      }
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_resendTimeout > 0 && mounted) {
        setState(() => _resendTimeout--);
        _startResendTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    // Customizing the Pinput default style
    final defaultPinTheme = PinTheme(
      width: isSmallScreen ? 40 : 45,
      height: isSmallScreen ? 50 : 60,
      textStyle: AppTextStyles.heading2(fontSize: isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Purple top section - now responsive
              Container(
                height: isSmallScreen ? screenHeight * 0.45 : screenHeight * 0.5,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with responsive sizing
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: isSmallScreen ? 50 : 60,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 20),
                        // Welcome text with responsive font size
                        Text(
                          'Verify OTP',
                          style: AppTextStyles.heading2(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 24 : 28,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        // Subtitle with responsive font size
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Enter the 6-digit code sent to\n+91 ${widget.phoneNumber}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 14 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // White bottom section
              Expanded(
                child: Container(
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // White OTP container - now responsive
          Positioned(
            top: isSmallScreen ? screenHeight * 0.35 : screenHeight * 0.40,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pinput OTP Field
                  Pinput(
                    length: 6,
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                          color: AppColors.inputBorderFocused,
                          width: 2,
                        ),
                      ),
                    ),
                    onCompleted: (pin) => _verifyOtp(),
                    keyboardType: TextInputType.number,
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Resend OTP with responsive font size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code?",
                        style: AppTextStyles.captionText(
                          color: Colors.black87,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _resendTimeout == 0 ? _resendOtp : null,
                        child: Text(
                          'Resend OTP',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 12 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 15 : 20),

                  // Verify Button with responsive height
                  SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 45 : 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final otp = _otpController.text.trim();
                        if (otp.length == 6) {
                          _verifyOtp();
                        }
                      },
                      child: Text(
                        'VERIFY',
                        style: AppTextStyles.buttonText(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 15 : 20),

                  // Timer with responsive font size
                  Text(
                    'Resend available in ${_resendTimeout ~/ 60}:${(_resendTimeout % 60).toString().padLeft(2, '0')}',
                    style: AppTextStyles.captionText(
                      color: Colors.grey,
                      fontSize: isSmallScreen ? 12 : 12,
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
}