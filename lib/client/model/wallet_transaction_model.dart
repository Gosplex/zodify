import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String paymentMethod;
  final DateTime date;
  final String? referenceId;
  final String? description;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.date,
    this.referenceId,
    this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      userId:  json['userId'],
      id: json['id'],
      amount: json['amount'].toDouble(),
      type: json['type'],
      paymentMethod: json['paymentMethod'],
      date: (json['date'] as Timestamp).toDate(),
      referenceId: json['referenceId'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'paymentMethod': paymentMethod,
      'date': Timestamp.fromDate(date),
      'referenceId': referenceId,
      'description': description,
    };
  }
}