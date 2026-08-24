import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../state/chat_provider.dart';

class AlexOrb extends StatefulWidget {
  const AlexOrb({super.key, required this.state, this.shape});
  final AlexState state;
  final String? shape;
  @override
  State<AlexOrb> createState() => _AlexOrbState();
}

class _AlexOrbState extends State<AlexOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * 2 * math.pi;
        final colors = _colorsFor(widget.state);
        final breathe = 0.5 + 0.5 * math.sin(t * 0.8);
        final baseSize = widget.state == AlexState.idle ? 200.0 : 260.0;
        final size = baseSize + breathe * 30;
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors[0].withOpacity(0.6),
                  colors[1].withOpacity(0.3),
                  colors[2].withOpacity(0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.3 + breathe * 0.2),
                  blurRadius: 60 + breathe * 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _colorsFor(AlexState s) {
    switch (s) {
      case AlexState.thinking: return [const Color(0xFF6B8AFF), const Color(0xFF080D2A), Colors.transparent];
      case AlexState.speaking: return [const Color(0xFF22C55E), const Color(0xFF082A10), Colors.transparent];
      case AlexState.listening: return [const Color(0xFFFF6B6B), const Color(0xFF2A0808), Colors.transparent];
      case AlexState.searching: return [const Color(0xFFFFC107), const Color(0xFF2A1F08), Colors.transparent];
      case AlexState.systemSearch: return [const Color(0xFF9C27B0), const Color(0xFF1A082A), Colors.transparent];
      case AlexState.systemLaunch: return [const Color(0xFF00BCD4), const Color(0xFF082A2A), Colors.transparent];
      case AlexState.idle: default: return [const Color(0xFFFF9D3D), const Color(0xFF2A1608), Colors.transparent];
    }
  }
}
