import 'package:astrology_app/client/screens/wallet_history_screen.dart';
import 'package:astrology_app/common/utils/constants.dart';
import 'package:astrology_app/main.dart';
import 'package:astrology_app/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../common/utils/images.dart';
import '../../services/razorpay_service.dart';
import '../../services/wallet_services.dart';
import '../model/user_model.dart';
import '../model/wallet_transaction_model.dart';

class UserProfileScreen extends StatefulWidget {
  bool? hideAstroBtn;
  UserProfileScreen({super.key, this.hideAstroBtn});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<UserModel> _userData;
  TextEditingController amountController = TextEditingController();
  final _razorpayService = RazorpayService();

  final walletService = WalletService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    userStore: userStore,
  );

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
  }

  Future<UserModel> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      throw Exception('User data not found');
    }

    UserModel userData = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    userStore.updateUserData(userData);

    return userData;
  }

  String _calculateZodiacSign(String? birthDate) {
    if (birthDate == null) return "Unknown";

    try {
      final date = DateTime.parse(birthDate);
      final month = date.month;
      final day = date.day;

      if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
        return "Aries";
      }
      if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
        return "Taurus";
      }
      if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
        return "Gemini";
      }
      if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
        return "Cancer";
      }
      if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
      if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
        return "Virgo";
      }
      if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
        return "Libra";
      }
      if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
        return "Scorpio";
      }
      if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
        return "Sagittarius";
      }
      if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
        return "Capricorn";
      }
      if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
        return "Aquarius";
      }
      if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) {
        return "Pisces";
      }
    } catch (e) {
      debugPrint('Error calculating zodiac: $e');
    }
    return "Unknown";
  }

  Future<void> _pickProfilePicture() async {
    await CommonUtilities.showImagePicker(
      context: context,
      onImageSelected: (imagePath) async {
        if (imagePath == null) return;

        try {
          // Show loading indicator
          CommonUtilities.showLoader(context);

          // Upload the image to Firebase Storage
          final downloadUrl = await CommonUtilities.uploadImageToFirebase(
            filePath: imagePath,
            storagePath: 'profile_pictures/${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}',
          );

          // Create updated user model
          final updatedUser = userStore.user?.copyWith(
            userProfile: downloadUrl,
            updatedAt: DateTime.now(),
          );

          print("updated User === $updatedUser");

          if (updatedUser != null) {
            // Update Firestore
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .update(updatedUser.toJson());

            // Update MobX store
            runInAction(() {
              userStore.user = updatedUser;
            });
          }

          // Close the loading dialog
          Navigator.pop(context);

          // Show success message
          CommonUtilities.showSuccess(
              context, 'Profile picture updated successfully');
        } catch (e) {
          // Close the loading dialog if still open
          if (Navigator.canPop(context)) Navigator.pop(context);

          CommonUtilities.showError(
              context, 'Failed to update profile picture: ${e.toString()}');
        }
      },
      iconColor: AppColors.zodiacGold,
      textColor: AppColors.textWhite,
      dividerColor: AppColors.zodiacGold.withOpacity(0.2),
      cancelButtonColor: AppColors.textWhite70,
      textStyle: AppTextStyles.bodyMedium(color: AppColors.textWhite),
      galleryText: 'Choose from Gallery',
      cameraText: 'Take a Photo',
      cancelText: 'Cancel',
      backgroundColor: AppColors.primaryDark.withOpacity(0.95),
    );
  }

  void _showFundWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: AppColors.primaryDark.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.zodiacGold, width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.zodiacGold),
            const SizedBox(width: 12),
            Text(
              'Fund Your Zodify Wallet',
              style: AppTextStyles.heading2(color: AppColors.textWhite),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: AppTextStyles.bodyMedium(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'Enter amount',
                hintStyle:
                    AppTextStyles.bodyMedium(color: AppColors.textWhite70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppColors.zodiacGold.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.zodiacGold),
                ),
                filled: true,
                fillColor: AppColors.primaryDark.withOpacity(0.7),
              ),
              style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      amountController.clear();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.zodiacGold),
                    ),
                    child: Text(
                      'Cancel',
                      style:
                          AppTextStyles.bodyMedium(color: AppColors.zodiacGold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();

                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (amount >= 100) {
                        // Minimum amount check
                        _razorpayService.initPaymentGateway(
                          amount: amount,
                          onSuccess: (paymentId) async {
                            await walletService
                                .updateWalletBalance(amount, paymentId)
                                .whenComplete(
                              () {
                                whenPaymentIsCompleted(amount: amount);
                              },
                            );
                          },
                          onError: (error) {
                            CommonUtilities.showError(context, error);
                          },
                        );
                      } else {
                        CommonUtilities.showError(
                            context, 'Minimum amount is ₹100');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.zodiacGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void whenPaymentIsCompleted({required double amount}) {
    Navigator.pop(context);
    CommonUtilities.removeLoader(context);
    CommonUtilities.showSuccess(
      context,
      '₹${amount.toStringAsFixed(2)} added to wallet!',
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return WalletHistoryScreen();
      },
    ));
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: AppTextStyles.heading2(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.power_settings_new, // Logout icon
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
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(AppImages.ic_background_user),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: FutureBuilder<UserModel>(
              future: _userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.zodiacGold,
                    ),
                  );
                }


                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading profile',
                      style:
                          AppTextStyles.bodyMedium(color: AppColors.textWhite),
                    ),
                  );
                }

                final user = snapshot.data!;
                final zodiacSign = _calculateZodiacSign(user.birthDate);

                return Observer(
                  builder: (context) {
                    return SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Picture
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.zodiacGold,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.zodiacGold.withOpacity(0.5),
                                    blurRadius: 16,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Observer(
                                    builder: (_) => CircleAvatar(
                                      radius: 60,
                                      backgroundImage:
                                          userStore.user?.userProfile != null &&
                                                  userStore.user!.userProfile!
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                  userStore.user!.userProfile!)
                                              : AssetImage(
                                                  user.gender == 'Female'
                                                      ? AppImages.ic_female
                                                      : AppImages.ic_male,
                                                ) as ImageProvider,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryDark
                                            .withOpacity(0.8),
                                        // Dark background for contrast
                                        border: Border.all(
                                          color: AppColors.zodiacGold,
                                          width:
                                              1.5, // Slightly thinner border for smaller size
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.zodiacGold
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            // Smaller blur for compact look
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          FontAwesomeIcons.cameraRetro,
                                          color: AppColors.zodiacGold,
                                          size: 16, // Reduced icon size
                                        ),
                                        onPressed: _pickProfilePicture,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit Profile Picture',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // User Name
                            Text(
                              user.name ?? 'Unknown',
                              style: AppTextStyles.heading2(
                                color: AppColors.textWhite,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            // Zodiac Sign
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star_border,
                                  color: AppColors.zodiacGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  zodiacSign,
                                  style: AppTextStyles.horoscopeText(
                                    color: AppColors.zodiacGold,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Switch Account
                            user.astrologerProfile == null
                                ? Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/astrologer_registration');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.zodiacGold,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.textWhite.withOpacity(0.3),
                                    ),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppColors.zodiacGold.withOpacity(0.3),
                                ),
                                child: Text(
                                  'Become an Astrologer',
                                  style: AppTextStyles.horoscopeText(
                                    color: AppColors.textWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                                : user.astrologerProfile!.status == AstrologerStatus.pending
                                ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.textWhite.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: AppColors.zodiacGold,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Astrologer Application Pending',
                                    style: AppTextStyles.horoscopeText(
                                      color: AppColors.textWhite70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                                :
                            widget.hideAstroBtn==true?SizedBox():
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to astrologer dashboard or switch mode
                                  Navigator.pushNamed(context, '/astrologer_home');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cosmicBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.textWhite.withOpacity(0.3),
                                    ),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppColors.cosmicBlue.withOpacity(0.3),
                                ),
                                child: Text(
                                  'Switch to Astrologer',
                                  style: AppTextStyles.horoscopeText(
                                    color: AppColors.textWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // User Details Cards
                            _buildDetailCard(
                              icon: Icons.cake,
                              title: "Birth Date",
                              value: CommonUtilities.formatDate(user.birthDate),
                            ),
                            const SizedBox(height: 16),

                            _buildDetailCard(
                              icon: Icons.place,
                              title: "Birth Place",
                              value: user.birthPlace ?? 'Not specified',
                            ),
                            const SizedBox(height: 16),

                            _buildDetailCard(
                              icon: Icons.language,
                              title: "Languages",
                              value:
                                  user.languages?.join(", ") ?? 'Not specified',
                            ),
                            const SizedBox(height: 16),

                            _buildDetailCard(
                              icon: Icons.phone,
                              title: "Phone",
                              value: user.phoneNumber ?? '+91 XXXXXXXXXX',
                            ),
                            // const SizedBox(height: 16),
                            // _buildDetailCard(
                            //   icon: Icons.account_balance_wallet,
                            //   title: "Wallet Balance",
                            //   value: CommonUtilities.formatCurrency(
                            //       userStore.user?.walletBalance),
                            //   buttonText: "Fund Wallet",
                            //   onButtonPressed: _showFundWalletDialog,
                            // ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/user_edit_profile');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.mysticPurple,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 48, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                  shadowColor:
                                      AppColors.mysticPurple.withOpacity(0.5),
                                ),
                                child: Text(
                                  'Edit Profile',
                                  style: AppTextStyles.heading2(
                                    color: AppColors.textWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.zodiacGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.zodiacGold,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.captionText(
                    color: AppColors.textWhite70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (buttonText != null && onButtonPressed != null)
            TextButton(
              onPressed: onButtonPressed,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: AppColors.zodiacGold.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.zodiacGold),
                ),
              ),
              child: Text(
                buttonText,
                style: AppTextStyles.buttonText(
                  color: AppColors.zodiacGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
