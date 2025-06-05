import 'package:astrology_app/client/screens/wallet_history_screen.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/common/utils/images.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../common/utils/common.dart';
import '../../main.dart';
import '../../services/razorpay_service.dart';
import '../../services/wallet_services.dart';

class AddMoneyScreen extends StatelessWidget {
  var customAmountController=TextEditingController();
  final _razorpayService = RazorpayService();
  final walletService = WalletService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    userStore: userStore,
  );
  final List<AmountOption> options = [
    AmountOption(25, ),
    AmountOption(100, isPopular: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark2,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Add money to wallet",style: TextStyle(color: AppColors.textWhite),),
        leading: BackButton(color: Colors.white,),
      ),
      body: Container(
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
          child: Column(
            children: [
              SizedBox(height: kToolbarHeight+16,),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Available Balance",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child:
                Text(
                  "₹ ${userStore?.user?.walletBalance??"0"}",
                  style: TextStyle(fontSize: 24,color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: options.map((option) => GestureDetector(
                      onTap: (){
                        executePayment(context,money:option.amount.toDouble());
                      },
                      child: AmountCard(option))).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: customAmountController,
                cursorColor: AppColors.primaryLight,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add Custom Amount',
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey,width: 1)
                  ),
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
              const SizedBox(height: 16),
              MaterialButton(
                minWidth: double.infinity,
                height: 48,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                color: AppColors.primaryLight,
                onPressed: () {
                  double money=double.tryParse(customAmountController.text)??0;
                  executePayment(context,money:money);
                }, child: Text("Continue",style: TextStyle(color: AppColors.textWhite,fontSize: 16,fontWeight: FontWeight.w900),),)
            ],
          ),
        ),
      ),
    );
  }

  void executePayment(BuildContext context, {required double money}) {
    if (money >= 0) {
      // Minimum amount check
      _razorpayService.initPaymentGateway(
        amount: money,
        onSuccess: (paymentId) async {
          await walletService
              .updateWalletBalance(money, paymentId)
              .whenComplete(
                () {
              whenPaymentIsCompleted(context,amount: money);
            },
          );
        },
        onError: (error) {
          CommonUtilities.showError(context, error);
        },
      );
    } else {
      CommonUtilities.showError(
          context, 'Enter Valid Amount');
    }
  }

  void whenPaymentIsCompleted(BuildContext context,{required double amount}) {
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

}



class AmountOption {
  final int amount;
  final bool isPopular;
  // final bool isCustom;

  AmountOption(this.amount, {this.isPopular = false,/*this.isCustom =false*/});
}

class AmountCard extends StatelessWidget {
  final AmountOption option;

  const AmountCard(this.option, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  option.amount.toString(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (option.isPopular)
          Positioned(
            right: 0,
            left: 0,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration:  BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)
                ),
                // borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "★ Most Popular",
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          )
      ],
    );
  }
}
