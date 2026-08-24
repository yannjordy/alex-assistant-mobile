import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../state/chat_provider.dart';

/// Orbe lumineuse animée — design pro 2026.
///
/// Port Flutter de l'orbe desktop Three.js (orb-desktop.html) :
/// - 3400 particules (34 streams × 100 points) sur sphère Fibonacci
///   avec windings=2.4
/// - 7 états avec energy/rotSpeed calqués sur le desktop
/// - Couleurs RGB depth-based identiques au desktop
/// - Pulse, twinkle et rotation fidèles à l'original
/// - 48 formes SVG reçues via WebSocket (shape_change)
class AlexOrb extends StatefulWidget {
  const AlexOrb({super.key, required this.state, this.shape});

  final AlexState state;
  final String? shape;

  @override
  State<AlexOrb> createState() => _AlexOrbState();
}

class _AlexOrbState extends State<AlexOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final _OrbPainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = _OrbPainter(state: widget.state, shape: widget.shape);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onTick)
      ..repeat();
  }

  @override
  void didUpdateWidget(AlexOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _painter.state = widget.state;
    _painter.shape = widget.shape;
  }

  void _onTick() {
    _painter.elapsed += 0.016;
    _painter.update();
  }

  @override
  void dispose() {
    _controller.dispose();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 600),
        child: CustomPaint(
          painter: _painter,
          size: const Size(340, 340),
          isComplex: true,
          willChange: true,
        ),
      ),
    );
  }
}

/// Paramètres d'énergie et de vitesse de rotation par état,
/// calqués sur le desktop (STATE_CONFIG dans orb-desktop.html).
class _StateConfig {
  final double energy;
  final double rotSpeed;

  const _StateConfig(this.energy, this.rotSpeed);

