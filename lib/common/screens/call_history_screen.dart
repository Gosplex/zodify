import 'package:astrology_app/common/utils/images.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class CallHistoryScreen extends StatefulWidget {
  String type;
  CallHistoryScreen({super.key, required this.type});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var historyData=[];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }


  _fetchHistory() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      querySnapshot = await _firestore
          .collection('callHistory')
          .where('receiverId', isEqualTo: userStore.user?.id)
          .where('callType', isEqualTo: widget.type)
          .get();
      print("CheckCount::::${querySnapshot.docs.length}");
      querySnapshot.docs.forEach((element) {
        historyData.add(element.data());
      },);
      print("Check list Value:::${historyData}");
      setState(() {});
    } catch (e, s) {
      debugPrint('Error fetching astrologers: $e:::$s');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(8),
        ),
        title: const Text(
          'Call History',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Initiate new call')),
        ),
        backgroundColor: Colors.amber[700],
        mini: true,
        child: const FaIcon(FontAwesomeIcons.phone, color: Colors.white, size: 20),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(AppImages.ic_background_user),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: historyData.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                      indent: 60,
                    ),
                    itemBuilder: (context, index) => _buildCallItem(historyData[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallItem(var callData) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[800]!.withOpacity(0.6),
        ),
        child: Icon(
          Icons.call_received,
          color:Colors.amber[700],
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              callData.keys.contains("callerName")?
              callData['callerName']:"Anonymous User",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
          DateFormat('dd MMM yyyy, hh:mm a').format(
              DateTime.parse(callData['timestamp'].toString())).toString(),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                callData['callType']=="video" ? Icons.videocam : Icons.call,
                size: 14,
                color: Colors.white70,
              ),
              Text(
                ' ${callData['callType']}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          // const SizedBox(width: 4),
          Text(
            'Duration: ${callData['durationSeconds']} Seconds',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      dense: true,
    );
  }
}

// class Call {
//   final String type;
//   final String duration;
//   final DateTime date;
//   final String contactName;
//   final bool video;
//
//   Call({
//     required this.type,
//     required this.duration,
//     required this.date,
//     required this.contactName,
//     this.video = false,
//   });
// }
//
// final List<Call> dummyCalls = [
//   Call(type: 'Missed', duration: 'Missed', date: DateTime.now().subtract(const Duration(minutes: 15)), contactName: 'Priya Sharma'),
//   Call(type: 'Outgoing', duration: '12m 30s', date: DateTime.now().subtract(const Duration(hours: 2)), contactName: 'Raj Patel', video: true),
//   Call(type: 'Incoming', duration: '8m 15s', date: DateTime.now().subtract(const Duration(days: 1)), contactName: 'Dr. Amit Joshi'),
//   Call(type: 'Missed', duration: 'Missed', date: DateTime.now().subtract(const Duration(days: 1, hours: 3)), contactName: 'Neha Gupta', video: true),
//   Call(type: 'Outgoing', duration: '20m 45s', date: DateTime.now().subtract(const Duration(days: 2)), contactName: 'Manoj Kumar'),
// ];