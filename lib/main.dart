import 'package:flutter/material.dart';
import 'screens/api_test_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Add 'const' and key parameter

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter API Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ApiTestScreen(), // Mark this as const as well
    );
  }
}
