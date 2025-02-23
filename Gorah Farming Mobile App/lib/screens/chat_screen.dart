import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:gora_farming/widgets/water_distribution.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../controllers/user_controller.dart';
import '../structures/structs.dart' as structs;

import '../widgets/widgets.dart';

class Message {
  final String text;
  final bool isUser;
  final Widget? customWidget;

  Message({required this.text, required this.isUser, this.customWidget});
}

class IoTChatScreen extends StatefulWidget {
  const IoTChatScreen({super.key});

  @override
  State<IoTChatScreen> createState() => _IoTChatScreenState();
}

class _IoTChatScreenState extends State<IoTChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  final structs.User? goraUser = UserController().currentUser;
  String _rpiIP = "https://74d3-196-225-57-154.ngrok-free.app";

  // Mock values for demonstration
  double currentTemp = 25.0;
  double currentHumidity = 65.0;

  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'API_KEY');

  @override
  void initState() {
    _initializeIP();
    super.initState();
  }

  Future<void> _initializeIP() async {
    try {
      final docSnapshot = await _firestore.collection('ip').doc('rpi').get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _rpiIP = data?['ip'];
        print("RPi IP: $_rpiIP");
        print('Successfully fetched RPi IP: $_rpiIP');
      } else {
        print('RPi IP document not found in Firestore');
      }
    } catch (e) {
      print('Error fetching RPi IP from Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: theme.colorScheme.copyWith(secondary: theme.primaryColor),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.device_hub, color: theme.colorScheme.onPrimary),
              SizedBox(width: 8),
              Text(
                'Gorah Control Chat',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 20, // Adjust font size as needed
                  fontWeight: FontWeight.bold, // Make the title bold
                ),
              ),
            ],
          ),
          backgroundColor: theme.primaryColor,
          elevation: 4,
        ),
        body: Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              if (_messages.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 150,
                          height: 150,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Welcome, ${goraUser!.displayName}!",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          "To the Gorah Control Chat!",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Column(
                      crossAxisAlignment:
                          message.isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                message.isUser
                                    ? theme.primaryColor
                                    : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: TextStyle(
                                  color:
                                      message.isUser
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (message.customWidget != null) ...[
                                SizedBox(height: 8),
                                message.customWidget!,
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_isTyping)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: TypingIndicator(color: theme.colorScheme.secondary),
                ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        onSubmitted: _handleUserInput,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      color: theme.primaryColor,
                      onPressed: () => _handleUserInput(_controller.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMessage(String text, bool isUser, {Widget? customWidget}) {
    setState(() {
      _messages.add(
        Message(text: text, isUser: isUser, customWidget: customWidget),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _predictWaterUsage(String text) async {
    final response = await http.post(
      Uri.parse('$_rpiIP/predict'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(js),
    );

    /*
    {"Adjusted Water Distribution (mm/day)":
    [88.24031752299307,88.24031752299307,88.24031752299307,
    44.12015876149653,88.24031752299307,88.24031752299307,88.24031752299307],
    "SoilMoistureIndex":0.20293280412834486,
    "Water Needed for Next 7 Days (mm)":617.6822226609514}

     */

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final waterDistribution = data['Adjusted Water Distribution (mm/day)'];
      final waterNeeded = data['Water Needed for Next 7 Days (mm)'];
      final soilMoistureIndex = data['SoilMoistureIndex'];
      _addMessage(
        text,
        false,
        customWidget: WaterDistributionWidget(
          adjustedWaterDistribution: waterDistribution.cast<double>(),
          soilMoistureIndex: soilMoistureIndex,
          waterNeededNext7Days: waterNeeded,
        ),
      );
    } else {
      _addMessage('Failed to predict water usage', false);
    }
  }

  Future<structs.WeatherLocation> _getWeather() async {
    await Geolocator.requestPermission();

    // Get user's location
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    double latitude = position.latitude;
    double longitude = position.longitude;

    // Fetch weather data from Open-Meteo
    final response = await http.get(
      Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true',
      ),
    );
    return structs.WeatherLocation.fromJson(json.decode(response.body));
  }

  Widget _buildSensorDataWidget(
    double sensorTemp,
    double sensorHumidity,
    String temperature,
    String windSpeed,
    String conditions,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indoor section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Soil Sensor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temp: ${sensorTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        'Humidity: ${sensorHumidity.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Outdoor section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            getWeatherIcon(conditions),
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Outdoor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temp: $temperature°C',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        'Wind: $windSpeed km/h',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Conditions bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getWeatherIcon(conditions),
                  size: 14,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  conditions,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future _controlPump(String action, int delay) async {
    try {
      final response = await http.get(
        Uri.parse('$_rpiIP/motor/control?state=$action&delay=$delay'),
      );

      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to control motor"};
      }
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSensorData() async {
    try {
      final response = await http.get(Uri.parse('$_rpiIP/getData'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to get data"};
      }
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  Future<void> _handleUserInput(String text) async {
    if (text.trim().isEmpty) return;
    _addMessage(text, true);
    _controller.clear();
    setState(() => _isTyping = true);

    final prompt = '''
    User's Request: $text

    We have to understand the intent of the user's request and provide a response accordingly.
    There are three possibilities:
    1. The user is asking for sensors data (temperature, humidity or anything related to them), in which case you return a JSON response with keys: intent: 'sensors_data'
    2. The user is asking to take action on the water pump, in which case you return a JSON response with key: intent: 'water_pump'
    and key: delay: {delay in seconds depending on the user request, if the user didn't mention any delay, set it to 0} and 
    key: action: {true to open water pump or false to close it, if not provided set it to true}, and key: text: {response to the user's request}
    3. The user is asking for water usage prediction or forecast (it's always a 7 days period), in which case you return a JSON response with key: intent: 'water_usage_prediction' and key: text: {response to the user's request}
    4. The user is asking for a general query, in which case you return a JSON response with key: intent: 'general_query'
    and key: text: {response to the user's query}
  
    In case of any issues with the given data please provide:
    Format response as JSON with keys: problem: {the issue with the data}
    ''';

    try {
      // Check for IoT control commands
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final extractedJson = extractJson(response.text!);
      final jsonResponse = json.decode(extractedJson);

      if (jsonResponse['problem'] != null) {
        _addMessage(
          "Sorry, there was an error processing your request., ${jsonResponse['problem']}",
          false,
        );
        return;
      }

      if (jsonResponse['intent'] == 'sensors_data') {
        final val = await getSensorData();
        final weather = await _getWeather();
        final String temperature =
            weather.current_weather.temperature.toString();
        final String windSpeed = weather.current_weather.windspeed.toString();
        final conditions = getWeatherDescription(
          weather.current_weather.weathercode,
        );

        _addMessage(
          "Here are the current sensor readings:",
          false,
          customWidget: _buildSensorDataWidget(
            val["temperature"],
            val["humidity"],
            temperature,
            windSpeed,
            conditions,
          ),
        );
      } else if (jsonResponse['intent'] == 'water_pump') {
        if (jsonResponse['delay'] != null) {
          _addMessage(jsonResponse["text"], false);
          _controlPump(
            jsonResponse['action'] ? "on" : "off",
            jsonResponse['delay'],
          );
          // Add delay logic here
        } else {
          _addMessage(jsonResponse["text"], false);
          _controlPump(jsonResponse['action'] ? "on" : "off", 0);
          // Add immediate activation logic here
        }
      } else if (jsonResponse['intent'] == 'general_query') {
        _addMessage(jsonResponse['text'], false);
      } else if (jsonResponse['intent'] == 'water_usage_prediction') {
        _predictWaterUsage(jsonResponse['text']);
      } else {
        _addMessage("Sorry, I couldn't understand your request.", false);
      }
    } catch (e) {
      _addMessage("Sorry, there was an error processing your request.", false);
    }

    setState(() => _isTyping = false);
  }
}

const js = {
  "sequence": [
    [
      0.9044117647058822,
      0.8333333333333334,
      0.6270574066639902,
      0.6480797636632201,
      0.8102522812667741,
      0.22320709105560033,
      0.0,
      0.30600890207715137,
    ],
    [
      0.9044117647058822,
      0.8333333333333334,
      0.6134528747937016,
      0.6081979320531757,
      0.8266237251744498,
      0.0749395648670427,
      0.0,
      0.2805390702274976,
    ],
    [
      0.8958333333333334,
      0.8333333333333334,
      0.7071680271198535,
      0.6421713441654358,
      0.8639291465378423,
      0.06526994359387589,
      0.0,
      0.27200791295746785,
    ],
    [
      0.5612745098039216,
      0.8333333333333334,
      0.8013738346937864,
      0.6355243722304283,
      0.8483628556092325,
      0.23690572119258663,
      0.0,
      0.20017309594460928,
    ],
    [
      0.8970588235294118,
      0.8333333333333334,
      0.7610508943307013,
      0.6399556868537667,
      0.8808373590982288,
      0.31023368251410155,
      0.0,
      0.2403560830860534,
    ],
    [
      0.8872549019607843,
      0.8333333333333334,
      0.7011463490789063,
      0.7200886262924668,
      0.8617820719269995,
      0.19500402900886382,
      0.0022240756185710315,
      0.29438674579624136,
    ],
    [
      0.8946078431372548,
      0.8333333333333334,
      0.6499843882421159,
      0.6573116691285081,
      0.808641975308642,
      0.2707493956486704,
      0.0,
      0.3067507418397626,
    ],
  ],
};

String getWeatherDescription(int weatherCode) {
  Map<int, String> weatherDescriptions = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Drizzle: Light",
    53: "Drizzle: Moderate",
    55: "Drizzle: Dense",
    56: "Freezing drizzle: Light",
    57: "Freezing drizzle: Dense",
    61: "Rain: Slight",
    63: "Rain: Moderate",
    65: "Rain: Heavy",
    66: "Freezing rain: Light",
    67: "Freezing rain: Heavy",
    71: "Snowfall: Slight",
    73: "Snowfall: Moderate",
    75: "Snowfall: Heavy",
    77: "Snow grains",
    80: "Rain showers: Slight",
    81: "Rain showers: Moderate",
    82: "Rain showers: Violent",
    85: "Snow showers: Slight",
    86: "Snow showers: Heavy",
    95: "Thunderstorm: Slight or moderate",
    96: "Thunderstorm with slight hail",
    99: "Thunderstorm with heavy hail",
  };
  return weatherDescriptions[weatherCode] ?? "Unknown weather";
}

IconData getWeatherIcon(String conditions) {
  switch (conditions.toLowerCase()) {
    case "clear sky":
      return Icons.wb_sunny;
    case "mainly clear":
      return Icons.wb_sunny_outlined;
    case "partly cloudy":
      return Icons.cloud_queue;
    case "overcast":
      return Icons.cloud;
    case "fog":
    case "depositing rime fog":
      return Icons.foggy;
    case "drizzle: light":
    case "drizzle: moderate":
    case "drizzle: dense":
      return Icons.grain;
    case "freezing drizzle: light":
      return Icons.ac_unit;
    default:
      return Icons.wb_sunny;
  }
}

String extractJson(String responseText) {
  final RegExp regex = RegExp(r'```json\s*([\s\S]*?)\s*```');
  final Match? match = regex.firstMatch(responseText);

  if (match != null) {
    return match.group(1)!; // Extract JSON string
  } else {
    throw Exception("JSON block not found in the response");
  }
}
