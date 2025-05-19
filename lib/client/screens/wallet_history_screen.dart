import 'package:astrology_app/common/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../common/utils/app_text_styles.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/common.dart';
import '../../common/utils/images.dart';
import '../../main.dart';
import '../../services/razorpay_service.dart';
import '../../services/wallet_services.dart';
import '../model/wallet_transaction_model.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<WalletTransaction>> _transactions;
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
    _transactions = _fetchTransactions();
  }

  Future<List<WalletTransaction>> _fetchTransactions() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final QuerySnapshot snapshot = await _firestore
        .collection('wallet_transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
            WalletTransaction.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
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
                                setState(() {
                                  _transactions = _fetchTransactions();
                                });
                                amountController.clear();
                                Navigator.pop(context);
                                CommonUtilities.showSuccess(context, 'Wallet funded successfully');
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
          'Wallet History',
          style: AppTextStyles.heading2(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFundWalletDialog,
        backgroundColor: AppColors.zodiacGold,
        child: const FaIcon(
          FontAwesomeIcons.plus,
          color: AppColors.textWhite,
          size: 24,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          // Full-screen background (same as profile screen)
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
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Balance Card
                  Observer(
                    builder: (_) => Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.zodiacGold.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.zodiacGold.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Balance',
                                style: AppTextStyles.captionText(
                                  color: AppColors.textWhite70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CommonUtilities.formatCurrency(
                                    userStore.user?.walletBalance),
                                style: AppTextStyles.heading2(
                                  color: AppColors.textWhite,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.zodiacGold,
                            size: 36,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Transactions List Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Recent Transactions',
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Transactions List
                  Expanded(
                    child: FutureBuilder<List<WalletTransaction>>(
                      future: _transactions,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.zodiacGold,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          debugPrint(
                              'Error loading transactions: ${snapshot.error}');
                          debugPrint('Stack trace: ${snapshot.stackTrace}');
                          return Center(
                            child: Text(
                              'Error loading transactions',
                              style: AppTextStyles.bodyMedium(
                                  color: AppColors.textWhite),
                            ),
                          );
                        }

                        final transactions = snapshot.data!;

                        if (transactions.isEmpty) {
                          return Center(
                            child: Text(
                              'No transactions yet',
                              style: AppTextStyles.bodyMedium(
                                  color: AppColors.textWhite70),
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: AppColors.textWhite.withOpacity(0.1),
                          ),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    final isCredit = transaction.type == AppConstants.CREDIT;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Transaction Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCredit
                  ? AppColors.successGreen.withOpacity(0.2)
                  : AppColors.errorRed.withOpacity(0.2),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppColors.successGreen : AppColors.errorRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Wallet Transaction',
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(transaction.date),
                  style: AppTextStyles.captionText(
                    color: AppColors.textWhite70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Transaction Amount
          Text(
            '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium(
              color: isCredit ? AppColors.successGreen : AppColors.errorRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
