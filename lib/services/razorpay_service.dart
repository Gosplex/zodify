import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../main.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();
  Function(String)? onSuccess; // Change to accept paymentId (String)
  Function(String)? onError;

  void initPaymentGateway({
    required double amount,
    required Function(String) onSuccess, // Update to accept paymentId
    required Function(String) onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    var options = {
      'key': 'rzp_test_CLw7tH3O3P5eQM',
      'amount': (amount * 100).toInt(),
      'name': 'Zodify App',
      'description': 'Wallet Top-up',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': userStore.user?.phoneNumber ?? '',
        'name': userStore.user?.name ?? ''
      },
      'external': {
        'wallets': ['paytm, gpay']
      },
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'upi': {
        'flow': 'intent', // Use Intent flow to show UPI apps like Google Pay, PhonePe
      },
      'theme': {
        'color': '#F37254',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (onSuccess != null) {
      onSuccess!(response.paymentId!); // Pass paymentId
    }
    _cleanup();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onError != null) {
      onError!(response.message ?? 'Payment failed');
    }
    _cleanup();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle wallet payments like Paytm, PhonePe etc.
    _cleanup();
  }

  void _cleanup() {
    _razorpay.clear();
  }
}