import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../client/model/chat_request_model.dart';

class ChatRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'chat_requests';

  // Save a chat request to Firestore
  Future<String?> saveChatRequest(ChatRequest chatRequest) async {
    print("createChatRequest.called12:saveChatRequest");
    try {
      print("createChatRequest.called12:saveChatRequest14");
      final docRef = _firestore.collection(_collectionPath).doc(chatRequest.id);
      print("createChatRequest.called12:saveChatRequest16");
      await docRef.set(chatRequest.toJson());
      print("createChatRequest.called12:saveChatRequest18");
      return chatRequest.id;
    } catch (e,s) {
      print("createChatRequest.called12:saveChatRequest:::21 ERR:::$e ==>$s");
      print('Error saving chat request: $e');
      return null;
    }
  }

  Future<String?> removeOldChat(String id) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chat_requests')
          .where('userId', isEqualTo: id)
          .get();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        await _firestore.collection('chat_requests').doc(doc.id).delete();
        print("Deleted document with ID: ${doc.id}");
      }
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
    print("createChatRequest.called");
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('Error: User not authenticated');
      return null;
    }
    print("createChatRequest.called58");
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
    print("createChatRequest.called76");

    return await saveChatRequest(chatRequest);
  }
}