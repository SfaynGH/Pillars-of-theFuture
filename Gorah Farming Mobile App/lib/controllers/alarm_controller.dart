import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;


class FireAlarmService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _rpiIP;

  FireAlarmService() {
    _initializeNotifications();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _fetchRPiIP();
    if (_rpiIP != null) {
      _startFireCheck();
    }
  }

  Future<void> _fetchRPiIP() async {
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

  void _initializeNotifications() {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings = InitializationSettings(android: androidSettings);
    notificationsPlugin.initialize(settings);
  }

  Future<void> _showNotification() async {
    print("Fire detected! Showing notification");
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fire_alarm_channel',
      'Fire Alarm',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await notificationsPlugin.show(0, '🔥 Fire Alert!', 'Fire detected! Take action now!', details);
  }

  Future<void> _playAlarm() async {
    await audioPlayer.play(AssetSource("sounds/alarm.mp3")); // Place alarm.mp3 in assets/audio/
  }

  Future<void> _checkFireStatus() async {
    print("Checking fire status");
    try {
      final response = await http.get(Uri.parse('$_rpiIP/checkFire'));
      print("Fire status response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['fire_detected'] == true) {
          _showNotification();
          _playAlarm();
        }
      }
    } catch (e) {
      print("Error checking fire status: $e");
    }
  }

  void _startFireCheck() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      _checkFireStatus();
    });
  }
}
