library circlestream.features.circle.screens.circle_detail_screen;

import 'package:flutter/material.dart';

class CircleDetailScreen extends StatelessWidget {
  final String circleId;

  const CircleDetailScreen({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Circle Detail Screen for circle $circleId')),
    );
  }
}
