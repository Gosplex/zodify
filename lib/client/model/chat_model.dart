import 'package:cloud_firestore/cloud_firestore.dart';

import 'message_model.dart'; // Import MessageType from MessageModel

class ChatModel {
  final String chatId; // Unique ID for the chat
  final List<String> participants; // List of user IDs in the chat
  final String lastMessage; // Content of the last message
  final MessageType lastMessageType; // Type of the last message
  final Timestamp lastMessageTime; // Time of the last message
  final Timestamp createdAt; // Time the chat was created
  final Timestamp updatedAt; // Time of the last update

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert ChatModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType.toString().split('.').last,
      'lastMessageTime': lastMessageTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create ChatModel from Firestore document
  factory ChatModel.fromMap(Map<String, dynamic> map, String chatId) {
    return ChatModel(
      chatId: chatId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == map['lastMessageType'],
        orElse: () => MessageType.text,
      ),
      lastMessageTime: map['lastMessageTime'] ?? Timestamp.now(),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  // CopyWith method for updating specific fields
  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    MessageType? lastMessageType,
    Timestamp? lastMessageTime,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}