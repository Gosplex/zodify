import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRequest {
  final String id;
  final String userId;
  final String astrologerId;
  final String firstName;
  final String lastName;
  final String? gender;
  final String dob;
  final String? tob;
  final String? birthPlace;
  final String? relationshipStatus;
  final String occupation;
  final String topic;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final String astrologerName;

  ChatRequest({
    required this.id,
    required this.astrologerName,
    required this.userId,
    required this.astrologerId,
    required this.firstName,
    required this.lastName,
    this.gender,
    required this.dob,
    this.tob,
    this.birthPlace,
    this.relationshipStatus,
    required this.occupation,
    required this.topic,
    required this.status,
    required this.createdAt,
  });

  // Factory to create ChatRequest from Firestore document
  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      id: json['id'] as String,
      astrologerName: json['astrologerName'] as String,
      userId: json['userId'] as String,
      astrologerId: json['astrologerId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      gender: json['gender'] as String?,
      dob: json['dob'] as String,
      tob: json['tob'] as String?,
      birthPlace: json['birthPlace'] as String?,
      relationshipStatus: json['relationshipStatus'] as String?,
      occupation: json['occupation'] as String,
      topic: json['topic'] as String,
      status: json['status'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert ChatRequest to Firestore-compatible map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'astrologerName': astrologerName,
      'userId': userId,
      'astrologerId': astrologerId,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dob': dob,
      'tob': tob,
      'birthPlace': birthPlace,
      'relationshipStatus': relationshipStatus,
      'occupation': occupation,
      'topic': topic,
      'status': status,
      'createdAt': createdAt,
    };
  }
}