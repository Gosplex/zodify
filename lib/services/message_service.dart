import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:astrology_app/client/model/message_model.dart';
import 'package:astrology_app/client/model/chat_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String messagesCollection = 'messages';
  final String chatsCollection = 'chats';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sends a message to Firestore
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    required MessageType messageType,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final message = MessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        timestamp: Timestamp.now(),
        isViewed: false,
        isSent: true,
        isDelivered: false,
      );

      await _firestore
          .collection(messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      // Update chat metadata (e.g., last message, timestamp)
      await _updateChatMetadata(
        chatId: chatId,
        lastMessage: content,
        lastMessageType: messageType,
        lastMessageTime: Timestamp.now(),
        participants: [senderId, receiverId],
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Updates chat metadata (e.g., last message, timestamp) in the chats collection
  Future<void> _updateChatMetadata({
    required String chatId,
    required String lastMessage,
    required MessageType lastMessageType,
    required Timestamp lastMessageTime,
    required List<String> participants,
  }) async {
    try {
      await _firestore.collection(chatsCollection).doc(chatId).set({
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType.toString().split('.').last,
        'lastMessageTime': lastMessageTime,
        'updatedAt': Timestamp.now(),
        'participants': participants,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update chat metadata: $e');
    }
  }

  /// Retrieves a stream of messages for a specific chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data());
      }).toList();
    });
  }

  /// Retrieves the last message for a specific chat (for ChatListScreen)
  Stream<MessageModel?> getLastMessage(String chatId) {
    return _firestore
        .collection(messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return MessageModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    });
  }

  /// Marks a message as viewed
  Future<void> markMessageAsViewed(String messageId) async {
    try {
      await _firestore.collection(messagesCollection).doc(messageId).update({
        'isViewed': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as viewed: $e');
    }
  }

  /// Marks a message as delivered
  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      await _firestore.collection(messagesCollection).doc(messageId).update({
        'isDelivered': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as delivered: $e');
    }
  }

  /// Retrieves a stream of chats for a user (for ChatListScreen)
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection(chatsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Retrieves a stream of chats for a user (for ChatListScreen)
  Stream<List<ChatModel>> getUserChatsHistory(String userId) {
    return _firestore
        .collection("chat_history")
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Generates a unique chat ID based on user IDs
  String generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  /// Deletes a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(messagesCollection).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Uploads an image to Firebase Storage and returns its URL
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final String fileName =
          'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Uploads a video to Firebase Storage and returns its URL
  Future<String?> uploadVideo(XFile videoFile) async {
    try {
      final String fileName =
          'chat_videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(File(videoFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Video upload failed: $e');
    }
  }

  /// Uploads a voice message to Firebase Storage and returns its URL
  Future<String?> uploadVoiceMessage(XFile voiceFile) async {
    try {
      final String fileName =
          'chat_voice/${DateTime.now().millisecondsSinceEpoch}.aac';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(File(voiceFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Voice message upload failed: $e');
    }
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required XFile imageFile,
    String? caption,
  }) async {
    try {
      final imageUrl = await uploadImage(imageFile);
      if (imageUrl == null) throw Exception('Failed to upload image');

      final messageId = const Uuid().v4();
      final message = MessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: imageUrl,
        messageType: MessageType.image,
        timestamp: Timestamp.now(),
        isViewed: false,
        isSent: true,
        isDelivered: false,
      );

      await _firestore
          .collection(messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      await _updateChatMetadata(
        chatId: chatId,
        lastMessage: caption ?? '📷 Image',
        lastMessageType: MessageType.image,
        lastMessageTime: Timestamp.now(),
        participants: [senderId, receiverId],
      );
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }

  /// Sends a video message
  Future<void> sendVideoMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required XFile videoFile,
  }) async {
    try {
      final videoUrl = await uploadVideo(videoFile);
      if (videoUrl == null) throw Exception('Failed to upload video');

      final messageId = const Uuid().v4();
      final message = MessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: videoUrl,
        messageType: MessageType.video,
        timestamp: Timestamp.now(),
        isViewed: false,
        isSent: true,
        isDelivered: false,
      );

      await _firestore
          .collection(messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      await _updateChatMetadata(
        chatId: chatId,
        lastMessage: '🎥 Video',
        lastMessageType: MessageType.video,
        lastMessageTime: Timestamp.now(),
        participants: [senderId, receiverId],
      );
    } catch (e) {
      throw Exception('Failed to send video: $e');
    }
  }

  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required XFile voiceFile,
  }) async {
    try {
      final voiceUrl = await uploadVoiceMessage(voiceFile);
      if (voiceUrl == null) throw Exception('Failed to upload voice message');

      final messageId = const Uuid().v4();
      final message = MessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: voiceUrl,
        messageType: MessageType.voice,
        timestamp: Timestamp.now(),
        isViewed: false,
        isSent: true,
        isDelivered: false,
      );

      await _firestore
          .collection(messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      await _updateChatMetadata(
        chatId: chatId,
        lastMessage: '🎙️ Voice',
        lastMessageType: MessageType.voice,
        lastMessageTime: Timestamp.now(),
        participants: [senderId, receiverId],
      );
    } catch (e) {
      throw Exception('Failed to send voice message: $e');
    }
  }


  Future<bool> isExactlyOneMessage(String chatId) async {
    try {
      // First check if at least one message exists (fast check)
      final initialCheck = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .limit(2)
          .get();

      // Return false immediately if no messages exist
      if (initialCheck.docs.isEmpty) return false;

      // Now get exact count (only if first check passed)
      final countSnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .count()
          .get();

      print("MESSAGE COUNT === ${countSnapshot.count}");

      // Return true ONLY if count == 1
      return countSnapshot.count == 1;
    } catch (e) {
      print('Error checking message count: $e');
      return false; // Default to false on error
    }
  }
}
