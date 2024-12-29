import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

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
    requestPermissions();
  }

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
            log('Received Raw Data: ${String.fromCharCodes(data)}');
            setState(() {
              receivedData += String.fromCharCodes(data);
              _processData(receivedData);
            });
          });
        }
      }
    }
  }

  void _processData(String data) async {
    log('Full Data: $data');

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

      if (flexData.length == 5 && accelData.length == 3 && gyroData.length == 3) {
        final parsedData = {
          'Flex': flexData,
          'Accel': accelData,
          'Gyro': gyroData,
        };

        parsedDataList.add(parsedData);
        receivedData = '';
        log('Parsed Data: $parsedData');

        // Send parsed data to the backend
        await _sendToBackend(parsedData);
      }
    } else {
      log('Data did not match the expected pattern');
    }
  }

  Future<void> _sendToBackend(Map<String, dynamic> data) async {
    final url = Uri.parse('http://10.0.2.2:8000/predict/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        log('Prediction: ${responseData['prediction']}');
        setState(() {
          parsedDataList.last['Prediction'] = responseData['prediction'];
        });
      } else {
        log('Error from backend: ${response.body}');
      }
    } catch (e) {
      log('Error sending data to backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth JDY-31')),
      body: Column(
        children: [
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
                        if (data['Prediction'] != null)
                          Text('Prediction: ${data['Prediction']}', style: TextStyle(fontSize: 16, color: Colors.green)),
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
