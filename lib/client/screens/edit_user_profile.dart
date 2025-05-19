import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../common/utils/images.dart';
import '../../main.dart';
import '../model/user_model.dart';
import '../../common/utils/constants.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _nameController;
  late TextEditingController _birthDateController;
  late TextEditingController _birthTimeController;
  late TextEditingController _phoneController;
  String? _selectedBirthPlace;
  String? _selectedGender;
  bool _knowsBirthTime = false;
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    final user = userStore.user!;

    _nameController = TextEditingController(text: user.name);
    _birthDateController = TextEditingController(text: user.birthDate);
    _birthTimeController = TextEditingController(text: user.birthTime);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _selectedBirthPlace = user.birthPlace;
    _selectedGender = user.gender;
    _knowsBirthTime = user.knowsBirthTime ?? false;
    _selectedLanguages = user.languages?.toList() ?? [];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.zodiacGold,
              onPrimary: AppColors.textWhite,
              surface: AppColors.primaryDark,
              onSurface: AppColors.textWhite,
            ),
            dialogBackgroundColor: AppColors.primaryDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            CommonUtilities.formatDate(picked.toIso8601String());
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "Select Time",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.zodiacGold,
              onPrimary: AppColors.textWhite,
              surface: AppColors.primaryDark,
              onSurface: AppColors.textWhite,
            ),
            dialogBackgroundColor: AppColors.primaryDark,
            textTheme: Theme.of(context).textTheme.copyWith(
              headlineSmall: TextStyle(color: AppColors.textWhite),
              titleMedium: TextStyle(color: AppColors.textWhite),
              bodyLarge: TextStyle(color: AppColors.textWhite),
            ),
            timePickerTheme: TimePickerThemeData(
              helpTextStyle: TextStyle(
                color: AppColors.textWhite, // Specifically for help text
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      CommonUtilities.showLoader(context);

      final updatedUser = userStore.user!.copyWith(
        name: _nameController.text.trim(),
        gender: _selectedGender,
        birthDate: _birthDateController.text.trim(),
        birthTime: _knowsBirthTime ? _birthTimeController.text.trim() : null,
        knowsBirthTime: _knowsBirthTime,
        birthPlace: _selectedBirthPlace,
        phoneNumber: _phoneController.text.trim(),
        languages: _selectedLanguages,
        // updatedAt: DateTime.now().toIso8601String(),
      );

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updatedUser.toJson());

      // Update MobX store
      userStore.updateUserData(updatedUser);
      // Show success message
      CommonUtilities.showSuccess(context, 'Profile updated successfully');
      Navigator.pop(context);
    } catch (e) {
      CommonUtilities.showError(
          context, 'Failed to update profile: ${e.toString()}');
    } finally {
      CommonUtilities.removeLoader(context);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.captionText(color: AppColors.textWhite70),
          prefixIcon: Icon(icon, color: AppColors.zodiacGold),
          filled: true,
          fillColor: AppColors.primaryDark.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.zodiacGold.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.zodiacGold.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.zodiacGold,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.zodiacGold.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.zodiacGold),
          const SizedBox(width: 12),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: AppColors.primaryDark.withOpacity(0.95), // Set dropdown menu background
              ),
              child: DropdownButton<String>(
                value: value != null && items.contains(value) ? value : null,
                hint: Text(
                  label,
                  style: AppTextStyles.bodyMedium(color: AppColors.textWhite70),
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.zodiacGold),
                underline: const SizedBox(),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectDropdown({
    required String label,
    required IconData icon,
    required List<String> selectedItems,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.zodiacGold.withOpacity(0.3),
          width: 1.0, // Don't forget to specify the width
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56), // Match TextField/Dropdown height
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                List<String> tempSelectedItems = List.from(selectedItems);
                return AlertDialog(
                  backgroundColor: AppColors.primaryDark.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.zodiacGold.withOpacity(0.3)),
                  ),
                  title: Text(
                    'Select Languages',
                    style: AppTextStyles.heading2(color: AppColors.textWhite),
                  ),
                  content: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((item) {
                            return CheckboxListTile(
                              title: Text(
                                item,
                                style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
                              ),
                              value: tempSelectedItems.contains(item),
                              onChanged: (bool? checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    tempSelectedItems.add(item);
                                  } else {
                                    tempSelectedItems.remove(item);
                                  }
                                });
                              },
                              activeColor: AppColors.zodiacGold,
                              checkColor: AppColors.textWhite,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyMedium(color: AppColors.textWhite70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedItems.clear();
                          selectedItems.addAll(tempSelectedItems);
                          onChanged(selectedItems);
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.zodiacGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          child: Row(
            children: [
              Icon(icon, color: AppColors.zodiacGold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedItems.isEmpty ? label : selectedItems.join(', '),
                  style: AppTextStyles.bodyMedium(
                    color: selectedItems.isEmpty ? AppColors.textWhite70 : AppColors.textWhite,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.zodiacGold),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _birthTimeController.dispose();
    _phoneController.dispose();
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
          'Edit Profile',
          style: AppTextStyles.heading2(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
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
            child: Observer(
              builder: (context) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      // Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        readOnly: true,
                        icon: Icons.person,
                      ),
                      // Gender
                      _buildDropdownField(
                        label: 'Gender',
                        icon: Icons.people,
                        value: _selectedGender,
                        items: AppConstants.genders,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                      // Birth Date
                      _buildTextField(
                        controller: _birthDateController,
                        label: 'Birth Date',
                        icon: Icons.cake,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      // Birth Time
                      _buildTextField(
                        controller: _birthTimeController,
                        label: 'Birth Time',
                        icon: Icons.access_time,
                        readOnly: true,
                        onTap: () => _selectTime(context),
                      ),

                      // Birth Place
                      _buildDropdownField(
                        label: 'Birth Place',
                        icon: Icons.place,
                        value: _selectedBirthPlace,
                        items: AppConstants.indianStates,
                        onChanged: (value) {
                          setState(() {
                            _selectedBirthPlace = value;
                          });
                        },
                      ),
                      // Phone Number
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        readOnly: true,
                        keyboardType: TextInputType.phone,
                      ),
                      // Languages
                      _buildMultiSelectDropdown(
                        label: 'Languages',
                        icon: Icons.language,
                        selectedItems: _selectedLanguages,
                        items: AppConstants.languages,
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguages = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.zodiacGold,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.zodiacGold.withOpacity(0.5),
                          ),
                          child: Text(
                            'Save Changes',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
