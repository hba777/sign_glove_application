import 'dart:convert';
import 'dart:developer';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart'; // Import the text-to-speech package

import '../main.dart';

class HomeScreen extends StatefulWidget {
  final NotchBottomBarController controller;
  final Function onNavigate; // Added callback to handle navigation
  const HomeScreen({super.key, required this.controller, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  String receivedData = '';
  List<Map<String, dynamic>> parsedDataList = [];
  var predictedLabel = '';
  final FlutterTts flutterTts = FlutterTts(); // Initialize text-to-speech instance

  @override
  void initState() {
    super.initState();
    _scanForDevices();
    requestPermissions(); // Ensure permissions are requested
    flutterTts.setLanguage("en-US"); // Set the language for TTS
    flutterTts.setSpeechRate(0.5); // Optional: adjust the speech rate
  }

  @override
  void dispose() {
    // Ensure the Bluetooth device is disconnected when the screen is disposed
    disconnectDevice();
    super.dispose();
  }

  // Request Bluetooth permissions
  Future<void> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      _scanForDevices();
    } else {
      print("Bluetooth permissions not granted.");
    }
  }

  // Function to disconnect from the Bluetooth device
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice?.disconnect();
      setState(() {
        connectedDevice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Disconnected from device")));
    }
  }

  // Scan for Bluetooth devices
  Future<void> _scanForDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        // Only add devices whose name contains "JDY-31-SPP"
        if (result.device.name.contains('JDY-31-SPP') && !devices.contains(result.device)) {
          // Check if the widget is still mounted before calling setState
          if (mounted) {
            setState(() {
              devices.add(result.device);
            });
          }
        }
      }
    });
  }

  // Connect to the Bluetooth device and set up notifications
  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectedDevice = device;
    });

    await device.connect();

    String deviceName = await device.name;
    print("Connected to $deviceName");

    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.properties.notify || char.properties.read) {
          setState(() {
            characteristic = char;
          });

          await char.setNotifyValue(true);
          char.value.listen((data) {
            setState(() {
              receivedData += String.fromCharCodes(data);
              _processData(receivedData);
            });
          });
        }
      }
    }
  }

  Future<void> _postDataToServer(Map<String, dynamic> data) async {
    final url = Uri.parse('https://5ce7-2401-ba80-aa16-a3b2-3433-68-ea62-e6da.ngrok-free.app/predict'); // Replace with your FastAPI server URL
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final label = responseData['label'];

        log('Label $label');
        setState(() {
          predictedLabel = label;
        });

        // After the 3-second delay, post the data and speak the label
        Future.delayed(Duration(seconds: 3), () async {
          //await flutterTts.speak(predictedLabel); // Speak the label
        });
      } else {
        print("Error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("Error sending data: $e");
    }
  }

  void _processData(String data) {
    final flexPattern = RegExp(r'Flex:\s*([-\d,]+)');
    final accelPattern = RegExp(r'Accel:\s*([-\d.,]+)');
    final gyroPattern = RegExp(r'Gyro:\s*([-\d.,]+)');

    final flexMatch = flexPattern.firstMatch(data);
    final accelMatch = accelPattern.firstMatch(data);
    final gyroMatch = gyroPattern.firstMatch(data);

    if (flexMatch != null && accelMatch != null && gyroMatch != null) {
      final flexData = flexMatch.group(1)?.split(',').map((e) => int.tryParse(e.trim())).toList() ?? [];
      final accelData = accelMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];
      final gyroData = gyroMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];

      if (flexData.length == 5 && accelData.length == 3 && gyroData.length == 3) {
        final formattedData = "Flex:${flexData.join(',')}|Accel:${accelData.join(',')}|Gyro:${gyroData.join(',')}";

        final parsedData = {
          "sensor_values": formattedData,
        };

        log('Parsed Data $parsedData');

        parsedDataList.clear();
        parsedDataList.add(parsedData);

        // Ensure widget is still mounted before calling setState
        if (mounted) {
          _postDataToServer(parsedData);
          setState(() {
            receivedData = '';
          });
        }
      } else {
        log('Accel and/or Gyro data does not have exactly 3 readings.');
      }
    } else {
      log('Data did not match the expected pattern');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen', style: TextStyle(fontSize: mq.width * .06)),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .035),
            child: InkWell(
              onTap: () {
                _scanForDevices();
              },
              child: const Icon(Icons.refresh, color: Colors.lightGreenAccent,),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Display the name of the device if available
          if (devices.isNotEmpty) ...[
            ListTile(
              title: Text(devices.first.name.isEmpty ? "Unknown Device" : devices.first.name, style: TextStyle(color: Colors.white),),
              subtitle: Text(devices.first.id.toString(), style: TextStyle(color: Colors.white),),
              onTap: () => connectToDevice(devices.first),
            ),
          ] else ...[
            const Text('No devices found',style: TextStyle(color: Colors.white)),
          ],
          const Divider(),
          // Display the received parsed data
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: mq.height *.03,),

              Text('Word:', style: TextStyle(fontSize: mq.width * .04, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(predictedLabel, style: TextStyle(fontSize: mq.width * .07, color: Colors.lightGreenAccent)),
              SizedBox(height: mq.height *.28,),
              ElevatedButton(
                onPressed: () {
                  String sanitizedLabel = predictedLabel.replaceAll('_', ' '); // Replace underscores with spaces
                  flutterTts.speak(sanitizedLabel); // Speak the sanitized label
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(mq.width *.5, mq.height *.06),
                  backgroundColor: Colors.black12
                ),
                child: const Text("Speak", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
