import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/chat_screen.dart';
import 'services/alex_api_service.dart';
import 'services/alex_socket_service.dart';
import 'services/edge_tts_service.dart';
import 'services/opencode_service.dart';
import 'services/tts_queue_player.dart';
import 'services/wake_word_service.dart';
import 'state/activity_provider.dart';
import 'state/chat_provider.dart';
import 'state/code_provider.dart';
import 'state/integrations_provider.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';

class AlexApp extends StatelessWidget {
  const AlexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services de base
        Provider<AlexApiService>(
          create: (_) => AlexApiService(),
          dispose: (_, api) => api.dispose(),
        ),
        Provider<TtsQueuePlayer>(
          create: (context) => TtsQueuePlayer(context.read<AlexApiService>()),
          dispose: (_, player) => player.dispose(),
        ),
        Provider<AlexSocketService>(
          create: (context) => AlexSocketService(context.read<AlexApiService>())..connect(),
          dispose: (_, socket) => socket.dispose(),
        ),

        // Nouveaux services : OpenCode, Wake Word, Edge TTS
        Provider<OpenCodeService>(
          create: (_) => OpenCodeService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<WakeWordService>(
          create: (_) => WakeWordService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<EdgeTtsService>(
          create: (_) => EdgeTtsService(),
        ),

        // Providers d'état
        ChangeNotifierProvider<SettingsProvider>(
          create: (context) => SettingsProvider(context.read<AlexApiService>())..load(),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(
            api: context.read<AlexApiService>(),
            ttsPlayer: context.read<TtsQueuePlayer>(),
            settings: context.read<SettingsProvider>(),
            socket: context.read<AlexSocketService>(),
          ),
        ),
        ChangeNotifierProvider<ActivityProvider>(
          create: (context) => ActivityProvider(
            api: context.read<AlexApiService>(),
            socket: context.read<AlexSocketService>(),
          ),
        ),
        ChangeNotifierProvider<CodeProvider>(
          create: (context) => CodeProvider(
            api: context.read<AlexApiService>(),
            socket: context.read<AlexSocketService>(),
          ),
        ),
        ChangeNotifierProvider<IntegrationsProvider>(
          create: (context) => IntegrationsProvider(api: context.read<AlexApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Alex',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const ChatScreen(),
      ),
    );
  }
}
