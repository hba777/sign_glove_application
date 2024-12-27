import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  String receivedData = '';
  List<Map<String, dynamic>> parsedDataList = [];

  @override
  void initState() {
    super.initState();
    _scanForDevices();
    requestPermissions(); // Ensure permissions are requested
  }

  // Request Bluetooth permissions
  Future<void> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      _scanForDevices();
    } else {
      print("Bluetooth permissions not granted.");
    }
  }

  // Scan for Bluetooth devices
  Future<void> _scanForDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (!devices.contains(result.device)) {
          setState(() {
            devices.add(result.device);
          });
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

    // After connecting, query the name explicitly
    String deviceName = await device.name;
    print("Connected to $deviceName");

    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.properties.notify || char.properties.read) {
          setState(() {
            characteristic = char;
          });

          // Enable notifications to continuously receive data
          await char.setNotifyValue(true);
          char.value.listen((data) {
            // Log raw data to check if it's being received
            log('Received Raw Data: ${String.fromCharCodes(data)}');

            setState(() {
              // Concatenate the received data to the existing string
              receivedData += String.fromCharCodes(data);
              _processData(receivedData);
            });
          });
        }
      }
    }
  }

  // Process received data and break it into sets of Flex, Accel, and Gyro readings
  void _processData(String data) {
    // Log the entire received data to see what's coming in
    log('Full Data: $data');

    // Extract Flex, Accel, and Gyro data using regular expressions
    final flexPattern = RegExp(r'Flex:([-\d,]+)');
    final accelPattern = RegExp(r'Accel:([-\d,]+)');
    final gyroPattern = RegExp(r'Gyro:([-\d,]+)');

    final flexMatch = flexPattern.firstMatch(data);
    final accelMatch = accelPattern.firstMatch(data);
    final gyroMatch = gyroPattern.firstMatch(data);

    if (flexMatch != null && accelMatch != null && gyroMatch != null) {
      final flexData = flexMatch.group(1)?.split(',').map((e) => int.tryParse(e.trim())).toList() ?? [];
      final accelData = accelMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];
      final gyroData = gyroMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];

      // Ensure the data has exactly 5 Flex, 3 Accel, and 3 Gyro readings
      if (flexData.length == 5 && accelData.length == 3 && gyroData.length == 3) {
        final parsedData = {
          'Flex': flexData,
          'Accel': accelData,
          'Gyro': gyroData,
        };

        // Add the parsed data to the list
        parsedDataList.add(parsedData);

        // Reset the received data to start fresh for the next set
        receivedData = '';
        log('Parsed Data: $parsedData');
      }
    } else {
      log('Data did not match the expected pattern');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth JDY-31')),
      body: Column(
        children: [
          // Display available Bluetooth devices
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name.isEmpty ? "Unknown Device" : device.name),
                  subtitle: Text(device.id.toString()),
                  onTap: () => connectToDevice(device),
                );
              },
            ),
          ),
          const Divider(),
          // Display the received parsed data
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parsed Data:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...parsedDataList.map((data) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flex: ${data['Flex']?.join(', ') ?? "N/A"}', style: TextStyle(fontSize: 16)),
                        Text('Accel: ${data['Accel']?.join(', ') ?? "N/A"}', style: TextStyle(fontSize: 16)),
                        Text('Gyro: ${data['Gyro']?.join(', ') ?? "N/A"}', style: TextStyle(fontSize: 16)),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
