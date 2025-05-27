import 'package:astrology_app/client/model/user_model.dart';
import 'package:astrology_app/client/screens/user_chat_waiting_screen.dart';
import 'package:astrology_app/common/utils/common.dart';
import 'package:astrology_app/main.dart';
import 'package:astrology_app/services/message_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/constants.dart';
import '../../services/chat_request_service.dart';
import '../../services/notification_service.dart';

class ChatIntakeFormScreen extends StatefulWidget {
  final UserModel astrologerDetails;

  const ChatIntakeFormScreen({super.key, required this.astrologerDetails});

  @override
  State<ChatIntakeFormScreen> createState() => _ChatIntakeFormScreenState();
}

class _ChatIntakeFormScreenState extends State<ChatIntakeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _tobController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  final ChatRequestService _chatRequestService = ChatRequestService();
  final MessageService _messageService = MessageService();


  String? _selectedGender;
  String? _selectedBirthPlace;
  String? _selectedRelationshipStatus;
  bool _knowsBirthTime = true;
  bool _isLoading = false;



  @override
  void initState() {
    super.initState();
    _firstNameController.text = userStore.user!.name!.split(' ')[0];
    try{
      _lastNameController.text = userStore.user!.name!.split(' ')[1];
    }catch(e){

    }
    _dobController.text = DateFormat('MMMM d, y').format(DateTime.parse(userStore.user!.birthDate!));
    _tobController.text = userStore.user!.birthTime??'';
    _knowsBirthTime = userStore.user!.birthTime != null ? true : false;
    _selectedGender = userStore.user!.gender;
    _selectedBirthPlace = userStore.user!.birthPlace;
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
        _dobController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
        _tobController.text = picked.format(context);
      });
    }
  }

  void _submitForm() {
    // Dismiss keyboard synchronously
    FocusScope.of(context).unfocus();

    // Validate form
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Set loading state
      });
      // Process submission
      _processSubmission();
    }
  }


  Future<void> _processSubmission() async {
    // Show loader
    CommonUtilities.showLoader(context);

    try {
      // Create chat request using the service
      final requestId = await _chatRequestService.createChatRequest(
        astrologerId: widget.astrologerDetails.id!,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        gender: _selectedGender,
        dob: _dobController.text,
        tob: _knowsBirthTime ? _tobController.text : null,
        birthPlace: _selectedBirthPlace,
        relationshipStatus: _selectedRelationshipStatus,
        occupation: _occupationController.text,
        topic: _topicController.text,
      );

      if (requestId == null) {
        throw Exception('Failed to create chat request');
      }

      // Send notification and wait for it to complete
      await NotificationService().sendGenericNotification(
        fcmToken: widget.astrologerDetails.fcmToken!,
        title: 'New Chat Request',
        body: 'You have a new chat request from ${userStore.user!.name}.',
        type: 'chat_request',
        data: {
          'requestId': requestId,
          'userId': userStore.user!.id!,
          'screen': 'accept_reject',
        },
      );

      // Remove loader before navigation
      CommonUtilities.removeLoader(context);

      // Navigate to UserChatWaitingScreen with astrologer details
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UserChatWaitingScreen(
              chatRequestId: requestId,
              chatId: _messageService.generateChatId(widget.astrologerDetails.id!, userStore.user!.id!),
              astrologerImageUrl: widget.astrologerDetails.astrologerProfile!.imageUrl!,
              astrologerName: widget.astrologerDetails.astrologerProfile!.name!,
              astrologerId: widget.astrologerDetails.id!,
            ),
          ),
        );
      }
    } catch (e) {
      // Remove loader if there's an error
      if (mounted) {
        CommonUtilities.removeLoader(context);
        CommonUtilities.showError(context, "Something went wrong");
      }
      debugPrint('Error in _processSubmission: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _occupationController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'Chat Intake Form',
          style: AppTextStyles.heading2(
            color: AppColors.textWhite,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter first name'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter last name'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Gender',
                icon: Icons.transgender,
                value: _selectedGender,
                items: AppConstants.genders,
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),

              _buildSectionHeader('Birth Information'),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _dobController,
                label: 'Date of Birth',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select birth date'
                    : null,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Know Time of Birth?',
                    style:
                        AppTextStyles.bodyMedium(color: AppColors.textWhite70),
                  ),
                  Switch(
                    value: _knowsBirthTime,
                    activeColor: AppColors.zodiacGold,
                    onChanged: (value) {
                      setState(() {
                        _knowsBirthTime = value;
                        if (!value) _tobController.clear();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_knowsBirthTime)
                _buildTextFormField(
                  controller: _tobController,
                  label: 'Time of Birth',
                  icon: Icons.access_time,
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  validator: (value) {
                    if (_knowsBirthTime && (value == null || value.isEmpty)) {
                      return 'Please select birth time';
                    }
                    return null;
                  },
                ),
              if (_knowsBirthTime) const SizedBox(height: 16),

              // Prevent overflow by wrapping dropdown properly
              LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: _buildDropdownField(
                      label: 'Place of Birth',
                      icon: Icons.place,
                      value: _selectedBirthPlace,
                      items: AppConstants.indianStates,
                      onChanged: (value) =>
                          setState(() => _selectedBirthPlace = value),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Life Details'),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Relationship Status',
                icon: Icons.favorite_border,
                value: _selectedRelationshipStatus,
                items: AppConstants.relationshipStatuses,
                onChanged: (value) =>
                    setState(() => _selectedRelationshipStatus = value),
              ),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _occupationController,
                label: 'Occupation',
                icon: Icons.work_outline,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter occupation'
                    : null,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Consultation Details'),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _topicController,
                label: 'Topic of Concern',
                icon: Icons.help_outline,
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please describe your concern'
                    : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.zodiacGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Submit & Start Chat',
                    style: AppTextStyles.buttonText(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.heading2(
        color: AppColors.zodiacGold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int? maxLines = 1,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly || _isLoading,
      maxLines: maxLines,
      onTap: onTap,
      style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.captionText(color: AppColors.textWhite70),
        prefixIcon: Icon(icon, color: AppColors.zodiacGold),
        filled: true,
        fillColor: AppColors.primaryDark.withOpacity(0.5),
        errorStyle: AppTextStyles.captionText(color: Colors.redAccent),
        // Add this
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.zodiacGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.zodiacGold,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          // Add this
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Add this
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      dropdownColor: AppColors.primaryDark,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.captionText(color: AppColors.textWhite70),
        prefixIcon: Icon(icon, color: AppColors.zodiacGold),
        filled: true,
        fillColor: AppColors.primaryDark.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.zodiacGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.zodiacGold,
            width: 1.5,
          ),
        ),
      ),
      iconEnabledColor: AppColors.zodiacGold,
      style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
