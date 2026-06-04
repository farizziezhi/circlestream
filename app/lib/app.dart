library circlestream.app;

import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'design/app_theme.dart';

class CircleStreamApp extends StatelessWidget {
  const CircleStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CircleStream',
      theme: AppTheme.light(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
