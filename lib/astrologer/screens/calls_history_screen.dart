// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class CallHistoryScreen extends StatelessWidget {
//   const CallHistoryScreen({super.key});
//
//
//
//
//
//
//
//   String formatDuration(int seconds) {
//     final duration = Duration(seconds: seconds);
//     return duration.inMinutes > 0
//         ? '${duration.inMinutes} min ${duration.inSeconds % 60} sec'
//         : '${duration.inSeconds} sec';
//   }
//
//   String formatTimestamp(Timestamp timestamp) {
//     final date = timestamp.toDate();
//     return DateFormat('dd MMM yyyy, hh:mm a').format(date);
//   }
//
//   IconData getCallIcon(String callType) {
//     return callType == 'video' ? Icons.videocam : Icons.call;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text("Call History"),
//         backgroundColor: Colors.black,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('callHistory')
//             .orderBy('timestamp', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error loading data'));
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final docs = snapshot.data?.docs ?? [];
//
//           if (docs.isEmpty) {
//             return const Center(child: Text('No call history found', style: TextStyle(color: Colors.white)));
//           }
//
//           return ListView.separated(
//             itemCount: docs.length,
//             separatorBuilder: (_, __) => Divider(color: Colors.grey.shade800),
//             itemBuilder: (context, index) {
//               final data = docs[index].data() as Map<String, dynamic>;
//
//               final callType = data['callType'] ?? 'audio';
//               final status = data['status'] ?? 'ended';
//               final duration = data['durationSeconds'] ?? 0;
//               final timestamp = data['timestamp'] as Timestamp?;
//
//               return ListTile(
//                 leading: Icon(getCallIcon(callType), color: Colors.white),
//                 title: Text(
//                   'Call Type: $callType',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Status: $status', style: const TextStyle(color: Colors.grey)),
//                     Text('Duration: ${formatDuration(duration)}', style: const TextStyle(color: Colors.grey)),
//                     if (timestamp != null)
//                       Text('Time: ${formatTimestamp(timestamp)}', style: const TextStyle(color: Colors.grey)),
//                   ],
//                 ),
//                 trailing: const Icon(Icons.chevron_right, color: Colors.white),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
