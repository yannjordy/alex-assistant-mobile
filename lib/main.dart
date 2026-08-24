import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.red,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'ERROR:\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  };
  runZonedGuarded(() {
    runApp(const AlexApp());
  }, (error, stack) {
    debugPrint('UNCAUGHT: $error');
  });
}
