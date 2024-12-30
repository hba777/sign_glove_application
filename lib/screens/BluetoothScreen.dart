import 'dart:convert';
import 'dart:developer';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:sign_glove_application/screens/CommunicationScreen.dart';
import 'package:sign_glove_application/screens/HomeScreen.dart';

import '../main.dart';


class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  String receivedData = '';
  List<Map<String, dynamic>> parsedDataList = [];
  var predictedLabel = '';
  late PageController _pageController;
  late NotchBottomBarController _controller;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _controller = NotchBottomBarController(index: 0);
    // _scanForDevices();
    // requestPermissions(); // Ensure permissions are requested
  }

  // // Request Bluetooth permissions
  // Future<void> requestPermissions() async {
  //   final statuses = await [
  //     Permission.bluetooth,
  //     Permission.bluetoothConnect,
  //     Permission.bluetoothScan,
  //   ].request();
  //
  //   if (statuses.values.every((status) => status.isGranted)) {
  //     _scanForDevices();
  //   } else {
  //     print("Bluetooth permissions not granted.");
  //   }
  // }
  //
  // // Scan for Bluetooth devices
  Future<void> _scanForDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (!devices.contains(result.device)) {
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

  // // Connect to the Bluetooth device and set up notifications
  // Future<void> connectToDevice(BluetoothDevice device) async {
  //   setState(() {
  //     connectedDevice = device;
  //   });
  //
  //   await device.connect();
  //
  //   String deviceName = await device.name;
  //   print("Connected to $deviceName");
  //
  //   List<BluetoothService> services = await device.discoverServices();
  //
  //   for (var service in services) {
  //     for (var char in service.characteristics) {
  //       if (char.properties.notify || char.properties.read) {
  //         setState(() {
  //           characteristic = char;
  //         });
  //
  //         await char.setNotifyValue(true);
  //         char.value.listen((data) {
  //           setState(() {
  //             receivedData += String.fromCharCodes(data);
  //             _processData(receivedData);
  //           });
  //         });
  //       }
  //     }
  //   }
  // }
  //
  // Future<void> _postDataToServer(Map<String, dynamic> data) async {
  //   final url = Uri.parse('https://fa07-38-7-191-243.ngrok-free.app/predict'); // Replace with your FastAPI server URL
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(data),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body);
  //       final label = responseData['label'];
  //
  //       log('Label $label');
  //       setState(() {
  //         predictedLabel = label;
  //       });
  //     } else {
  //       print("Error: ${response.statusCode}, ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Error sending data: $e");
  //   }
  // }
  //
  // void _processData(String data) {
  //   final flexPattern = RegExp(r'Flex:\s*([-\d,]+)');
  //   final accelPattern = RegExp(r'Accel:\s*([-\d.,]+)');
  //   final gyroPattern = RegExp(r'Gyro:\s*([-\d.,]+)');
  //
  //   final flexMatch = flexPattern.firstMatch(data);
  //   final accelMatch = accelPattern.firstMatch(data);
  //   final gyroMatch = gyroPattern.firstMatch(data);
  //
  //   if (flexMatch != null && accelMatch != null && gyroMatch != null) {
  //     final flexData = flexMatch.group(1)?.split(',').map((e) => int.tryParse(e.trim())).toList() ?? [];
  //     final accelData = accelMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];
  //     final gyroData = gyroMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];
  //
  //     if (flexData.length == 5 && accelData.length == 3 && gyroData.length == 3) {
  //       final formattedData = "Flex:${flexData.join(',')}|Accel:${accelData.join(',')}|Gyro:${gyroData.join(',')}";
  //
  //       final parsedData = {
  //         "sensor_values": formattedData,
  //       };
  //
  //       log('Parsed Data $parsedData');
  //
  //       parsedDataList.clear();
  //       parsedDataList.add(parsedData);
  //       _postDataToServer(parsedData);
  //       receivedData = '';
  //     } else {
  //       log('Accel and/or Gyro data does not have exactly 3 readings.');
  //     }
  //   } else {
  //     log('Data did not match the expected pattern');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    final List<Widget> bottomBarPages = [
      HomeScreen(
        controller: (_controller),
      ),
      CommunicationScreen()

    ];
    return Scaffold(
      body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(bottomBarPages.length, (index) => bottomBarPages[index]),
      ),
      bottomNavigationBar: AnimatedNotchBottomBar(
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
        notchBottomBarController: _controller,
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(
              Icons.home_filled,
              color: Colors.blueGrey,
            ),
            activeItem: Icon(
              Icons.home_filled,
              color: Colors.blueAccent,
            ),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.chat_bubble_outline,
              color: Colors.blueGrey,
            ),
            activeItem: Icon(
              Icons.chat_bubble_outline,
              color: Colors.blueAccent,
            ),
            itemLabel: 'Communication',
          ),
        ],
        kIconSize: 14, kBottomRadius: 14,
      ),
    );
  }
}
