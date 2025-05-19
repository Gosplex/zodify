import 'package:astrology_app/common/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LiveStreamingScreen extends StatelessWidget {
  const LiveStreamingScreen({super.key});

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
          'Live Streams',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start new live stream')),
        ),
        backgroundColor: const Color(0xFF6B4F00), // Dark amber
        mini: true,
        child: const FaIcon(FontAwesomeIcons.video, color: Colors.white, size: 20),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(AppImages.ic_background_user),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.darken), // Darker overlay
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
                      color: const Color(0xFF1A1A1A).withOpacity(0.4), // Near-black
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF6B4F00).withOpacity(0.3)),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.white70, size: 18),
                        hintText: 'Search live streams',
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: dummyLiveStreams.length,
                    itemBuilder: (context, index) => _buildLiveCard(dummyLiveStreams[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard(LiveStream stream) {
    final duration = DateTime.now().difference(stream.startTime);
    final durationText = '${duration.inMinutes}m ${duration.inSeconds % 60}s';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.9), // Darker grey-black
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // Darker shadow
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Image
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4F00), Color(0xFF1A1A1A)], // Dark amber to near-black
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.live_tv,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          // Stream Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Streamer Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A).withOpacity(0.6),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF6B4F00), // Dark amber
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Streamer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stream.streamerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.videocam,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live • ${stream.viewerCount} viewers • $durationText',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Join Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4F00), // Dark amber
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Join'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveStream {
  final String streamerName;
  final DateTime startTime;
  final int viewerCount;

  LiveStream({
    required this.streamerName,
    required this.startTime,
    required this.viewerCount,
  });
}

final List<LiveStream> dummyLiveStreams = [
  LiveStream(
    streamerName: 'Priya Sharma',
    startTime: DateTime.now().subtract(const Duration(minutes: 45)),
    viewerCount: 120,
  ),
  LiveStream(
    streamerName: 'Raj Patel',
    startTime: DateTime.now().subtract(const Duration(minutes: 20)),
    viewerCount: 85,
  ),
  LiveStream(
    streamerName: 'Dr. Amit Joshi',
    startTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
    viewerCount: 200,
  ),
  LiveStream(
    streamerName: 'Neha Gupta',
    startTime: DateTime.now().subtract(const Duration(minutes: 10)),
    viewerCount: 50,
  ),
];