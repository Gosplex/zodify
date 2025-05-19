import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/common/utils/common.dart';
import 'package:astrology_app/common/utils/images.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/app_text_styles.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _verificationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _verifyPhoneNumber() async {
    CommonUtilities.removeKeyboardFocus(context);
    CommonUtilities.showLoader(context);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          // Navigate to home screen on successful verification
        },
        verificationFailed: (FirebaseAuthException e) {
          CommonUtilities.removeLoader(context);
          CommonUtilities.showError(context, e.message!);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            CommonUtilities.removeLoader(context);
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                verificationId: verificationId,
                phoneNumber: _phoneController.text.trim(),
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _verificationId = verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      CommonUtilities.removeLoader(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: [
              // Purple top section
              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Welcome text
                      Text(
                        'Welcome back!',
                        style: AppTextStyles.heading2(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        'Login to continue',
                        style: AppTextStyles.bodyMedium(
                          color: Colors.white70,
                        ),
                      ),
                    ],
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

          // White login container
          Positioned(
            top: MediaQuery.of(context).size.height * 0.40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    style: AppTextStyles.bodyMedium(),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: AppTextStyles.bodyMedium(
                        color: Colors.grey,
                      ),
                      prefix: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '+91 ',
                          style: AppTextStyles.bodyMedium(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                      counterText: '',
                      // Hide character counter
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: AppColors.inputBorderFocused),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (value) {
                      if (value.length > 10) {
                        _phoneController.text = value.substring(0, 10);
                        _phoneController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _phoneController.text.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _verifyPhoneNumber();
                      },
                      child: Text(
                        'GET OTP',
                        style: AppTextStyles.buttonText(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // OR divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR',
                          style: AppTextStyles.captionText(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {

                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppImages.ic_google_logo,
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: AppTextStyles.bodyMedium(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text.rich(
                          TextSpan(
                            text: 'By signing up, you agree to our ',
                            style: AppTextStyles.captionText(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTextStyles.captionText(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {},
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTextStyles.captionText(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {},
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
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
}
