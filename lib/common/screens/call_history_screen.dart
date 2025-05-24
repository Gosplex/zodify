import 'package:astrology_app/common/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[800]!.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.amber[700]!.withOpacity(0.3)),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.white70, size: 18),
                        hintText: 'Search call history',
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: dummyCalls.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                      indent: 60,
                    ),
                    itemBuilder: (context, index) => _buildCallItem(dummyCalls[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallItem(Call call) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM dd');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(call.date.year, call.date.month, call.date.day);

    String dateText = callDate == today
        ? 'Today'
        : callDate == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : dateFormat.format(call.date);

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
          call.type == 'Missed'
              ? Icons.call_missed
              : call.type == 'Outgoing'
              ? Icons.call_made
              : Icons.call_received,
          color: call.type == 'Missed'
              ? Colors.red[400]
              : call.type == 'Outgoing'
              ? Colors.green[400]
              : Colors.amber[700],
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              call.contactName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeFormat.format(call.date),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Icon(
            call.video ? Icons.videocam : Icons.call,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            '${call.type} • ${call.duration}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      trailing: call.type == 'Missed'
          ? IconButton(
        icon: const Icon(Icons.call, color: Colors.amber, size: 20),
        padding: const EdgeInsets.all(4),
        onPressed: () {},
      )
          : null,
      dense: true,
    );
  }
}

class Call {
  final String type;
  final String duration;
  final DateTime date;
  final String contactName;
  final bool video;

  Call({
    required this.type,
    required this.duration,
    required this.date,
    required this.contactName,
    this.video = false,
  });
}

final List<Call> dummyCalls = [
  Call(type: 'Missed', duration: 'Missed', date: DateTime.now().subtract(const Duration(minutes: 15)), contactName: 'Priya Sharma'),
  Call(type: 'Outgoing', duration: '12m 30s', date: DateTime.now().subtract(const Duration(hours: 2)), contactName: 'Raj Patel', video: true),
  Call(type: 'Incoming', duration: '8m 15s', date: DateTime.now().subtract(const Duration(days: 1)), contactName: 'Dr. Amit Joshi'),
  Call(type: 'Missed', duration: 'Missed', date: DateTime.now().subtract(const Duration(days: 1, hours: 3)), contactName: 'Neha Gupta', video: true),
  Call(type: 'Outgoing', duration: '20m 45s', date: DateTime.now().subtract(const Duration(days: 2)), contactName: 'Manoj Kumar'),
];