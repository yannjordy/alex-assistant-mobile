import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tools_models.dart';
import '../state/code_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CodeProvider>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<CodeProvider>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Code d\'Alex', style: AppTheme.wordmark(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.creamDim), onPressed: code.refresh),
        ],
      ),
      body: code.isLoading && code.events.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2))
          : code.events.isEmpty
              ? const Center(
                  child: Text('Alex n\'a encore rien écrit.', style: TextStyle(color: AppColors.creamFaint)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: code.events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final event = code.events[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CodeDetailScreen(event: event)),
                      ),
                      child: GlassPanel(
                        borderRadius: 14,
                        tintOpacity: 0.05,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              event.ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                              color: event.ok ? AppColors.success : AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.path,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  if (event.lang.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        event.lang,
                                        style: const TextStyle(color: AppColors.creamFaint, fontSize: 11.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.creamFaint),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class CodeDetailScreen extends StatefulWidget {
  const CodeDetailScreen({super.key, required this.event});

  final CodeLogEvent event;

  @override
  State<CodeDetailScreen> createState() => _CodeDetailScreenState();
}

class _CodeDetailScreenState extends State<CodeDetailScreen> {
  bool _sideBySide = true;
  bool _running = false;
  String? _output;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _output = null;
    });
    final result = await context.read<CodeProvider>().runCode(widget.event);
    if (!mounted) return;
    setState(() {
      _running = false;
      _output = result.output.isEmpty ? '(pas de sortie)' : result.output;
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(event.path, style: const TextStyle(color: AppColors.cream, fontSize: 15), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_sideBySide ? Icons.difference_outlined : Icons.vertical_split_rounded, color: AppColors.creamDim),
            tooltip: _sideBySide ? 'Voir le diff' : 'Voir côte à côte',
            onPressed: () => setState(() => _sideBySide = !_sideBySide),
          ),
          if (event.isRunnable)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: AppColors.amberSoft),
              tooltip: 'Exécuter',
              onPressed: _running ? null : _run,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _sideBySide
                ? Row(
                    children: [
                      Expanded(child: _CodePane(title: 'Avant', content: event.old ?? '(nouveau fichier)')),
                      Container(width: 1, color: AppColors.glassBorder),
                      Expanded(child: _CodePane(title: 'Après', content: event.new_ ?? '')),
                    ],
                  )
                : _DiffPane(diff: event.diff.isEmpty ? '(pas de diff disponible)' : event.diff),
          ),
          if (_running)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(height: 2, child: LinearProgressIndicator(color: AppColors.amber)),
            ),
          if (_output != null)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0704),
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output!,
                  style: const TextStyle(color: AppColors.creamDim, fontSize: 12.5, fontFamily: 'monospace', height: 1.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CodePane extends StatelessWidget {
  const _CodePane({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(color: AppColors.creamFaint, fontSize: 11, letterSpacing: 1.2),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
            child: SelectableText(
              content,
              style: const TextStyle(color: AppColors.cream, fontSize: 12, fontFamily: 'monospace', height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiffPane extends StatelessWidget {
  const _DiffPane({required this.diff});

  final String diff;

  @override
  Widget build(BuildContext context) {
    final lines = diff.split('\n');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: SelectableText.rich(
        TextSpan(
          children: lines.map((line) {
            Color color = AppColors.creamDim;
            if (line.startsWith('+') && !line.startsWith('+++')) color = AppColors.success;
            if (line.startsWith('-') && !line.startsWith('---')) color = AppColors.error;
            if (line.startsWith('@@')) color = AppColors.amberSoft;
            return TextSpan(
              text: '$line\n',
              style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace', height: 1.5),
            );
          }).toList(),
        ),
      ),
    );
  }
}
