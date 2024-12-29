import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String? _latestPrediction;
  bool _isFetching = false;

  // Function to fetch the latest prediction
  Future<void> fetchLatestPrediction() async {
    final url = Uri.parse('http://10.0.2.2:8000/latest_prediction'); // For Android emulator, use 10.0.2.2
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _latestPrediction = data['prediction']?.toString() ?? "No prediction available";
        });
      } else {
        setState(() {
          _latestPrediction = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _latestPrediction = 'Failed to fetch data: $e';
      });
    }
  }


  // Polling function to repeatedly fetch data
  void startFetching() {
    if (_isFetching) return; // Prevent multiple polling loops
    _isFetching = true;

    // Periodic timer for polling
    Future.doWhile(() async {
      if (!_isFetching) return false; // Stop polling if _isFetching is false
      await fetchLatestPrediction();
      await Future.delayed(const Duration(seconds: 1)); // Poll every second
      return true; // Continue polling
    });
  }

  @override
  void dispose() {
    _isFetching = false; // Stop polling when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Viewer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_latestPrediction != null)
              Text(
                'Latest Prediction: $_latestPrediction',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              )
            else
              const Text(
                'Press the button to start fetching predictions',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startFetching,
              child: const Text('Start Fetching Predictions'),
            ),
          ],
        ),
      ),
    );
  }
}
