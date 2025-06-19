import 'package:flutter/material.dart';
import '../../common/utils/images.dart';
import '../../common/utils/colors.dart';
import '../utils/app_text_styles.dart';

class KundliResultScreen extends StatefulWidget {
  String kundliData;
  KundliResultScreen({super.key, required this.kundliData});

  @override
  State<KundliResultScreen> createState() => _KundliResultScreenState();
}

class _KundliResultScreenState extends State<KundliResultScreen> {

  @override
  void initState() {
    super.initState();
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
        title: Text('Your Kundli',style: AppTextStyles.heading2(
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
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: kToolbarHeight+50),
            child: SelectableText(
              widget.kundliData,
              style: const TextStyle(fontSize: 16,color: AppColors.textWhite, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
