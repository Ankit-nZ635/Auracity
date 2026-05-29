import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmojiRain extends StatefulWidget {
  const EmojiRain({super.key});

  @override
  State<EmojiRain> createState() => EmojiRainState();
}

class EmojiRainState extends State<EmojiRain> {
  String? _currentEmoji;
  int _rainCounter = 0;

  void startRain(String emoji) {
    setState(() {
      _currentEmoji = emoji;
      _rainCounter++;
    });
    
    // Stop after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentEmoji = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEmoji == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: List.generate(25, (index) {
          final random = Random(_rainCounter + index);
          final double left = random.nextDouble() * MediaQuery.of(context).size.width;
          final double duration = 1.5 + random.nextDouble() * 2.0;
          final double delay = random.nextDouble() * 1.5;
          final double size = 20.0 + random.nextDouble() * 30.0;
          final double rotation = random.nextDouble() * 2 * pi;

          return Positioned(
            left: left,
            bottom: -100, // Start below the screen
            child: Text(
              _currentEmoji!,
              style: TextStyle(fontSize: size),
            )
            .animate()
            .moveY(
              begin: 0,
              end: -(MediaQuery.of(context).size.height + 200),
              duration: duration.seconds,
              delay: delay.seconds,
              curve: Curves.easeOutCubic,
            )
            .fadeOut(
              begin: 1.0,
              delay: (delay + duration * 0.7).seconds, // Start fading near the top
              duration: (duration * 0.3).seconds,
            )
            .rotate(begin: 0, end: rotation, duration: duration.seconds),
          );
        }),
      ),
    );
  }
}
