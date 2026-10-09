import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../agent/siri_agent_service.dart';

class SiriOrbWidget extends StatefulWidget {
  final SiriState state;
  final double size;

  const SiriOrbWidget({
    super.key,
    required this.state,
    this.size = 140,
  });

  @override
  State<SiriOrbWidget> createState() => _SiriOrbWidgetState();
}

class _SiriOrbWidgetState extends State<SiriOrbWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
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
      builder: (context, child) {
        final progress = _controller.value;
        double scale = 1.0;
        double glowRadius = 20.0;

        switch (widget.state) {
          case SiriState.idle:
            scale = 1.0 + 0.05 * math.sin(progress * 2 * math.pi);
            glowRadius = 15;
            break;
          case SiriState.listening:
            scale = 1.08 + 0.12 * math.sin(progress * 4 * math.pi);
            glowRadius = 35;
            break;
          case SiriState.thinking:
            scale = 1.0 + 0.08 * math.sin(progress * 6 * math.pi);
            glowRadius = 25;
            break;
          case SiriState.speaking:
            scale = 1.12 + 0.15 * math.sin(progress * 8 * math.pi);
            glowRadius = 40;
            break;
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                  blurRadius: glowRadius,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFF007F).withValues(alpha: 0.4),
                  blurRadius: glowRadius * 1.2,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF7000FF).withValues(alpha: 0.35),
                  blurRadius: glowRadius * 1.5,
                  spreadRadius: 6,
                ),
              ],
              gradient: SweepGradient(
                startAngle: 0.0,
                endAngle: math.pi * 2,
                transform: GradientRotation(progress * 2 * math.pi),
                colors: const [
                  Color(0xFF00E5FF), // Cyan
                  Color(0xFF7000FF), // Purple
                  Color(0xFFFF007F), // Magenta
                  Color(0xFF0070F3), // Electric Blue
                  Color(0xFF00E5FF),
                ],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
