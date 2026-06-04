library circlestream.features.circle.screens.circle_members_screen;

import 'package:flutter/material.dart';

class CircleMembersScreen extends StatelessWidget {
  final String circleId;

  const CircleMembersScreen({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Circle Members Screen for circle $circleId')),
    );
  }
}
