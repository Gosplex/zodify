import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../utils/common.dart';

class HoroscopeTabs extends StatefulWidget {
  @override
  _HoroscopeTabsState createState() => _HoroscopeTabsState();
}

class _HoroscopeTabsState extends State<HoroscopeTabs> with SingleTickerProviderStateMixin {
  late TabController _tc;

  String? txt,img;
  final tabs = [
    Tab(text: 'Basic Kundli'),
    Tab(text: 'Lagna'),
    Tab(text: 'Navamsa'),
    Tab(text: 'Transit'),
    Tab(text: 'Dasha'),
    Tab(text: 'Ashtkvarga'),
    Tab(text: 'Planet'),
    Tab(text: 'Chart'),
    Tab(text: 'KP'),
    Tab(text: 'Manglik'),
  ];

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: tabs.length, vsync: this);
    _tc.addListener(() {
      if (_tc.indexIsChanging) return; // Avoid calling during animation
      switch (_tc.index) {
        case 0:
        // Load data or do setup for Tab 0
          break;
        case 1:
        // Setup for Tab 1
          break;
        case 2:
        // Setup for Tab 2
          break;
      }
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horoscope'),
        bottom: TabBar(controller: _tc, tabs: tabs, isScrollable: true,onTap: (value) {
          setState(() {
            _tc.animateTo(value);
          });
        },),
      ),
      body: TabBarView(
          controller: _tc, children: [
        for(int i=0;i<tabs.length;i++)
        DailyHoroscopePage(key: Key(i.toString()),text:tabs[i].text),
      ]),
    );
  }
}

class DailyHoroscopePage extends StatefulWidget {
  String? text;
  DailyHoroscopePage({super.key, this.text});

  @override
  _DailyHoroscopePageState createState() => _DailyHoroscopePageState();

}

class _DailyHoroscopePageState extends State<DailyHoroscopePage> {
  String textResponse='';
  String? imageResponse;

