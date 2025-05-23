import 'package:astrology_app/client/screens/user_dashboard_screen.dart';
import 'package:astrology_app/common/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../main.dart';
import '../../services/preference_services.dart';
import '../model/user_model.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 7;
  var _searchCityController=TextEditingController();
  // Form data
  String _name = '';
  String? _gender;
  DateTime? _birthDate;
  bool? _knowsBirthTime;
  TimeOfDay? _birthTime;
  String? _birthPlace;
  final List<String> _selectedLanguages = [];

  var cityList=[];

  Future<void> createUser() async {
    try {
      appStore.setLoading(true);
      CommonUtilities.showLoader(context);
      // Get current Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final user = UserModel(
        id: firebaseUser.uid,
        name: _name.trim(),
        gender: _gender,
        birthDate: _birthDate?.toIso8601String(),
        knowsBirthTime: _knowsBirthTime,
        birthTime: _birthTime != null
            ? '${_birthTime!.hour}:${_birthTime!.minute}'
            : null,
        birthPlace: _birthPlace,
        phoneNumber: firebaseUser.phoneNumber,
        userType: UserType.user,
        languages: _selectedLanguages,
        createdAt: now,
        updatedAt: now,
        lastActive: now,
        currentAppVersion: (await PackageInfo.fromPlatform()).version,
      );

      // Use the Firebase UID as the document ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toJson());

      await PreferenceService.setLoggedIn(true, userId: firebaseUser.uid);

      userStore.updateUserData(user);

      // Success - navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => UserDashboardScreen()),
              (route) => false,
        );
      }
    } on FirebaseException catch (e) {
      const errorMessages = {
        'permission-denied': 'Permission denied. Please check your account.',
        'unavailable': 'Service unavailable. Try again later.',
        'invalid-argument': 'Invalid data. Please check your input.',
        'deadline-exceeded': 'Request timed out. Check your connection.',
      };
      final errorMessage =
          errorMessages[e.code] ?? 'Error: ${e.message ?? 'Please try again.'}';
      debugPrint('Firebase error: ${e.code} - ${e.message}');

      if (mounted) {
        CommonUtilities.showError(context, errorMessage);
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      if (mounted) {
        CommonUtilities.showError(context, 'An unexpected error occurred.');
      }
    } finally {
      appStore.setLoading(false);
      if (mounted) {
        CommonUtilities.removeLoader(context);
      }
    }
  }

  void _skipRegistration() {
    // Set default values for skipped fields
    setState(() {
      _gender ??= 'Other';
      _birthDate ??= DateTime.now().subtract(const Duration(days: 365 * 25));
      _knowsBirthTime ??= false;
      _birthPlace ??= AppConstants.indianStates.first;
      _selectedLanguages.addAll(['English', 'Hindi']);
    });
    // Submit registration with these values
    createUser();
  }


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
          'Step $_currentStep/$_effectiveTotalSteps',
          style: AppTextStyles.bodyMedium(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentStep > 1) // Show skip button on all steps except first
            TextButton(
              onPressed: _skipRegistration,
              child: Text(
                'Skip',
                style: AppTextStyles.bodyMedium(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _currentStep / _effectiveTotalSteps,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${((_currentStep / _effectiveTotalSteps) * 100).round()}%',
                  style: AppTextStyles.captionText(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 1: Name
                _buildStep(
                  question: 'Hey! What\'s your name?',
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

                // Step 2: Gender (updated version)
                _buildStep(
                  question: 'What is your gender?',
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // You can customize the number of items per row (e.g., 3)
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
                                  height: itemWidth, // Keep square
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
                  ),
                ),

                // Step 3: Date of Birth
                _buildStep(
                  question: 'When were you born?',
                  child: GestureDetector(
                    onTap: () => _showDatePicker(context),
                    child: AbsorbPointer(
                      // Prevent keyboard from showing
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

                // Step 4: Know birth time
                _buildStep(
                  question: 'Do you know your exact birth time?',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildYesNoOption('Yes', true),
                          const SizedBox(width: 20),
                          _buildYesNoOption('No', false),
                        ],
                      ),
                    ],
                  ),
                ),

                // Step 5: Birth time (conditional)
                if (_knowsBirthTime == true)
                  _buildStep(
                    question: 'What time were you born?',
                    child: GestureDetector(
                      onTap: () => _showTimePicker(context),
                      child: AbsorbPointer(
                        // Prevents keyboard pop-up
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Select your birth time',
                            hintStyle: AppTextStyles.bodyMedium(),
                            suffixIcon: Icon(Icons.access_time,
                                color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          controller: TextEditingController(
                            text: _birthTime == null
                                ? ''
                                : _formatTime(_birthTime!), // formatted string
                          ),
                        ),
                      ),
                    ),
                  ),

                // Step 6: Birth place
                _buildStep(
                  question: 'Where were you born?',
                  child:
                  Column(
                    children: [
                      TextField(
                        controller: _searchCityController,
                          cursorColor: AppColors.primaryLight,
                          // style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                          hintText: 'Search City',
                          // hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey,width: 1)
                          ),
                          suffixIcon: IconButton(onPressed: () async{
                            if(_searchCityController.text.isNotEmpty){
                              _birthPlace=null;
                              cityList=await CommonUtilities.fetchCity(_searchCityController.text);
                              setState(() {

                              });
                            }else{
                              cityList.clear();
                              setState(() {

                              });
                            }
                          }, icon: Icon(Icons.search)),
                          focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey,width: 1)
                          ),
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey,width: 1)
                          ),
                          ),
                          ),
                      if(cityList.isNotEmpty && _birthPlace==null)

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for(int i=0;i<cityList.length;i++)
                                  InkWell(
                                      onTap: (){
                                        setState(() {
                                          _birthPlace=cityList[i]['description'];
                                          cityList.clear();
                                          _searchCityController.text=_birthPlace??"";
                                        });
                                      },
                                      child: Container(
                                        margin: EdgeInsets.symmetric(vertical: 4),
                                        padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(12)
                                          ),
                                          child: Text(cityList[i]['description'])))
                              ],
                            ),
                          ),
                        )
                    ],
                  )
                      // :
                  // Material(
                  //   elevation: 0,
                  //   color: Colors.white,
                  //   borderRadius: BorderRadius.circular(10),
                  //   child: SizedBox(
                  //     width: double.infinity, // This will constrain it to the parent's width
                  //     child: DropdownButtonFormField<String>(
                  //       value: _birthPlace,
                  //       elevation: 0,
                  //       dropdownColor: Colors.white,
                  //       decoration: InputDecoration(
                  //         border: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(10),
                  //         ),
                  //         focusedBorder: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(10),
                  //           borderSide: BorderSide(color: AppColors.primary),
                  //         ),
                  //       ),
                  //       items: AppConstants.indianStates.map((state) {
                  //         return DropdownMenuItem(
                  //           value: state,
                  //           child: Text(state, style: AppTextStyles.bodyMedium()),
                  //         );
                  //       }).toList(),
                  //       onChanged: (value) => setState(() => _birthPlace = value),
                  //       hint: Text('Select your state',
                  //           style: AppTextStyles.bodyMedium()),
                  //     ),
                  //   ),
                  // ),
                ),

                // Step 7: Languages
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
                        if (_currentStep == 6 && _knowsBirthTime == false) {
                          // If coming back from step 6 and we skipped step 5
                          _pageController.jumpToPage(_currentStep - 2);
                          setState(() => _currentStep -= 2);
                        } else if (_currentStep > 1) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() => _currentStep--);
                        } else {
                          Navigator.pop(context);
                        }
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
                      // Only validate name (step 1 is mandatory)
                      if (_currentStep == 1 && _name.trim().isEmpty) {
                        CommonUtilities.showError(
                            context, "Please enter your full name");
                        return;
                      }

                      if (_currentStep < _effectiveTotalSteps) {
                        FocusScope.of(context).unfocus();
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentStep++);
                      } else {
                        createUser();
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

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Widget _buildYesNoOption(String text, bool value) {
    final isSelected = _knowsBirthTime == value;
    final icon = value ? Icons.check_circle_outline : Icons.cancel_outlined;

    return GestureDetector(
      onTap: () => setState(() => _knowsBirthTime = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: AppTextStyles.bodyMedium(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
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

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      setState(() => _birthTime = picked);
    }
  }

  void _submitRegistration() {
    // Handle form submission
    print({
      'name': _name,
      'gender': _gender,
      'birthDate': _birthDate,
      'birthTime': _birthTime,
      'birthPlace': _birthPlace,
      'languages': _selectedLanguages,
    });
  }

  int get _effectiveTotalSteps =>
      _knowsBirthTime == true ? _totalSteps : _totalSteps - 1;
}
