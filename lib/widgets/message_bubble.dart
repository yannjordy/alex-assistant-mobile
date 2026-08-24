import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/chat_message.dart';
import '../theme/app_colors.dart';
import '../theme/glass.dart';
import 'media_viewer.dart';
import 'task_progress_card.dart';
import 'thinking_chip.dart';
import 'todo_checklist.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    final parsedTodos = !_isUser ? extractTodos(message.content) : null;
    final displayContent = parsedTodos?.textWithoutBlock ?? message.content;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!_isUser && message.thinking != null && message.thinking!.trim().isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
              child: ThinkingChip(text: message.thinking!, isLive: message.isStreaming),
            ),
          if (!_isUser && message.taskProgress != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
              child: TaskProgressCard(progress: message.taskProgress!),
            ),
          if (parsedTodos != null && parsedTodos.items.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
              child: TodoChecklist(items: parsedTodos.items),
            ),
          if (displayContent.trim().isNotEmpty || (message.isStreaming && message.thinking == null))
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
              child: _Bubble(isUser: _isUser, isError: message.isError, child: _buildContent(context, displayContent)),
            ),
          if (message.imageUrls.isNotEmpty) _ImageStrip(urls: message.imageUrls),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, String content) {
    if (content.trim().isEmpty) {
      return const _TypingDots();
    }
    if (_isUser) {
      return Text(
        content,
        style: const TextStyle(color: AppColors.cream, fontSize: 15, height: 1.35),
      );
    }
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: AppColors.cream, fontSize: 15, height: 1.45),
        strong: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w700),
        em: const TextStyle(color: AppColors.creamDim, fontStyle: FontStyle.italic),
        code: TextStyle(
          color: AppColors.amberSoft,
          backgroundColor: Colors.white.withOpacity(0.06),
          fontSize: 13.5,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder),
        ),
        blockquoteDecoration: BoxDecoration(
          border: const Border(left: BorderSide(color: AppColors.amber, width: 3)),
          color: Colors.white.withOpacity(0.03),
        ),
        h1: const TextStyle(color: AppColors.amberSoft, fontSize: 20, fontWeight: FontWeight.w700),
        h2: const TextStyle(color: AppColors.amberSoft, fontSize: 18, fontWeight: FontWeight.w700),
        h3: const TextStyle(color: AppColors.amberSoft, fontSize: 16, fontWeight: FontWeight.w700),
        listBullet: const TextStyle(color: AppColors.amber, fontSize: 15),
        a: const TextStyle(color: AppColors.amber, decoration: TextDecoration.underline),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.isUser, required this.isError, required this.child});

  final bool isUser;
  final bool isError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 20,
      tintOpacity: isUser ? 0.09 : 0.05,
      tint: isUser ? AppColors.amber : AppColors.cream,
      borderColor: isError ? AppColors.error.withOpacity(0.4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isError
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Flexible(child: child),
              ],
            )
          : child,
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: urls
            .map(
              (url) => GestureDetector(
                onTap: () => showMediaViewer(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.glassBorder)),
                    child: alexImage(url, width: 150, height: 150, fit: BoxFit.cover),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final v = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
              final scale = 0.5 + 0.5 * (1 - (2 * v - 1).abs());
              return Opacity(
                opacity: 0.4 + 0.6 * scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppColors.amberSoft, shape: BoxShape.circle),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
