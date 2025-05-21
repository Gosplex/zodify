import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/common/utils/images.dart';
import 'package:flutter/material.dart';

class AstrologerListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> astrologers = [
    {
      'name': 'Lorem ipsum',
      'image': 'https://img.freepik.com/free-psd/spectacular-flight-vivid-green-bird_191095-78393.jpg',
      'languages': 'English, Hindi',
      'experience': '8 Years',
      'rate': '30/min',
      'waitTime': '5m',
      'isOnline': true,
      'chat': true,
      'call': true,
      'video': true,
    },
    {
      'name': 'Lorem ipsum',
      'image': 'https://img.freepik.com/free-psd/conquering-summit-watercolor-painting-hikers-triumph_191095-77950.jpg',
      'languages': 'English, Hindi',
      'experience': '8 Years',
      'rate': '30/min',
      'waitTime': '3m',
      'isOnline': true,
      'chat': true,
      'call': true,
      'video': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () {}, // Add settings functionality
        ),
        title: Text(
          'Astrologer List', // Your app name
          style: AppTextStyles.heading2(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.black,
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage('https://img.freepik.com/free-psd/spectacular-flight-vivid-green-bird_191095-78393.jpg'),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.ic_background_astrologer),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54,
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            // Filter Chips
            Container(
              height: 50,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChipWidget(label: "Filter"),
                  FilterChipWidget(label: "All"),
                  FilterChipWidget(label: "Love"),
                  FilterChipWidget(label: "Offer"),
                  FilterChipWidget(label: "Education"),
                ],
              ),
            ),
            Divider(color: Colors.white30,),
            // Astrologer List
            Expanded(
              child: ListView.builder(
                itemCount: astrologers.length,
                itemBuilder: (context, index) {
                  final astro = astrologers[index];
                  return AstrologerCard(astro: astro);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;

  const FilterChipWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.purple.shade700,
        labelStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}

class AstrologerCard extends StatelessWidget {
  final Map<String, dynamic> astro;

  const AstrologerCard({required this.astro});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.withOpacity(0.4),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              // crossAxisAlignment: CrossAxisAlignment.,
              children: [
                // Profile Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    astro['image'],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(astro['name'],
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(width: 6),
                          Icon(Icons.verified, color: Colors.green, size: 16),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_city),
                          Expanded(
                            child: Text(
                              'Vastu consultation, Vedic Astrology +7 more',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.language),
                          Expanded(
                            child: Text(
                              '${astro['languages']}',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.cast_for_education),
                          Text(
                            '${astro['experience']}',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₹ ${astro['rate']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Status
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        astro['isOnline'] ? "Online" : "Offline",
                        style: TextStyle(
                            color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Wait = ${astro['waitTime']}',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                  ),
                )
              ],
            ),
            Divider(color: Colors.grey[700], height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.chat, "Chat", astro['chat']),
                _buildActionButton(Icons.call, "Call", astro['call']),
                _buildActionButton(Icons.video_call, "Video Call", astro['video']),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, bool enabled) {
    return ElevatedButton.icon(
      onPressed: enabled ? () {} : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? Colors.green : Colors.grey[800],
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white54,
        disabledBackgroundColor: Colors.grey[800],
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
