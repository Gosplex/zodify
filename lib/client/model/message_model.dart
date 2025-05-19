import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, voice, video }

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final Timestamp timestamp;
  final bool isViewed;
  final bool isSent;
  final bool isDelivered;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.messageType,
    required this.timestamp,
    this.isViewed = false,
    this.isSent = true,
    this.isDelivered = false,
  });

  // Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.toString().split('.').last,
      'timestamp': timestamp,
      'isViewed': isViewed,
      'isSent': isSent,
      'isDelivered': isDelivered,
    };
  }

  // Create MessageModel from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      messageType: MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == map['messageType'],
        orElse: () => MessageType.text,
      ),
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isViewed: map['isViewed'] ?? false,
      isSent: map['isSent'] ?? true,
      isDelivered: map['isDelivered'] ?? false,
    );
  }

  // CopyWith method for updating specific fields
  MessageModel copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? messageType,
    Timestamp? timestamp,
    bool? isViewed,
    bool? isSent,
    bool? isDelivered,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isViewed: isViewed ?? this.isViewed,
      isSent: isSent ?? this.isSent,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }
}