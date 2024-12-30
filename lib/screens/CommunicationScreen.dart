import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class CommunicationScreen extends StatefulWidget {
  final NotchBottomBarController? controller;
  const CommunicationScreen({super.key, this.controller});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  TextEditingController _searchController = TextEditingController();
  List<String> _imageNames = List.generate(26, (index) => String.fromCharCode(65 + index) + '.jpg'); // List A.jpg to Z.jpg
  List<String> _filteredImageNames = [];

  @override
  void initState() {
    super.initState();
    _filteredImageNames = _imageNames; // Initially show all images
    _searchController.addListener(_filterImages);
  }

  // Filter images based on the search query
  void _filterImages() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredImageNames = _imageNames
          .where((image) => image.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterImages); // Clean up listener
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Communication Screen',
          style: TextStyle(
              fontSize: mq.width * .06
          ),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // TextField for searching images
            SizedBox(
              width: mq.width * .8,
              height: mq.height * .07,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.white, // Set cursor color to white
                decoration: InputDecoration(
                  focusColor: Colors.white, // Ensures the focus color is white
                  labelStyle: const TextStyle(color: Colors.white),
                  labelText: 'Search',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(mq.width * .04),
                  ),
                  focusedBorder: OutlineInputBorder( // When the TextField is focused
                    borderRadius: BorderRadius.circular(mq.width * .04),
                    borderSide: BorderSide(color: Colors.white, width: 2.0), // White border when focused
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            // Grid view to display images
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  crossAxisSpacing: 24.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: _filteredImageNames.length,
                itemBuilder: (context, index) {
                  String imageName = _filteredImageNames[index];
                  return GridTile(
                    child: SizedBox(
                      width: mq.width * 0.4, // Adjust width for zoom out
                      height: mq.width * 0.8, // Adjust height to maintain aspect ratio
                      child: Image.asset(
                        'assets/images/Alphabets/$imageName', // Updated path
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
