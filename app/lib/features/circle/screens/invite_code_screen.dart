library circlestream.features.circle.screens.invite_code_screen;

import 'package:flutter/material.dart';

class InviteCodeScreen extends StatelessWidget {
  final String circleId;

  const InviteCodeScreen({super.key, required this.circleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Invite Code Screen for circle $circleId')),
    );
  }
}
