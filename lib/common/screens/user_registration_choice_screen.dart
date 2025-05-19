import 'package:flutter/material.dart';
import '../utils/app_text_styles.dart';
import '../utils/colors.dart';

class UserRegistrationChoiceScreen extends StatefulWidget {
  const UserRegistrationChoiceScreen({super.key});

  @override
  State<UserRegistrationChoiceScreen> createState() =>
      _UserRegistrationChoiceScreenState();
}

class _UserRegistrationChoiceScreenState
    extends State<UserRegistrationChoiceScreen> {
  String? _selectedRole; // Tracks 'astrologer' or 'client'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                  'Join the Cosmic Journey',
                  style: AppTextStyles.heading1(
                    color: AppColors.textWhite,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Register as',
                  style: AppTextStyles.horoscopeText(
                    color: AppColors.textWhite70,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 40),

                // Role Selection Circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Astrologer Circle
                    _buildRoleCircle(
                      role: 'astrologer',
                      icon: Icons.star_border,
                      label: 'Astrologer',
                      isSelected: _selectedRole == 'astrologer',
                      onTap: () {
                        setState(() {
                          _selectedRole = 'astrologer';
                        });
                      },
                    ),
                    const SizedBox(width: 32),

                    // Client Circle
                    _buildRoleCircle(
                      role: 'client',
                      icon: Icons.person_outline,
                      label: 'Client',
                      isSelected: _selectedRole == 'client',
                      onTap: () {
                        setState(() {
                          _selectedRole = 'client';
                        });
                      },
                    ),
                  ],
                ),

                const Spacer(),

                // Continue Button
                ElevatedButton(
                  onPressed: _selectedRole != null
                      ? () {
                    // Navigate based on role
                    if (_selectedRole == 'astrologer') {
                      Navigator.pushReplacementNamed(
                          context, '/astrologer_registration');
                    } else {
                      Navigator.pushReplacementNamed(
                          context, '/client_registration');
                    }
                  }
                      : null, // Disabled if no role is selected
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.zodiacGold,
                    disabledBackgroundColor: AppColors.zodiacGold.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.zodiacGold.withOpacity(0.4),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.heading1(
                      color: AppColors.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget for role selection circle
  Widget _buildRoleCircle({
    required String role,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? LinearGradient(
            colors: [
              AppColors.zodiacGold,
              AppColors.zodiacGold.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              AppColors.textWhite.withOpacity(0.2),
              AppColors.textWhite.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? AppColors.zodiacGold
                : AppColors.textWhite.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.zodiacGold.withOpacity(0.5)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? AppColors.textWhite
                  : AppColors.textWhite.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.horoscopeText(
                color: isSelected
                    ? AppColors.textWhite
                    : AppColors.textWhite.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}