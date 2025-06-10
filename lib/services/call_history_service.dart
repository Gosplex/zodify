import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';

import '../client/model/call_history_model.dart';

class CallHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'callHistory';

  // Generate a deterministic call ID based on channelName and timestamp
  String _generateCallId(String channelName, DateTime timestamp) {
    final input = '$channelName-${timestamp.toIso8601String()}';
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<void> saveCallHistory({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String channelName,
    required String callType,
    required String status,
    required int durationSeconds,
  }) async {
    try {
      print("I AM HERE");
      final timestamp = DateTime.now();
      final callId = _generateCallId(channelName, timestamp);

      // Check if the call history already exists
      final docRef = _firestore.collection(_collectionPath).doc(callId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        debugPrint('Call history already exists for callId: $callId');
        return;
      }

      final callHistory = CallHistory(
        id: callId,
        callerId: callerId,
        callerName: callerName,
        receiverId: receiverId,
        channelName: channelName,
        callType: callType,
        status: status,
        durationSeconds: durationSeconds,
        timestamp: timestamp,
      );

      await docRef.set(callHistory.toMap());
      debugPrint('Call history saved successfully: $callId');
    } catch (e) {
      debugPrint('Error saving call history: $e');
      throw Exception('Failed to save call history: $e');
    }
  }
}