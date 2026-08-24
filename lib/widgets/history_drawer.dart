import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/activity_screen.dart';
import '../screens/code_screen.dart';
import '../screens/integrations_screen.dart';
import '../screens/map_screen.dart';
import '../screens/models_screen.dart';
import '../screens/voices_screen.dart';
import '../state/chat_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';
import '../utils/text_utils.dart';

class HistoryDrawer extends StatefulWidget {
  const HistoryDrawer({super.key});

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  late Future<List<ConversationTurn>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ChatProvider>().loadHistoryTurns();
  }

  void _reload() {
    setState(() => _future = context.read<ChatProvider>().loadHistoryTurns());
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatProvider>();

    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.84,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.92),
              border: const Border(right: BorderSide(color: AppColors.glassBorder)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
                    child: Row(
                      children: [
                        Text('CONVERSATIONS', style: AppTheme.wordmark(fontSize: 15)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.creamFaint),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _NewChatButton(
                      onTap: () {
                        chat.newChat();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  Expanded(
                    child: FutureBuilder<List<ConversationTurn>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
                          );
                        }
                        final turns = snapshot.data ?? [];
                        if (turns.isEmpty) {
                          return const Center(
                            child: Text('Aucune conversation', style: TextStyle(color: AppColors.creamFaint)),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          itemCount: turns.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final turn = turns[i];
                            return _ConversationTile(
                              turn: turn,
                              onTap: () {
                                chat.openConversationTurn(turn);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Row(
                      children: [Text('OUTILS', style: AppTheme.wordmark(fontSize: 12, color: AppColors.creamFaint))],
                    ),
                  ),
                  _ToolRow(
                    icon: Icons.terminal_rounded,
                    label: 'Terminal d\'activité',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityScreen()));
                    },
                  ),
                  _ToolRow(
                    icon: Icons.code_rounded,
                    label: 'Code d\'Alex',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CodeScreen()));
                    },
                  ),
                  _ToolRow(
                    icon: Icons.map_outlined,
                    label: 'Carte',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreen()));
                    },
                  ),
                  _ToolRow(
                    icon: Icons.extension_outlined,
                    label: 'Intégrations',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IntegrationsScreen()));
                    },
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Row(
                      children: [Text('IA & VOIX', style: AppTheme.wordmark(fontSize: 12, color: AppColors.creamFaint))],
                    ),
                  ),
                  _ToolRow(
                    icon: Icons.psychology_rounded,
                    label: 'Modèles IA (7 free)',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModelsScreen()));
                    },
                  ),
                  _ToolRow(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Voix Edge TTS (13)',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoicesScreen()));
                    },
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: TextButton.icon(
                      onPressed: () => _confirmClear(context, chat),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                      label: const Text('Effacer tout l\'historique', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, ChatProvider chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141008),
        title: const Text('Effacer l\'historique ?', style: TextStyle(color: AppColors.cream)),
        content: const Text(
          'Toutes les conversations enregistrées seront définitivement supprimées.',
          style: TextStyle(color: AppColors.creamDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.creamDim)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await chat.clearHistory();
      _reload();
    }
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        borderRadius: 14,
        tintOpacity: 0.06,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, color: AppColors.amberSoft, size: 18),
            SizedBox(width: 8),
            Text('Nouvelle conversation', style: TextStyle(color: AppColors.cream, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: AppColors.creamDim, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.cream, fontSize: 13.5)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.creamGhost, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.turn, required this.onTap});

  final ConversationTurn turn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              turn.question,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (turn.answerPreview.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                turn.answerPreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.creamFaint, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
