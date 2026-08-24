import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tools_models.dart';
import '../state/activity_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ActivityProvider>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Terminal d\'activité', style: AppTheme.wordmark(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.creamDim),
            onPressed: activity.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _confirmClear(context, activity),
          ),
        ],
      ),
      body: activity.isLoading && activity.events.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2))
          : activity.events.isEmpty
              ? const Center(
                  child: Text('Aucune activité pour le moment.', style: TextStyle(color: AppColors.creamFaint)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemCount: activity.events.length,
                  itemBuilder: (context, i) => _ActivityRow(event: activity.events[i]),
                ),
    );
  }

  Future<void> _confirmClear(BuildContext context, ActivityProvider activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141008),
        title: const Text('Effacer le journal ?', style: TextStyle(color: AppColors.cream)),
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
    if (confirmed == true) await activity.clear();
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final ActivityEvent event;

  Color get _color {
    switch (event.level) {
      case 'success':
        return AppColors.success;
      case 'warn':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      case 'cmd':
        return AppColors.amberSoft;
      default:
        return AppColors.creamDim;
    }
  }

  String get _prefix {
    switch (event.level) {
      case 'cmd':
        return '▶';
      case 'success':
        return '✓';
      case 'warn':
        return '!';
      case 'error':
        return '✕';
      default:
        return '·';
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = event.dateTime;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$hh:$mm:$ss',
            style: const TextStyle(color: AppColors.creamGhost, fontSize: 11, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          Text(_prefix, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              event.message,
              style: TextStyle(color: _color, fontSize: 12.5, fontFamily: 'monospace', height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
