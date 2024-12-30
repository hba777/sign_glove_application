import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    final List<Widget> bottomBarPages = [
      HomeScreen(
        controller: _controller,
        onNavigate: (index) {
          if (connectedDevice != null) {
            disconnectDevice(); // Disconnect device on navigation
          }
          _pageController.jumpToPage(index);
        },
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
          if (connectedDevice != null) {
            disconnectDevice(); // Disconnect the device before navigating
          }
          _pageController.jumpToPage(index); // Navigate to the selected page
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
            itemLabel: 'Signs',
          ),
        ],
        kIconSize: 14,
        kBottomRadius: 14,
      ),
    );
  }
}
