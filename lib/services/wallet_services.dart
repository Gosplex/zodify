import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import '../../common/utils/constants.dart';
import '../client/model/user_model.dart';
import '../client/model/wallet_transaction_model.dart';
import '../common/store/user_store.dart';

class WalletService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserStore _userStore;

  WalletService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required UserStore userStore,
  })  : _firestore = firestore,
        _auth = auth,
        _userStore = userStore;

  Future<void> updateWalletBalance(
      double amount, String razorpayPaymentId) async {
    try {
      final userId = _auth.currentUser!.uid;
      final transactionId = const Uuid().v4();

      // Create transaction object
      final transaction = WalletTransaction(
        id: transactionId,
        userId: userId,
        amount: amount,
        type: AppConstants.CREDIT,
        paymentMethod: AppConstants.RAZORPAY,
        date: DateTime.now(),
        referenceId: razorpayPaymentId,
        description: 'Wallet top-up via Razorpay',
      );

      // Batch write for atomic update
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);

      // Update wallet balance
      batch.update(userRef, {
        'walletBalance': FieldValue.increment(amount),
      });

      // Save transaction in a top-level collection with a unique doc ID
      final transactionRef =
      _firestore.collection('wallet_transactions').doc(transactionId);

      batch.set(transactionRef, transaction.toJson());

      await batch.commit();

      // Fetch updated user data from Firestore
      final updatedDoc = await userRef.get();
      if (updatedDoc.exists) {
        final updatedUser =
        UserModel.fromJson(updatedDoc.data() as Map<String, dynamic>);
        runInAction(() {
          _userStore.updateUserData(updatedUser);
        });
      } else {
        throw Exception('Failed to fetch updated user data');
      }
    } catch (e) {
      debugPrint('Error updating wallet: $e');
      rethrow;
    }
  }
}