library circlestream.features.reaction.widgets.floating_emoji_animation;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FloatingEmojiController {
  FloatingEmojiController._();
  static final FloatingEmojiController instance = FloatingEmojiController._();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  void trigger(String emoji) {
    _controller.add(emoji);
  }
}

class _EmojiParticle {
  final String emoji;
  final double x;
  final Key id;

  _EmojiParticle({
    required this.emoji,
    required this.x,
    required this.id,
  });
}

class FloatingEmojiOverlay extends StatefulWidget {
  final Widget child;
  const FloatingEmojiOverlay({super.key, required this.child});

  @override
  State<FloatingEmojiOverlay> createState() => _FloatingEmojiOverlayState();
}

class _FloatingEmojiOverlayState extends State<FloatingEmojiOverlay> {
  final List<_EmojiParticle> _particles = [];
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FloatingEmojiController.instance.stream.listen((emoji) {
      _addParticle(emoji);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _addParticle(String emoji) {
    final random = Random();
    final id = UniqueKey();

    if (mounted) {
      setState(() {
        _particles.add(_EmojiParticle(
          emoji: emoji,
          x: 0.2 + random.nextDouble() * 0.6, // 20% to 80% of screen width
          id: id,
        ));
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _particles.removeWhere((p) => p.id == id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._particles.map((p) => _FloatingEmojiWidget(key: p.id, particle: p)),
      ],
    );
  }
}

class _FloatingEmojiWidget extends StatefulWidget {
  final _EmojiParticle particle;
  const _FloatingEmojiWidget({super.key, required this.particle});

  @override
  State<_FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<_FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _positionAnim = Tween<double>(begin: 0.85, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return Positioned(
          left: screenWidth * widget.particle.x,
          top: screenHeight * _positionAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Text(
                widget.particle.emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
        );
      },
    );
  }
}
