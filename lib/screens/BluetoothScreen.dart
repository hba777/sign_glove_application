import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _postDataToServer(Map<String, dynamic> data) async {
    //log(data.toString());
    final url = Uri.parse('https://fa07-38-7-191-243.ngrok-free.app/predict'); // Replace with your FastAPI server URL
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
        // Display the predicted label
        setState(() {
          //parsedDataList.add({...data, 'Prediction': label});
          predictedLabel= label;
        });
      } else {
        print("Error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("Error sending data: $e");
    }
  }

  // Process received data and break it into sets of Flex, Accel, and Gyro readings
  void _processData(String data) {
    // Log the entire received data to see what's coming in
    // log('Full Data: $data');

    // Extract Flex, Accel, and Gyro data using regular expressions
    final flexPattern = RegExp(r'Flex:\s*([-\d,]+)');
    final accelPattern = RegExp(r'Accel:\s*([-\d.,]+)'); // Improved for decimals and negatives
    final gyroPattern = RegExp(r'Gyro:\s*([-\d.,]+)');   // Improved for decimals and negatives

    final flexMatch = flexPattern.firstMatch(data);
    final accelMatch = accelPattern.firstMatch(data);
    final gyroMatch = gyroPattern.firstMatch(data);

    // log('Flex Match: $flexMatch');
    // log('Accel Match: $accelMatch');
    // log('Gyro Match: $gyroMatch');

    if (flexMatch != null && accelMatch != null && gyroMatch != null) {
      final flexData = flexMatch.group(1)?.split(',').map((e) => int.tryParse(e.trim())).toList() ?? [];
      final accelData = accelMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];
      final gyroData = gyroMatch.group(1)?.split(',').map((e) => double.tryParse(e.trim())).toList() ?? [];

      // log('Flex Data: $flexData');
      // log('Accel Data: $accelData');
      // log('Gyro Data: $gyroData');

      // Ensure the data has exactly 5 Flex, 3 Accel, and 3 Gyro readings
      if (flexData.length == 5 && accelData.length == 3 && gyroData.length == 3) {
        // Create a formatted string for sensor values
        final formattedData = "Flex:${flexData.join(',')}|Accel:${accelData.join(',')}|Gyro:${gyroData.join(',')}";

        final parsedData = {
          "sensor_values": formattedData,
        };

        log('Parsed Data $parsedData');

        // Add the parsed data to the list
        parsedDataList.clear();  // Ensure only the most recent data is displayed
        parsedDataList.add(parsedData);
        _postDataToServer(parsedData);
        // Reset the received data to start fresh for the next set
        receivedData = '';
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
                  Text('Label:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(predictedLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