  @override
  Widget build(BuildContext c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(textResponse??''),
            if(imageResponse!=null)
              SvgPicture.string(
                color: Colors.red,
                imageResponse??'',
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async{
    print("CheckInitCall::${widget.text}");
    if(widget.text=="Basic Kundli"){
      var b=await KundliApiService.getKundliDetails(dateTime: "2004-02-12T15:19:21%2B05:30", location: '31.5143178,31.5143178',ayanamsa: 1);
      setState(() {
        textResponse=generateKundliText(b);
      });
    }else if(widget.text=="Lagna"){
      print("CheckInitCall:115");
      // north-indian south-indian east-indian
      var b=await KundliApiService.getApiCall("chart",{
        "ayanamsa":"1",
        "coordinates":"31.5143178,31.5143178",
        "datetime":"1997-09-04T03:30:00+05:30",
        "chart_type":"lagna",
        "chart_style":"north-indian",
        "format":"svg",
        "la":"en",
      });
      setState(() {
        imageResponse=b;
      });
    }else if(widget.text=="Navamsa"){
      var b=await KundliApiService.getApiCall("chart",{
        "ayanamsa":"1",
        "coordinates":"31.5143178,31.5143178",
        "datetime":"1997-09-04T03:30:00+05:30",
        "chart_type":"navamsa",
        "chart_style":"north-indian",
        "format":"svg",
        "la":"en",
      });
      setState(() {
        imageResponse=b;
      });
    }else if(widget.text=="Transit"){
    // https://api.prokerala.com/v2/astrology/transit-chart
      var b=await KundliApiService.getApiCall("transit-chart",{
        "ayanamsa":"1",
        "current_coordinates":"31.5143178,31.5143178",
        "transit_datetime":"1997-09-04T03:30:00+05:30",
        "house_system":"placidus",
        "chart_type":"navamsa",
        "chart_style":"north-indian",
        "format":"svg",
        "la":"en",
      });
      setState(() {
        imageResponse=b;
      });
    }else if(widget.text=="Dasha"){
      var b=await KundliApiService.getApiCall("dasha-periods",{
        "ayanamsa":"1",
        "coordinates":"31.5143178,31.5143178",
        "datetime":"1997-09-04T03:30:00+05:30",
        "la":"en",
      });
      // b=jsonDecode(b);
      print('CheckDataJsonmn:::$b');
      setState(() {
        for(int k=0;k<b['dasha_periods'].length;k++)
        textResponse+='${b['dasha_periods'][k]['name']} \nStart: ${b['dasha_periods'][k]['start']}\nEnd: ${b['dasha_periods'][k]['end']}\n';
        // textResponse=generateKundliText(b);
      });
    }else if(widget.text=="Ashtkvarga"){
      var b=await KundliApiService.getApiCall("ashtakavarga-chart",{
        "ayanamsa":"1",
        "coordinates":"31.5143178,31.5143178",
        "datetime":"1997-09-04T03:30:00+05:30",
        "planet":"1",
        "chart_style":"north-indian",
        "la":"en",
        "type":"prastara",
      });
      setState(() {
       imageResponse=b;
      });

    }else if(widget.text=="Planet"){
      var b=await KundliApiService.getApiCall("planet-position",{
        "coordinates":"31.5143178,31.5143178",
        "ayanamsa":"1",
        "datetime":"1997-09-04T03:30:00+05:30",
      });
      setState(() {
        for(int k=0;k<b['planet_position'].length;k++)
          textResponse+='Planet: ${b['planet_position'][k]['name']}\ndegree: ${b['planet_position'][k]['degree']}\n';
      });
    }else if(widget.text=="Chart"){
      var b=await KundliApiService.getApiCall('chart',{
        "coordinates":"31.5143178,31.5143178",
        "ayanamsa":"1",
        "chart_type":"rasi",
        "chart_style":"north-indian",
        "format":"svg",
        "datetime":"1997-09-04T03:30:00+05:30",
      });
      setState(() {
        imageResponse=b;
      });
    }else if(widget.text=="KP"){

    }else if(widget.text=="Manglik"){
      var b=await KundliApiService.getApiCall("mangal-dosha",{
        "ayanamsa":"1",
        "coordinates":"31.5143178,31.5143178",
        "datetime":"1997-09-04T03:30:00+05:30",
        "la":"en",
      });
      setState(() {
          textResponse=b['description'];
        // textResponse=generateKundliText(b);
      });
    }
  }

  String generateKundliText(Map<String, dynamic> data) {
    String getValue(dynamic map, List<String> keys, {String defaultValue = 'N/A'}) {
      dynamic current = map;
      for (var key in keys) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return defaultValue;
        }
      }
      return current?.toString() ?? defaultValue;
    }

    // Safely extract yoga lists
    final yogaDetails = data['yoga_details'] as List<dynamic>?;
    final dasha_periods = data['dasha_periods'] as List<dynamic>?;
    final majorYogas = yogaDetails?.isNotEmpty == true ? yogaDetails![0]['yoga_list'] as List<dynamic>? : [];
    final inauspiciousYogas = yogaDetails?.length == 4 ? yogaDetails![3]['yoga_list'] as List<dynamic>? : [];

    final presentYogas = (majorYogas ?? [])
        .where((yoga) => yoga['has_yoga'] == true)
        .map((yoga) => '✅ ${yoga['name'] ?? 'Unknown'}')
        .join('\n   ');

    final presentInauspicious = (inauspiciousYogas ?? [])
        .where((yoga) => yoga['has_yoga'] == true)
        .map((yoga) => '❗ ${yoga['name'] ?? 'Unknown'}')
        .join('\n   ');

    return '''
🔹 Nakshatra: ${getValue(data, ['nakshatra_details', 'nakshatra', 'name'])} (Pada ${getValue(data, ['nakshatra_details', 'nakshatra', 'pada'])})
🔹 Nakshatra Lord: ${getValue(data, ['nakshatra_details', 'nakshatra', 'lord', 'name'])}

🌙 Chandra Rasi: ${getValue(data, ['nakshatra_details', 'chandra_rasi', 'name'])}
   ➤ Lord: ${getValue(data, ['nakshatra_details', 'chandra_rasi', 'lord', 'name'])} (${getValue(data, ['nakshatra_details', 'chandra_rasi', 'lord', 'vedic_name'])})

☀️ Soorya Rasi: ${getValue(data, ['nakshatra_details', 'soorya_rasi', 'name'])}
   ➤ Lord: ${getValue(data, ['nakshatra_details', 'soorya_rasi', 'lord', 'name'])} (${getValue(data, ['nakshatra_details', 'soorya_rasi', 'lord', 'vedic_name'])})

♒ Zodiac Sign: ${getValue(data, ['nakshatra_details', 'zodiac', 'name'])}

📌 Additional Info:
   ➤ Deity: ${getValue(data, ['nakshatra_details', 'additional_info', 'deity'])}
   ➤ Ganam: ${getValue(data, ['nakshatra_details', 'additional_info', 'ganam'])}
   ➤ Symbol: ${getValue(data, ['nakshatra_details', 'additional_info', 'symbol'])}
   ➤ Animal Sign: ${getValue(data, ['nakshatra_details', 'additional_info', 'animal_sign'])}
   ➤ Nadi: ${getValue(data, ['nakshatra_details', 'additional_info', 'nadi'])}
   ➤ Color: ${getValue(data, ['nakshatra_details', 'additional_info', 'color'])}
   ➤ Best Direction: ${getValue(data, ['nakshatra_details', 'additional_info', 'best_direction'])}
   ➤ Syllables: ${getValue(data, ['nakshatra_details', 'additional_info', 'syllables'])}
   ➤ Birth Stone: ${getValue(data, ['nakshatra_details', 'additional_info', 'birth_stone'])}
   ➤ Gender: ${getValue(data, ['nakshatra_details', 'additional_info', 'gender'])}
   ➤ Planet: ${getValue(data, ['nakshatra_details', 'additional_info', 'planet'])}
   ➤ Enemy Yoni: ${getValue(data, ['nakshatra_details', 'additional_info', 'enemy_yoni'])}

🔥 Mangal Dosha: ${getValue(data, ['mangal_dosha', 'has_dosha']) == 'true' ? '✅ Manglik' : '❌ Not Manglik'}

🧘‍♂️ Major Yogas:
   ${presentYogas.isNotEmpty ? presentYogas : 'None'}

⚠️ Inauspicious Yogas:
   ${presentInauspicious.isNotEmpty ? presentInauspicious : 'None'}
    
''';
  }

}
