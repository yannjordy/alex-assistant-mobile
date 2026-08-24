import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/alex_socket_service.dart';
import '../state/chat_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/alex_orb.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/history_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/quick_action_pills.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/status_pill.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<WakeEvent>? _wakeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _wakeSub = context.read<AlexSocketService>().events.listen(_onWakeEvent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _wakeSub?.cancel();
    super.dispose();
  }

  void _onWakeEvent(WakeEvent event) {
    if (event.kind != WakeEventKind.notification || !mounted) return;
    final title = event.raw['title'] as String? ?? '';
    final message = event.raw['message'] as String? ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title.isNotEmpty ? '$title — $message' : message,
          style: const TextStyle(color: AppColors.cream),
        ),
        backgroundColor: const Color(0xFF1A1208),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.black,
      drawer: const HistoryDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: const BoxDecoration(gradient: AppColors.ambientGlow)),
          ),
          Positioned.fill(child: AlexOrb(state: chat.alexState, shape: chat.currentShape)),
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.green,
                  padding: const EdgeInsets.all(4),
                  child: const Text('DEBUG: APP LOADED', style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
                Builder(
                  builder: (context) => GlassAppBar(
                    onMenuTap: () => Scaffold.of(context).openDrawer(),
                    onSettingsTap: () => showSettingsSheet(context),
                  ),
                ),
                Expanded(
                  child: chat.hasMessages
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, i) => MessageBubble(message: chat.messages[i]),
                        )
                      : _EmptyState(
                          onQuickAction: (text) => context.read<ChatProvider>().sendMessage(text),
                        ),
                ),
                if (chat.statusText != null && chat.statusText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: StatusPill(text: chat.statusText!),
                  ),
                ChatInputBar(
                  isStreaming: chat.isStreaming,
                  onSend: (text) => context.read<ChatProvider>().sendMessage(text),
                  onStop: () => context.read<ChatProvider>().stop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onQuickAction});

  final ValueChanged<String> onQuickAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ALEX', style: AppTheme.wordmark(fontSize: 32)),
            const SizedBox(height: 10),
            const Text(
              'Dis-moi ce dont tu as besoin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.creamFaint, fontSize: 14.5),
            ),
            const SizedBox(height: 26),
            QuickActionPills(onTap: onQuickAction),
          ],
        ),
      ),
    );
  }
}
