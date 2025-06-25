import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../utils/colors.dart';
import '../utils/common.dart';

class HoroscopeTabs extends StatefulWidget {
  int ayanmasa;
  String dob;
  String location;
  HoroscopeTabs({super.key, required this.ayanmasa,required this.dob,required this.location});

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

    Tab(text: 'Dasha'),
    Tab(text: 'Ashtkvarga'),
    Tab(text: 'Planet'),
    Tab(text: 'Chart'),

    Tab(text: 'Manglik'),

    Tab(text: 'Sarvashtak'),
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
        DailyHoroscopePage(key: Key(i.toString()),text:tabs[i].text,location:widget.location,dob:widget.dob,ayanmasa:widget.ayanmasa,),
      ]),
    );
  }
}

class DailyHoroscopePage extends StatefulWidget {
  String? text,location,dob;
  int ayanmasa;
  DailyHoroscopePage({super.key, this.text, required this.location,required this.ayanmasa,this.dob});

  @override
  _DailyHoroscopePageState createState() => _DailyHoroscopePageState();

}

class _DailyHoroscopePageState extends State<DailyHoroscopePage> {
  String textResponse='';
  String? imageResponse;
  String selectedChartStyle="north-indian";
  var chartStyle=["north-indian" ,"south-indian", "east-indian"];

  @override
  Widget build(BuildContext c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.text == "Lagna" ||
                widget.text == "Navamsa" ||
                widget.text == "Ashtkvarga" ||
                widget.text == "Chart")
            Padding(
              padding:EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Chart-Style",style: TextStyle(color: Colors.black),),
            ),
            if (widget.text == "Lagna" ||
                widget.text == "Navamsa" ||
                widget.text == "Ashtkvarga" ||
                widget.text == "Chart")
            Container(
              decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12)
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              margin: EdgeInsets.all(16),
              child: DropdownButton<String>(
                value: selectedChartStyle,
                underline: SizedBox(),
                borderRadius: BorderRadius.circular(12),
                dropdownColor: AppColors.primaryDark,
                isExpanded: true,
                style: TextStyle(color: Colors.white),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedChartStyle = newValue;
                      init();
                    });
                  }
                },
                items: chartStyle.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option,style: TextStyle(color: Colors.white),),
                  );
                }).toList(),
              ),
            ),
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
      var b=await KundliApiService.getKundliDetails(dateTime: "${widget.dob}", location: '${widget.location}',ayanamsa: widget.ayanmasa);
      setState(() {
        textResponse=generateKundliText(b);
      });
    }else if(widget.text=="Lagna"){
      var b=await KundliApiService.getApiCall("chart",{
        "ayanamsa":"${widget.ayanmasa}",
        "coordinates":"${widget.location}",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
        "chart_type":"lagna",
        "chart_style":"${selectedChartStyle}",
        "format":"svg",
        "la":"en",
      });
      setState(() {
        imageResponse=b;
      });
    }else if(widget.text=="Navamsa"){
      var b=await KundliApiService.getApiCall("chart",{
        "ayanamsa":"${widget.ayanmasa}",
        "coordinates":"${widget.location}",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
        "chart_type":"navamsa",
        "chart_style":"${selectedChartStyle}",
        "format":"svg",
        "la":"en",
      });
      setState(() {
        imageResponse=b;
      });
    }else if(widget.text=="Dasha"){
      var b=await KundliApiService.getApiCall("dasha-periods",{
        "ayanamsa":"${widget.ayanmasa}",
        "coordinates":"${widget.location}",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
        "la":"en",
      });
      print('CheckDataJsonmn:::$b');
      setState(() {
        for(int k=0;k<b['dasha_periods'].length;k++)
        textResponse+='${b['dasha_periods'][k]['name']} \nStart: ${b['dasha_periods'][k]['start']}\nEnd: ${b['dasha_periods'][k]['end']}\n';
        // textResponse=generateKundliText(b);
      });
    }else if(widget.text=="Ashtkvarga"){
      var b=await KundliApiService.getApiCall("ashtakavarga-chart",{
        "ayanamsa":"${widget.ayanmasa}",
        "coordinates":"${widget.location}",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
        "planet":"1",
        "chart_style":"${selectedChartStyle}",
        "la":"en",
        "type":"prastara",
      });
      setState(() {
       imageResponse=b;
      });

    }else if(widget.text=="Planet"){
      var b=await KundliApiService.getApiCall("planet-position",{
        "coordinates":"${widget.location}",
        "ayanamsa":"${widget.ayanmasa}",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
      });
      setState(() {
        for(int k=0;k<b['planet_position'].length;k++)
          textResponse+='Planet: ${b['planet_position'][k]['name']}\ndegree: ${b['planet_position'][k]['degree']}\n';
      });
    }else if(widget.text=="Chart"){
      var b=await KundliApiService.getApiCall('chart',{
        "coordinates":"${widget.location}",
        "ayanamsa":"${widget.ayanmasa}",
        "chart_type":"rasi",
        "chart_style":"${selectedChartStyle}",
        "format":"svg",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
      });
      setState(() {
        imageResponse=b;
      });
    }else if(widget.text=="Manglik"){
      var b=await KundliApiService.getApiCall("mangal-dosha",{
        "ayanamsa":"${widget.ayanmasa}",
        "coordinates":"${widget.location}",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
        "la":"en",
      });
      setState(() {
          textResponse=b['description'];
      });
    }else if(widget.text=="Sarvashtak"){
      var b=await KundliApiService.getApiCall("sarvashtakavarga",{
        "ayanamsa":"${widget.ayanmasa}",
        "coordinates":"${widget.location}",
        "datetime":"${widget.dob.toString().replaceAll("%2B", "+")}",
        "la":"en",
      });
      setState(() {
        final buffer = StringBuffer();
        final houses = b['sarvashtakavarga']?['prastara']?['houses'] ?? [];

        for (var houseData in houses) {
          final house = houseData['house'];
          final rasi = houseData['rasi'];
          final planets = houseData['planets'] ?? [];
          final score = houseData['score'];

          buffer.writeln('🏠 House: ${house['name']} (${house['number']})');
          buffer.writeln('🔯 Rasi: ${rasi['name']} (Lord: ${rasi['lord']['name']})');
          buffer.writeln('🪐 Planet Scores:');

          for (var planetData in planets) {
            final planet = planetData['planet'];
            buffer.writeln('   - ${planet['name']} (${planet['vedic_name']}): ${planetData['score']}');
          }

          buffer.writeln('📊 Total Score: $score');
          buffer.writeln('------------------------');
        }

        textResponse=buffer.toString();
        // textResponse=generateKundliText(b);
      });
    }
    // Tab(text: 'Vimshottari'),
    // Tab(text: 'Jaimini'),
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
