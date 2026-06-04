library circlestream.features.feed.screens.photo_viewer_screen;

import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String postId;

  const PhotoViewerScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Viewer')),
      body: Center(child: Text('Photo Viewer for post $postId')),
    );
  }
}
