import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass.dart';

/// Construit une image à partir d'une URL réseau OU d'un `data:` URI
/// (photo jointe localement, ex. via la vision caméra) — `Image.network`
/// seul ne sait pas lire les data URIs.
Widget alexImage(String source, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (source.startsWith('data:')) {
    final commaIndex = source.indexOf(',');
    if (commaIndex != -1) {
      try {
        final bytes = base64Decode(source.substring(commaIndex + 1));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _brokenImage(width, height),
        );
      } catch (_) {
        return _brokenImage(width, height);
      }
    }
    return _brokenImage(width, height);
  }
  return Image.network(
    source,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => _brokenImage(width, height),
  );
}

Widget _brokenImage(double? width, double? height) {
  return SizedBox(
    width: width,
    height: height,
    child: const Icon(Icons.broken_image_outlined, color: AppColors.creamFaint),
  );
}

/// Ouvre une visionneuse plein écran pour l'image `url`, avec zoom au
/// pincement et fond assombri — équivalent du `mediaViewer` de la PWA.
void showMediaViewer(BuildContext context, String url) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.85),
      pageBuilder: (context, animation, __) => FadeTransition(
        opacity: animation,
        child: _MediaViewerScreen(url: url),
      ),
    ),
  );
}

class _MediaViewerScreen extends StatelessWidget {
  const _MediaViewerScreen({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(child: alexImage(url, fit: BoxFit.contain)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GlassPanel(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(4),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.cream),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
