import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_text_styles.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/images.dart';
import 'kundli_result_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KundliFormScreen extends StatefulWidget {
  @override
  _KundliFormScreenState createState() => _KundliFormScreenState();
}

class _KundliFormScreenState extends State<KundliFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dobController = TextEditingController();
  final pobController = TextEditingController();
  final tobController = TextEditingController();
  int selectedAyanamsa = 1;
  var cityList=[];
  String? _birthPlaceLocation;
  String? chartSVG;
  DateTime? time;
  final List<Map<String, dynamic>> ayanamsaOptions = [
    {'value': 1, 'label': 'Lahiri (1)'},
    {'value': 3, 'label': 'Raman (3)'},
    {'value': 5, 'label': 'KP (5)'},
  ];


  @override
  void dispose() {
    tobController.dispose();
    pobController.dispose();
    dobController.dispose();
    super.dispose();
  }

  String formatDateTimeForApi(DateTime dateTime) {
    // Get ISO 8601 string with timezone
    String isoString = dateTime.toIso8601String(); // e.g., "2004-02-12T15:19:21.000+05:30"

    // Remove milliseconds (optional)
    isoString = isoString.split('.').first;

    // Encode '+' as '%2B' for URL safety
    isoString = isoString.replaceAll('+', '%2B');
    // 2025-06-12T01:43:00%2B05:30

    return isoString;
  }

  String convertToEncodedIso(String input) {
    // 2004-02-12T15:19:21%2B05:30
    // 1999-12-24T12:20:00%2B05:30
    // Parse the input string as if it's in local time (not UTC)
    DateTime dateTime = DateTime.parse(input);

    // Force it to local time (optional if already local)
    dateTime = dateTime.toLocal();

    // Format with timezone
    final duration = dateTime.timeZoneOffset;
    final offsetHours = duration.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes = (duration.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = duration.isNegative ? '-' : '%2B'; // encode '+' as '%2B'

    final offset = '$sign$offsetHours:$offsetMinutes';

    // Format final string
    final formatted = dateTime.toIso8601String().split('.').first + offset;
    print("CHeckFormatedDate::${formatted}");
    return formatted;
  }


  void submitForm() async{
    print("CheckLocation:::${_birthPlaceLocation}");
    if (_formKey.currentState!.validate()) {
      // var b=await KundliApiService.getKundliDetails(dateTime: convertToEncodedIso(formatDateTimeForApi(time!)), location: _birthPlaceLocation??'',ayanamsa: selectedAyanamsa);
      var b=await KundliApiService.getChart(dateTime: convertToEncodedIso(formatDateTimeForApi(time!)), location: _birthPlaceLocation??'',ayanamsa: selectedAyanamsa);
      setState(() {
        chartSVG=b;
      });

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => KundliResultScreen(kundliData:generateKundliText(b),),
      //   ),
      // );
    }
  }

  String generateKundliText(Map<String, dynamic> data) {
    String getValue(dynamic map, List<String> keys, {String defaultValue = 'N/A'}) {
      dynamic current = map;
      for (var key in keys) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return defaultValue;
        }
      }
      return current?.toString() ?? defaultValue;
    }

    // Safely extract yoga lists
    final yogaDetails = data['yoga_details'] as List<dynamic>?;
    final majorYogas = yogaDetails?.isNotEmpty == true ? yogaDetails![0]['yoga_list'] as List<dynamic>? : [];
    final inauspiciousYogas = yogaDetails?.length == 4 ? yogaDetails![3]['yoga_list'] as List<dynamic>? : [];

    final presentYogas = (majorYogas ?? [])
        .where((yoga) => yoga['has_yoga'] == true)
        .map((yoga) => '✅ ${yoga['name'] ?? 'Unknown'}')
        .join('\n   ');

    final presentInauspicious = (inauspiciousYogas ?? [])
        .where((yoga) => yoga['has_yoga'] == true)
        .map((yoga) => '❗ ${yoga['name'] ?? 'Unknown'}')
        .join('\n   ');

    return '''
🔹 Nakshatra: ${getValue(data, ['nakshatra_details', 'nakshatra', 'name'])} (Pada ${getValue(data, ['nakshatra_details', 'nakshatra', 'pada'])})
🔹 Nakshatra Lord: ${getValue(data, ['nakshatra_details', 'nakshatra', 'lord', 'name'])}

🌙 Chandra Rasi: ${getValue(data, ['nakshatra_details', 'chandra_rasi', 'name'])}
   ➤ Lord: ${getValue(data, ['nakshatra_details', 'chandra_rasi', 'lord', 'name'])} (${getValue(data, ['nakshatra_details', 'chandra_rasi', 'lord', 'vedic_name'])})

☀️ Soorya Rasi: ${getValue(data, ['nakshatra_details', 'soorya_rasi', 'name'])}
   ➤ Lord: ${getValue(data, ['nakshatra_details', 'soorya_rasi', 'lord', 'name'])} (${getValue(data, ['nakshatra_details', 'soorya_rasi', 'lord', 'vedic_name'])})

♒ Zodiac Sign: ${getValue(data, ['nakshatra_details', 'zodiac', 'name'])}

📌 Additional Info:
   ➤ Deity: ${getValue(data, ['nakshatra_details', 'additional_info', 'deity'])}
   ➤ Ganam: ${getValue(data, ['nakshatra_details', 'additional_info', 'ganam'])}
   ➤ Symbol: ${getValue(data, ['nakshatra_details', 'additional_info', 'symbol'])}
   ➤ Animal Sign: ${getValue(data, ['nakshatra_details', 'additional_info', 'animal_sign'])}
   ➤ Nadi: ${getValue(data, ['nakshatra_details', 'additional_info', 'nadi'])}
   ➤ Color: ${getValue(data, ['nakshatra_details', 'additional_info', 'color'])}
   ➤ Best Direction: ${getValue(data, ['nakshatra_details', 'additional_info', 'best_direction'])}
   ➤ Syllables: ${getValue(data, ['nakshatra_details', 'additional_info', 'syllables'])}
   ➤ Birth Stone: ${getValue(data, ['nakshatra_details', 'additional_info', 'birth_stone'])}
   ➤ Gender: ${getValue(data, ['nakshatra_details', 'additional_info', 'gender'])}
   ➤ Planet: ${getValue(data, ['nakshatra_details', 'additional_info', 'planet'])}
   ➤ Enemy Yoni: ${getValue(data, ['nakshatra_details', 'additional_info', 'enemy_yoni'])}

🔥 Mangal Dosha: ${getValue(data, ['mangal_dosha', 'has_dosha']) == 'true' ? '✅ Manglik' : '❌ Not Manglik'}

🧘‍♂️ Major Yogas:
   ${presentYogas.isNotEmpty ? presentYogas : 'None'}

⚠️ Inauspicious Yogas:
   ${presentInauspicious.isNotEmpty ? presentInauspicious : 'None'}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Generate Your Kundli',style: AppTextStyles.heading2(
          color: AppColors.textWhite,
          fontSize: 22,
        ),),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.ic_user_dashboard_background),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54, // Adjust opacity (0-255)
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButton<int>(
                  value: selectedAyanamsa,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedAyanamsa = newValue;
                      });
                    }
                  },
                  items: ayanamsaOptions.map((option) {
                    return DropdownMenuItem<int>(
                      value: option['value'],
                      child: Text(option['label']),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: dobController,
                  label: 'Date of Birth',
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select birth date'
                      : null,
                ),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: tobController,
                  label: 'Time of Birth',
                  icon: Icons.access_time,
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select birth time';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Column(
                  children: [
                    _buildTextFormField(
                        controller: pobController,
                        label: 'Place of Birth',
                        icon: Icons.access_time,
                        onChangeCall:(v) async{
                          if(pobController.text.isNotEmpty){
                            _birthPlaceLocation=null;
                            cityList=await CommonUtilities.fetchCity(pobController.text);
                            setState(() {

                            });
                          }else{
                            cityList.clear();
                            setState(() {

                            });
                          }
                        }
                    ),
                    if(cityList.isNotEmpty && _birthPlaceLocation==null)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8,vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for(int i=0;i<cityList.length;i++)
                              InkWell(
                                  onTap: () async{
                                    print('CheckCity Location:::${cityList[i].toString()}');
                                    _birthPlaceLocation=await CommonUtilities.fetchPlaceLocation(cityList[i]['place_id']);
                                    setState(() {

                                      pobController.text=cityList[i]['description']??"";
                                      cityList.clear();
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
                      )
                  ],
                ),
                SizedBox(height: 20),
              if(chartSVG!=null)
              SvgPicture.string(
                color: Colors.white,
                chartSVG??'',
                semanticsLabel: 'Dart Logo',
              ),
                SizedBox(height: 20),
                ElevatedButton(onPressed: submitForm, child: Text("Generate Kundli")),
              ],
            ),
          ),
        ),
      ),
    );
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
        time=picked;
        dobController.text = DateFormat('MMM dd, yyyy').format(picked);
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
        time=DateTime(time!.year,time!.month,time!.day,picked.hour,picked.minute);
        tobController.text = picked.format(context);
      });
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int? maxLines = 1,
    VoidCallback? onTap,
    var onChangeCall,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly ,
      maxLines: maxLines,
      onTap: onTap,
      onChanged: onChangeCall,
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
  
}
