library circlestream.shared.widgets.avatar_widget;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String username;
  final double size;

  const AvatarWidget({
    super.key,
    required this.username,
    this.size = 40.0,
  });

  String get _initials {
    if (username.isEmpty) return '?';
    
    final parts = username.trim().split(RegExp(r'[\s_\-]'));
    
    if (parts.length > 1) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    
    return username[0].toUpperCase();
  }

  Color get _backgroundColor {
    if (username.isEmpty) return AppColors.textHint;

    final List<Color> colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF5A9E87),
      const Color(0xFF8E7AB5),
      const Color(0xFFD37D92),
      const Color(0xFFE6A15C),
      AppColors.primaryDark,
      const Color(0xFF6B828F),
    ];

    int hash = 0;
    for (int i = 0; i < username.length; i++) {
      hash = username.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final index = hash.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.poppins(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
