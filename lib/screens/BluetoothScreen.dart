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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Disconnected from device")));
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
      const CommunicationScreen()
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(bottomBarPages.length, (index) => bottomBarPages[index]),
      ),
      bottomNavigationBar: AnimatedNotchBottomBar(
        circleMargin: mq.width *.07,
        onTap: (index) {
          if (connectedDevice != null) {
            disconnectDevice(); // Disconnect the device before navigating
          }
          _pageController.jumpToPage(index); // Navigate to the selected page
        },
        notchBottomBarController: _controller,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.home_filled,
              color: Colors.lightGreen,
            ),
            activeItem: const Icon(
              Icons.home_filled,
              color: Colors.lightGreenAccent,
            ),
            itemLabelWidget: Padding(
              padding:EdgeInsets.only(left: mq.width *.02),
              child: const Text('Home',style: TextStyle(color: Colors.white),),
            )
          ),
          const BottomBarItem(
            inActiveItem: Icon(
              Icons.chat_bubble_outline,
              color: Colors.lightGreen,
            ),
            activeItem: Icon(
              Icons.chat_bubble_outline,
              color: Colors.lightGreenAccent,
            ),
              itemLabelWidget: Text('Signs',style: TextStyle(color: Colors.white),)
          ),
        ],
        kIconSize: 17,
        kBottomRadius: 24,
        color: Colors.black45,
        notchColor: Colors.black,
      ),
    );
  }
}
