import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../client/model/chat_request_model.dart';

class ChatRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'chat_requests';

  // Save a chat request to Firestore
  Future<String?> saveChatRequest(ChatRequest chatRequest) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc(chatRequest.id);
      await docRef.set(chatRequest.toJson());
      return chatRequest.id;
    } catch (e) {
      print('Error saving chat request: $e');
      return null;
    }
  }

  // Generate a new chat request
  Future<String?> createChatRequest({
    required String astrologerId,
    required String firstName,
    required String astrologerName,
    required String lastName,
    String? gender,
    required String dob,
    String? tob,
    String? birthPlace,
    String? relationshipStatus,
    required String occupation,
    required String topic,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('Error: User not authenticated');
      return null;
    }

    final chatRequest = ChatRequest(
      id: _firestore.collection(_collectionPath).doc().id,
      userId: userId,
      astrologerId: astrologerId,
      astrologerName: astrologerName,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      dob: dob,
      tob: tob,
      birthPlace: birthPlace,
      relationshipStatus: relationshipStatus,
      occupation: occupation,
      topic: topic,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    return await saveChatRequest(chatRequest);
  }
}