  static const map = {
    AlexState.idle: _StateConfig(0.12, 0.0035),
    AlexState.listening: _StateConfig(0.14, 0.007),
    AlexState.thinking: _StateConfig(0.4, 0.015),
    AlexState.speaking: _StateConfig(0.5, 0.0055),
    AlexState.searching: _StateConfig(0.45, 0.012),
    AlexState.systemSearch: _StateConfig(0.35, 0.009),
    AlexState.systemLaunch: _StateConfig(0.55, 0.018),
  };
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.state, this.shape});

  AlexState state;
  String? shape;
  double elapsed = 0;
  math.Random _rand = math.Random(42);

  late List<_Particle> _particles = [];
  bool _initialized = false;

  // État animé (lerp depuis le desktop)
  double _energy = 0.16;
  double _targetEnergy = 0.16;
  double _rotSpeed = 0.0042;
  double _targetRotSpeed = 0.0042;
  double _rotY = 0;
  double _rotX = 0.16;

  // 34 streams × 30 points = 1020 particules (compromis mobile/desktop)
  static const _streams = 34;
  static const _pointsPerStream = 30;
  static const _totalParticles = _streams * _pointsPerStream;
  static const _windings = 2.4;
  static const _radius = 55.0;

  void dispose() {
    _particles.clear();
  }

  void _initialize(Size size) {
    final scale = size.width / 120;

    _particles = List.generate(_totalParticles, (i) {
      final s = i ~/ _pointsPerStream;
      final pi = i % _pointsPerStream;

      final streamOffset = (s / _streams) * math.pi * 2;
      final tilt = (s % 2 == 0 ? 1 : -1) * 0.15;
      final isAmber = s % 3 == 0;

      final t = pi / (_pointsPerStream - 1);
      final phi = -math.pi / 2 + t * math.pi;
      final theta = streamOffset + t * _windings * math.pi * 2;

      final x = math.cos(phi) * math.cos(theta);
      final y = math.sin(phi) + math.sin(theta * 0.5) * tilt * 0.15;
      final z = math.cos(phi) * math.sin(theta);
      final len = math.sqrt(x * x + y * y + z * z);

      return _Particle(
        tx: (x / len) * _radius * scale,
        ty: (y / len) * _radius * scale,
        tz: (z / len) * _radius * scale,
        delay: _rand.nextDouble() * 0.18,
        dur: 0.35 + _rand.nextDouble() * 0.2,
        phase: _rand.nextDouble() * math.pi * 2,
        speed: 0.7 + _rand.nextDouble() * 0.7,
        isAmber: isAmber ? _rand.nextDouble() < 0.8 : _rand.nextDouble() < 0.3,
        size: (1.6 + _rand.nextDouble() * 1.5) * scale * 0.6,
        shapeSlot: _rand.nextDouble(),
      );
    });

    _initialized = true;
  }

  void update() {
    final config = _StateConfig.map[state] ?? _StateConfig(0.12, 0.0035);
    _targetEnergy = config.energy;
    _targetRotSpeed = config.rotSpeed;

    _energy += (_targetEnergy - _energy) * 0.07;
    _rotSpeed += (_targetRotSpeed - _rotSpeed) * 0.04;

    _rotY += _rotSpeed + _energy * 0.0012;
    _rotX = 0.16 + math.sin(elapsed * 0.8) * 0.04;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!_initialized) _initialize(size);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 120;

    // Fond lumineux
    final bgRadius = size.width * 0.48;
    final bgGradient = ui.Gradient.radial(
      Offset(cx, cy),
      bgRadius,
      [
        _bgColor().withOpacity(0.3 + _energy * 0.4),
        Colors.transparent,
      ],
      [0.0, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy), bgRadius, Paint()..shader = bgGradient);

    // Rotation (identique au desktop)
    final cY = math.cos(_rotY);
    final sY = math.sin(_rotY);
    final cX = math.cos(_rotX);
    final sX = math.sin(_rotX);

    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    for (final p in _particles) {
      // Pulse : (1 + sin(time*0.02*speed+phase) * (0.03+energy*0.26))
      final pulse = 1 + math.sin(elapsed * 20 * p.speed + p.phase) * (0.03 + _energy * 0.26);

      var x = p.tx * pulse;
      var y = p.ty * pulse;
      var z = p.tz * pulse;

      // Rotation Y puis X (identique au desktop)
      final x1 = x * cY - z * sY;
      final z1 = x * sY + z * cY;
      final y1 = y * cX - z1 * sX;
      final z2 = y * sX + z1 * cX;

      final px = cx + x1;
      final py = cy + y1;
      final depth = (z2 / (_radius * scale) + 1) / 2;

      // Twinkle : 0.5 + 0.5 * sin(time*0.045*speed+phase)
      final twinkle = 0.5 + 0.5 * math.sin(elapsed * 45 * p.speed + p.phase);
      var alpha = (0.45 + depth * 0.5) * (0.55 + twinkle * 0.45);

      double r, g, b;
      var sizeMult = 1.0;

      switch (state) {
        case AlexState.speaking:
          r = 0.95 + depth * 0.05;
          g = 0.60 + depth * 0.15;
          b = 0.15 + depth * 0.10;
          sizeMult = 1.0 + _energy * 0.5;
          alpha *= 1.0 + _energy * 0.3;
          break;
        case AlexState.listening:
          r = 0.15 + depth * 0.15;
          g = 0.50 + depth * 0.20;
          b = 0.90 + depth * 0.10;
          sizeMult = 1.0 + _energy * 0.2;
          break;
        case AlexState.thinking:
          r = 0.50 + depth * 0.20;
          g = 0.15 + depth * 0.15;
          b = 0.80 + depth * 0.20;
          sizeMult = 1.0 + _energy * 0.3;
          break;
        case AlexState.searching:
          if (p.shapeSlot < 0.3) {
            final w = 0.6 + depth * 0.4;
            r = w; g = w; b = w;
            sizeMult = 0.55;
            alpha *= 0.7 + twinkle * 0.3;
          } else {
            r = 0.85 + depth * 0.15;
            g = 0.08 + depth * 0.12;
            b = 0.12 + depth * 0.18;
          }
          break;
        case AlexState.systemSearch:
          if (p.shapeSlot < 0.3) {
            final w = 0.7 + depth * 0.3;
            r = w; g = w; b = w;
            sizeMult = 0.5;
            alpha *= 0.65 + twinkle * 0.35;
          } else {
            r = 0.55 + depth * 0.2;
            g = 0.80 + depth * 0.15;
            b = 0.25 + depth * 0.15;
          }
          break;
        case AlexState.systemLaunch:
          if (p.shapeSlot < 0.3) {
            final w = 0.9 + depth * 0.1;
            r = w; g = w; b = w;
            sizeMult = 0.6;
            alpha *= 0.8 + twinkle * 0.2;
          } else {
            r = 0.90 + depth * 0.10;
            g = 0.60 + depth * 0.20;
            b = 0.10 + depth * 0.15;
          }
          break;
        case AlexState.idle:
        default:
          if (p.isAmber) {
            r = 0.82 + depth * 0.18;
            g = 0.47 + depth * 0.22;
            b = 0.24 + depth * 0.16;
          } else {
            r = 0.88 + depth * 0.18;
            g = 0.80 + depth * 0.22;
            b = 0.62 + depth * 0.16;
          }
          break;
      }

      final finalAlpha = alpha.clamp(0.0, 1.0);
      final finalSize = p.size * (0.85 + depth * 0.35) * (1 + _energy * 0.3) * sizeMult;

      paint.color = Color.fromRGBO(
        (r * 255).round().clamp(0, 255),
        (g * 255).round().clamp(0, 255),
        (b * 255).round().clamp(0, 255),
        finalAlpha,
      );

      canvas.drawCircle(Offset(px, py), finalSize, paint);
    }

    // Forme SVG au centre si shape n'est pas null
    if (shape != null) {
      _drawShape(canvas, Offset(cx, cy), size.width * 0.15);
    }
  }

  Color _bgColor() {
    switch (state) {
      case AlexState.thinking: return const Color(0xFF080D2A);
      case AlexState.speaking: return const Color(0xFF082A10);
      case AlexState.listening: return const Color(0xFF2A0808);
      case AlexState.searching: return const Color(0xFF2A1F08);
      case AlexState.systemSearch: return const Color(0xFF1A082A);
      case AlexState.systemLaunch: return const Color(0xFF082A2A);
      case AlexState.idle:
      default: return const Color(0xFF2A1608);
    }
  }

  void _drawShape(Canvas canvas, Offset center, double size) {
    final iconData = _shapeIcon(shape);
    if (iconData == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          fontSize: size,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(size * 0.35, size * 0.35));
  }

  /// Mappe les 48 formes du desktop vers des icônes Material.
  IconData? _shapeIcon(String? shapeName) {
    switch (shapeName) {
      case 'question': return Icons.question_mark_rounded;
      case 'exclamation': return Icons.priority_high_rounded;
      case 'error': return Icons.error_outline_rounded;
      case 'headphones': return Icons.headphones_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'search': return Icons.search_rounded;
      case 'google': return Icons.g_mobiledata_rounded;
      case 'github': return Icons.code_rounded;
      case 'star': return Icons.star_rounded;
      case 'heart': return Icons.favorite_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'camera': return Icons.camera_alt_rounded;
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'clock': return Icons.access_time_rounded;
      case 'chat': return Icons.chat_rounded;
      case 'gear': return Icons.settings_rounded;
      case 'globe': return Icons.language_rounded;
      case 'terminal': return Icons.terminal_rounded;
      case 'boat': return Icons.sailing_rounded;
      case 'mountain': return Icons.terrain_rounded;
      case 'happy': return Icons.sentiment_very_satisfied_rounded;
      case 'sad': return Icons.sentiment_very_dissatisfied_rounded;
      case 'love': return Icons.favorite_rounded;
      case 'thinking_face': return Icons.psychology_rounded;
      case 'angry': return Icons.sentiment_very_dissatisfied_rounded;
      case 'wow': return Icons.sentiment_very_satisfied_rounded;
      case 'lightning': return Icons.bolt_rounded;
      case 'shield': return Icons.shield_rounded;
      case 'rocket': return Icons.rocket_launch_rounded;
      case 'brain': return Icons.psychology_rounded;
      case 'wand': return Icons.auto_awesome_rounded;
      case 'eye': return Icons.visibility_rounded;
      case 'fire': return Icons.local_fire_department_rounded;
      case 'sparkles': return Icons.auto_awesome_rounded;
      case 'refresh': return Icons.refresh_rounded;
      case 'download': return Icons.download_rounded;
      case 'upload': return Icons.upload_rounded;
      case 'code': return Icons.code_rounded;
      case 'chart': return Icons.bar_chart_rounded;
      case 'compass': return Icons.explore_rounded;
      case 'lock': return Icons.lock_rounded;
      case 'wifi': return Icons.wifi_rounded;
      case 'cloud': return Icons.cloud_rounded;
      case 'bell': return Icons.notifications_rounded;
      case 'map': return Icons.map_rounded;
      case 'folder': return Icons.folder_rounded;
      case 'bug': return Icons.bug_report_rounded;
      case 'key': return Icons.key_rounded;
      default: return null;
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => true;
}

class _Particle {
  final double tx, ty, tz;
  final double delay, dur;
  final double phase, speed;
  final bool isAmber;
  final double size;
  final double shapeSlot;

  const _Particle({
    required this.tx,
    required this.ty,
    required this.tz,
    required this.delay,
    required this.dur,
    required this.phase,
    required this.speed,
    required this.isAmber,
    required this.size,
    required this.shapeSlot,
  });
}
