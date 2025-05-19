import 'dart:io';

import 'package:astrology_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../client/model/user_model.dart';
import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../common/utils/constants.dart';
import '../../services/auth_services.dart';
import 'astrologer_dashboard_screen.dart';

class AstrologerRegistrationScreen extends StatefulWidget {
  const AstrologerRegistrationScreen({super.key});

  @override
  State<AstrologerRegistrationScreen> createState() =>
      _AstrologerRegistrationScreenState();
}

class _AstrologerRegistrationScreenState
    extends State<AstrologerRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 7;

  // Form data
  String _name = '';
  DateTime? _birthDate;
  String? _gender;
  final List<String> _selectedLanguages = [];
  final List<String> _selectedSkills = [];
  String? _profilePicturePath;
  String _email = '';

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () {
            if (_currentStep > 1) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Step $_currentStep of $_totalSteps',
          style: AppTextStyles.bodyMedium(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary),
            ),
            child: Center(
              child: Text(
                '$_currentStep/$_totalSteps',
                style: AppTextStyles.captionText(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Form content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 1: Name
                _buildStep(
                  question: 'What should we call you?',
                  child: TextField(
                    onChanged: (value) => _name = value,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: AppTextStyles.bodyMedium(),
                  ),
                ),

                // Step 2: Date of Birth
                _buildStep(
                  question: 'When were you born?',
                  child: GestureDetector(
                    onTap: () => _showDatePicker(context),
                    child: AbsorbPointer(
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Select your birth date',
                          hintStyle: AppTextStyles.bodyMedium(),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        controller: TextEditingController(
                          text: _birthDate == null
                              ? ''
                              : DateFormat('d, MMMM y').format(_birthDate!),
                        ),
                      ),
                    ),
                  ),
                ),

                // Step 3: Gender
                _buildStep(
                  question: 'What is your gender?',
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate item width based on available space and the number of items per row
                          final itemWidth = (constraints.maxWidth - 40) / 3; // 3 items with spacing
                          return Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: AppConstants.genders.map((gender) {
                              final icon = gender == 'Male'
                                  ? Icons.male
                                  : gender == 'Female'
                                  ? Icons.female
                                  : Icons.transgender;

                              return GestureDetector(
                                onTap: () => setState(() => _gender = gender),
                                child: SizedBox(
                                  width: itemWidth,
                                  height: itemWidth, // Keep square size
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _gender == gender
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _gender == gender
                                            ? AppColors.primary
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 30,
                                          color: _gender == gender
                                              ? AppColors.primary
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          gender,
                                          style: AppTextStyles.bodyMedium(
                                            color: _gender == gender
                                                ? AppColors.primary
                                                : Colors.black87,
                                            fontWeight: _gender == gender
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  )
                ),

                // Step 4: Languages
                _buildStep(
                  question: 'Which languages do you speak?',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.languages.map((language) {
                      return FilterChip(
                        label: Text(language),
                        checkmarkColor: Colors.white,
                        selected: _selectedLanguages.contains(language),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLanguages.add(language);
                            } else {
                              _selectedLanguages.remove(language);
                            }
                          });
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: AppTextStyles.bodyMedium(
                          color: _selectedLanguages.contains(language)
                              ? Colors.white
                              : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Step 5: Skills
                _buildStep(
                  question: 'What are your astrological skills?',
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      // 2 columns
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.8,
                      // Wider aspect ratio for text
                      children: AppConstants.astrologySkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              isSelected
                                  ? _selectedSkills.remove(skill)
                                  : _selectedSkills.add(skill);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Center(
                              child: Text(
                                skill,
                                textAlign: TextAlign.center,
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Step 6: Profile Picture
                _buildStep(
                  question: 'Upload your profile picture',
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      // Adjust as needed
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _pickProfilePicture,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade100,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                image: _profilePicturePath != null
                                    ? DecorationImage(
                                  image: FileImage(
                                      File(_profilePicturePath!)),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: _profilePicturePath == null
                                  ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: AppColors.primary,
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Tap to upload photo',
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Step 7: Email
                _buildStep(
                  question: 'What\'s your email address?',
                  child: TextField(
                    onChanged: (value) => _email = value,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: AppTextStyles.bodyMedium(),
                  ),
                ),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (_currentStep > 1)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentStep--);
                      },
                      child: Text(
                        'Back',
                        style: AppTextStyles.buttonText(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 1) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (_isCurrentStepValid()) {
                        if (_currentStep < _totalSteps) {
                          FocusScope.of(context).unfocus();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() => _currentStep++);
                        } else {
                          _submitRegistration();
                        }
                      } else {
                        CommonUtilities.showError(context,
                            "Please complete this step before continuing.");
                      }
                    },
                    child: Text(
                      _currentStep == _totalSteps ? 'Submit' : 'Next',
                      style: AppTextStyles.buttonText(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 1:
        return _name
            .trim()
            .isNotEmpty;
      case 2:
        return _birthDate != null;
      case 3:
        return _gender != null;
      case 4:
        return _selectedLanguages.isNotEmpty;
      case 5:
        return _selectedSkills.isNotEmpty;
      case 6:
        return _profilePicturePath != null;
      case 7:
        return _email
            .trim()
            .isNotEmpty &&
            RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_email.trim());
      default:
        return false;
    }
  }

  Widget _buildStep({required String question, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            question,
            style: AppTextStyles.heading2(
              fontSize: 24,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickProfilePicture() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('Choose from Gallery',
                    style: AppTextStyles.bodyMedium()),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _profilePicturePath = pickedFile.path;
                    });
                  }
                },
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('Take a Photo', style: AppTextStyles.bodyMedium()),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _profilePicturePath = pickedFile.path;
                    });
                  }
                },
              ),
              SizedBox(height: 8),
              TextButton(
                child: Text('Cancel',
                    style: AppTextStyles.bodyMedium(color: Colors.grey)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRegistration() async {
    CommonUtilities.showLoader(context);
    await _authService.registerAstrologer(
      bio: "Your Cosmic Guide",
      specialization: "",
      yearsOfExperience: 0,
      name: _name,
      certificationUrl: "",
      idProofUrl: "",
      birthDate: _birthDate!.toIso8601String(),
      gender: _gender,
      languages: _selectedLanguages,
      skills: _selectedSkills,
      profilePicturePath: _profilePicturePath,
      email: _email,
      callback: (success, error) {
        CommonUtilities.removeLoader(context);
        if (success) {
          CommonUtilities.showSuccess(context, 'Registration successful!');
          Navigator.of(context).pushReplacementNamed("/home");
        } else {
          CommonUtilities.showError(context, error ?? 'Registration failed');
        }
      },
    );
  }
}
