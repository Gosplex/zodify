import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../common/utils/colors.dart'; // Import for AppColors
import '../../common/utils/app_text_styles.dart'; // Import for AppTextStyles
import 'package:http/http.dart' as http;

class CommonUtilities {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        dismissDirection: DismissDirection.endToStart,
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

      static Future<dynamic> fetchCity(String searchString) async {
        final url =
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$searchString&types=(cities)&components=country:in&key=AIzaSyA2ePDSb0Y1wStqWbLA0UwvFGZMXb7KuOY';
        final response = await http.get(Uri.parse(url));
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'];
        } else {
          return [];
        }
      }

  static Future<String?> fetchPlaceLocation(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=AIzaSyA2ePDSb0Y1wStqWbLA0UwvFGZMXb7KuOY';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      return '${location['lat']},${location['lng']}';
    } else {
      return null;
    }
  }

  static Future<dynamic> getKundliDetails(
      {required String dateTime, required String location}) async {
    // Client Name
    // TestingAPI App
    // Client ID
    // 4de6a4c3-8953-4af5-a69b-d94fa2eec012
    // Client Secret
    // Am1Eg2CwFDtEay4PZvXN8jFGMWuhPgfRsS87PnH5
    String token=await generateAuthTokenForKundli();
    final url = 'https://api.prokerala.com/v2/astrology/kundli/advanced?ayanamsa=1&datetime=$dateTime&coordinates=$location&la=en';
    final response = await http.get(Uri.parse(url),headers: {
      'Authorizations':'Bearer $token'
    });
    final data = jsonDecode(response.body);
    if (data['status'] == 'ok') {
      return data['data'];
    } else {
      return [];
    }
  }

  static Future<String> generateAuthTokenForKundli() async {
    // Client Name
    // TestingAPI App
    // Client ID
    // 4de6a4c3-8953-4af5-a69b-d94fa2eec012
    // Client Secret
    // Am1Eg2CwFDtEay4PZvXN8jFGMWuhPgfRsS87PnH5
    final url = 'https://api.prokerala.com/token?grant_type=client_credentials&client_id=4de6a4c3-8953-4af5-a69b-d94fa2eec012&client_secret=Am1Eg2CwFDtEay4PZvXN8jFGMWuhPgfRsS87PnH5';
    final response = await http.post(Uri.parse(url),);
    final data = jsonDecode(response.body);
    print('KundliToken:::${data}');
    print('KundliToken:::${data}');
    return data['access_token'].toString();
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        dismissDirection: DismissDirection.endToStart,
        content: Text(message),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showLoader(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Lottie.asset(
                'assets/animations/loading.json',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  static void removeLoader(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Close the loader dialog
    }
  }

  static void removeKeyboardFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static void showCustomDialog({
    required BuildContext context,
    required IconData icon,
    required String message,
    required String firstButtonText,
    required VoidCallback firstButtonCallback,
    required String secondButtonText,
    required VoidCallback secondButtonCallback,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.9), // Matches profile screen aesthetic
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.zodiacGold.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  icon,
                  color: AppColors.zodiacGold,
                  size: 48,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  message,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // First Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                          firstButtonCallback(); // Execute callback
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.zodiacGold.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          side: BorderSide(
                            color: AppColors.zodiacGold,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          firstButtonText,
                          style: AppTextStyles.horoscopeText(
                            color: AppColors.zodiacGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Second Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                          secondButtonCallback(); // Execute callback
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.zodiacGold,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.zodiacGold.withOpacity(0.5),
                        ),
                        child: Text(
                          secondButtonText,
                          style: AppTextStyles.horoscopeText(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }


  static Future<void> showImagePicker({
    required BuildContext context,
    required Function(String) onImageSelected,
    Color? iconColor,
    Color? textColor,
    Color? dividerColor,
    Color? cancelButtonColor,
    Color? backgroundColor,
    TextStyle? textStyle,
    String? galleryText,
    String? cameraText,
    String? cancelText,
  }) async {
    final defaultTextStyle = textStyle ?? AppTextStyles.bodyMedium();
    final defaultIconColor = iconColor ?? AppColors.primary;
    final defaultTextColor = textColor ?? AppColors.textPrimary;
    final defaultDividerColor = dividerColor ?? Colors.grey[300];
    final defaultCancelColor = cancelButtonColor ?? Colors.grey;
    final defaultBackgroundColor = backgroundColor ?? AppColors.primaryDark.withOpacity(0.95);

    await showModalBottomSheet(
      context: context,
      backgroundColor: defaultBackgroundColor,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: defaultBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: defaultIconColor),
                  title: Text(
                    galleryText ?? 'Choose from Gallery',
                    style: defaultTextStyle.copyWith(color: defaultTextColor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (pickedFile != null) {
                      onImageSelected(pickedFile.path);
                    }
                  },
                ),
                Divider(height: 1, color: defaultDividerColor),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: defaultIconColor),
                  title: Text(
                    cameraText ?? 'Take a Photo',
                    style: defaultTextStyle.copyWith(color: defaultTextColor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (pickedFile != null) {
                      onImageSelected(pickedFile.path);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  child: Text(
                    cancelText ?? 'Cancel',
                    style: defaultTextStyle.copyWith(color: defaultCancelColor),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<String> uploadImageToFirebase({
    required String filePath,
    required String storagePath,
  }) async {
    try {
      // 1. Validate input file
      final File imageFile = File(filePath);
      if (!await imageFile.exists()) {
        throw FileSystemException('File not found at path: $filePath');
      }

      // 2. Create storage reference with timestamp for uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniquePath = '$storagePath-$timestamp';
      final Reference storageRef = FirebaseStorage.instance.ref().child(uniquePath);


      // 3. Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded_by': 'user_profile'},
      );

      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        metadata,
      );

      // 4. Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // 5. Complete upload
      final TaskSnapshot snapshot = await uploadTask;
      if (snapshot.state != TaskState.success) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          message: 'Upload failed with state: ${snapshot.state}',
        );
      }

      // 6. Get download URL
      final String downloadUrl = await storageRef.getDownloadURL();
      debugPrint('Upload successful. URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      rethrow;
    }
  }

  static String formatCurrency(double? amount) {
    if (amount == null) return '₹0';
    final format = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return format.format(amount);
  }

  static String formatDate(String? dateString) {
    if (dateString == null) return "Not specified";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, y').format(date);
    } catch (e) {
      return dateString;
    }
  }

}


  class KundliApiService {
    static String? TokenVal=null;

    static Future<dynamic> getKundliDetails({
      required String dateTime,
      required String location,
      required int ayanamsa,
    }) async {
      print('Kundli Genrate call:::${dateTime}:::=>${location}');
      print('🔄 Getting auth token...');
      if(TokenVal==null){
        TokenVal = await generateAuthTokenForKundli();
      }
      print('✅ Token received: $TokenVal');

      final url = 'https://api.prokerala.com/v2/astrology/kundli?ayanamsa=$ayanamsa&datetime=$dateTime&coordinates=$location&la=en';
      // final url = 'https://api.prokerala.com/v2/astrology/kundli/advanced?ayanamsa=$ayanamsa&datetime=$dateTime&coordinates=$location&la=en';
      print('🌐 Request URL: $url');

      final headers = {
        'Authorization': 'Bearer $TokenVal',
      };
      print('📡 Request Headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        print('✅ Kundli data retrieved successfully');
        return data['data'];
      } else {
        print('❌ Error: API did not return status ok');
        return [];
      }
    }

    static Future<dynamic> getChart ({
      required String dateTime,
      required String location,
      required int ayanamsa,
    }) async {
      print('Kundli Genrate call:::${dateTime}:::=>${location}');
      print('🔄 Getting auth token...');
      if(TokenVal==null){
        TokenVal = await generateAuthTokenForKundli();
      }
      print('✅ Token received: $TokenVal');

      final url =
                'https://api.prokerala.com/v2/astrology/chart?ayanamsa=$ayanamsa&datetime=$dateTime&coordinates=$location&la=en&chart_type=navamsa&chart_style=north-indian&format=svg';
      print('🌐 Request URL: $url');

      final headers = {
        'Authorization': 'Bearer $TokenVal',
      };
      print('📡 Request Headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      return response.body;
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        print('✅ Kundli data retrieved successfully');
        return data['data'];
      } else {
        print('❌ Error: API did not return status ok');
        return [];
      }
    }

    static Future<dynamic> getApiCall(String path, [Map<String, String>? params]) async {
      if (TokenVal == null) {
        print('Generating new auth token...');
        TokenVal = await KundliApiService.generateAuthTokenForKundli();
        print('Token generated: $TokenVal');
      }

      final uri = Uri.https('api.prokerala.com', '/v2/astrology/$path', {
        ...?params,
        'la': 'en',
      });

      print('Making GET request to: $uri');
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $TokenVal',
      });

      print('Response Status Code: ${res.statusCode}');
      print('Response Body: ${res.body}');

      try {
        final decoded = json.decode(res.body)['data'];
        print('Decoded Data: $decoded');
        return decoded;
      } catch (e, s) {
        print('Decoding error: $e');
        print('Stack trace: $s');
        return res.body;
      }
    }

    static Future<String> generateAuthTokenForKundli() async {
      final url =
          'https://api.prokerala.com/token';
      print('🔐 Requesting auth token from: $url');

      final response = await http.post(Uri.parse(url),headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
        body: {

          'grant_type': 'client_credentials',
          'client_id': '5388d432-ccd7-4060-9823-9a957c31b9de',
          'client_secret': '5qT8iIykiRg4IVwoWsgHdzpedXf5XCJr7eNMOtPd',
          // 'client_id': '2a2e574e-00a5-447c-8b6a-90cc8d0efa68',
          // 'client_secret': 'V8qwiQ0aWzBtPlXK8RQ5AJvDvACJitBrFxd2UONH',
          // 'client_id': '4de6a4c3-8953-4af5-a69b-d94fa2eec012',
          // 'client_secret': 'Am1Eg2CwFDtEay4PZvXN8jFGMWuhPgfRsS87PnH5',
        },
      );
      print('📥 Token Response Status: ${response.statusCode}');
      print('📥 Token Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (data.containsKey('access_token')) {
        print('✅ Access Token Retrieved');
        return data['access_token'].toString();
      } else {
        print('❌ Failed to retrieve access token');
        throw Exception('Token generation failed');
      }
    }
  }


// class HoroscopeApiService {
//   static String? t1;
//   //
//   // static Future<void> _ensureToken() async {
//   //   if (_token != null) return;
//   //   final res = await http.post(
//   //     Uri.parse('https://api.prokerala.com/token'),
//   //     headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//   //     body: {
//   //       'grant_type': 'client_credentials',
//   //       'client_id': _clientId,
//   //       'client_secret': _clientSecret,
//   //     },
//   //   );
//   //   final data = json.decode(res.body);
//   //   _token = data['access_token'];
//   // }
//
//   static Future<dynamic> _get(String path, [Map<String, String>? params]) async {
//     if(t1==null){
//       t1=await KundliApiService.generateAuthTokenForKundli();
//     }
//     final uri = Uri.https('api.prokerala.com', '/v2/astrology/$path', {...?params, 'la': 'en'});
//     final res = await http.get(uri, headers: {'Authorization': 'Bearer ${t1.toString()}'});
//     try{
//       return json.decode(res.body)['data'];
//     }catch(e,s){
//       return res.body;
//     }
//   }
//
//   static Future<dynamic> getApiCall(String path, [Map<String, String>? params]) async {
//     if(t1==null){
//       t1=await KundliApiService.generateAuthTokenForKundli();
//     }
//     final uri = Uri.https('api.prokerala.com', '/v2/astrology/$path', {...?params, 'la': 'en'});
//     final res = await http.get(uri, headers: {'Authorization': 'Bearer ${t1.toString()}'});
//     try{
//       return json.decode(res.body)['data'];
//     }catch(e,s){
//       return res.body;
//     }
//   }
//
//   static Future<dynamic> birthDetails({required String coordinates,required String dateTime}) => _get('birth-details', {
//     'ayanamsa':'1',
//     'coordinates':coordinates,
//     'datetime':dateTime,
//     'la':'en',
// });
//
//   static Future<dynamic> kaalSarpDosh({required String coordinates,required String dateTime}) => _get('kaal-sarp-dosha', {
//     'ayanamsa':'1',
//     'coordinates':coordinates,
//     'datetime':dateTime,
//     'la':'en',
//   });
//
//   static Future<dynamic> chart({required String coordinates,required String dateTime}) => _get('mangal-dosha', {
//     'ayanamsa':'1',
//     'coordinates':coordinates,
//     'datetime':dateTime,
//     'la':'en',
//   });
//
//   static Future<dynamic> planetPosition() => _get('planet-position', {
//
//   });
//
//   static Future<dynamic> yoga({required String coordinates,required String dateTime,String? planet}) => _get('yoga', {
//     'ayanamsa':'1',
//     'coordinates':coordinates,
//     'datetime':dateTime,
//     'planet':planet??'',
//     'la':'en',
//   });
//
//
// // Repeat for mangal-dosha, sade-sati, planet-position, dasha-periods, kundli-matching, horoscope-matching, etc.
// }
