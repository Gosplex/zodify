class CallHistory {
  final String id;
  final String callerId;
  final String receiverId;
  final String channelName;
  final String callType;
  final String status;
  final int durationSeconds;
  final DateTime timestamp;

  CallHistory({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.channelName,
    required this.callType,
    required this.status,
    required this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'channelName': channelName,
      'callType': callType,
      'status': status,
      'durationSeconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CallHistory.fromMap(Map<String, dynamic> map) {
    return CallHistory(
      id: map['id'],
      callerId: map['callerId'],
      receiverId: map['receiverId'],
      channelName: map['channelName'],
      callType: map['callType'],
      status: map['status'],
      durationSeconds: map['durationSeconds'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}