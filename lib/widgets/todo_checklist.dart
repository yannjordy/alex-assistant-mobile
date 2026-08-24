import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass.dart';

class TodoItem {
  final String label;
  final String status; // pending | active | done | failed
  const TodoItem({required this.label, required this.status});
}

class ParsedTodos {
  final List<TodoItem> items;
  final String textWithoutBlock;
  const ParsedTodos({required this.items, required this.textWithoutBlock});
}

/// Extrait un bloc `[TODO]...[/TODO]` du texte d'un message et déduit le
/// statut de chaque ligne à partir des marqueurs ✅ / ⏳ / ❌ trouvés
/// ailleurs dans le même message — même convention que la PWA d'origine.
/// Retourne `null` si le message ne contient pas de bloc todo.
ParsedTodos? extractTodos(String content) {
  final blockMatch = RegExp(r'\[TODO\]([\s\S]*?)\[/TODO\]', caseSensitive: false).firstMatch(content);
  if (blockMatch == null) return null;

  final lines = (blockMatch.group(1) ?? '')
      .split('\n')
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-*•]\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return null;

  final withoutBlock = content.replaceRange(blockMatch.start, blockMatch.end, '').trim();

  final done = RegExp('✅\\s*(.+)').allMatches(withoutBlock).map((m) => m.group(1)!.trim()).toList();
  final wip = RegExp('⏳\\s*(.+)').allMatches(withoutBlock).map((m) => m.group(1)!.trim()).toList();
  final failed = RegExp('❌\\s*(.+)').allMatches(withoutBlock).map((m) => m.group(1)!.trim()).toList();

  final items = lines.map((line) {
    String status = 'pending';
    if (done.any((d) => d.contains(line) || line.contains(d))) {
      status = 'done';
    } else if (wip.any((d) => d.contains(line) || line.contains(d))) {
      status = 'active';
    } else if (failed.any((d) => d.contains(line) || line.contains(d))) {
      status = 'failed';
    }
    return TodoItem(label: line, status: status);
  }).toList();

  return ParsedTodos(items: items, textWithoutBlock: withoutBlock);
}

class TodoChecklist extends StatelessWidget {
  const TodoChecklist({super.key, required this.items});

  final List<TodoItem> items;

  @override
  Widget build(BuildContext context) {
    final doneCount = items.where((i) => i.status == 'done').length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        borderRadius: 16,
        tintOpacity: 0.05,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rounded, color: AppColors.amberSoft, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Tâches',
                  style: TextStyle(color: AppColors.amberSoft, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text('$doneCount/${items.length}', style: const TextStyle(color: AppColors.creamFaint, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => _TodoRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.item});

  final TodoItem item;

  @override
  Widget build(BuildContext context) {
    Widget icon = const Icon(Icons.circle_outlined, size: 13, color: AppColors.creamFaint);
    Color textColor = AppColors.creamDim;
    bool strike = false;

    switch (item.status) {
      case 'done':
        icon = const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success);
        textColor = AppColors.creamFaint;
        strike = true;
        break;
      case 'active':
        icon = const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
        );
        textColor = AppColors.cream;
        break;
      case 'failed':
        icon = const Icon(Icons.cancel_rounded, size: 15, color: AppColors.error);
        textColor = AppColors.error;
        break;
      default:
        icon = const Icon(Icons.circle_outlined, size: 13, color: AppColors.creamFaint);
        textColor = AppColors.creamDim;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 18, child: Padding(padding: const EdgeInsets.only(top: 2), child: icon)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                decoration: strike ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
