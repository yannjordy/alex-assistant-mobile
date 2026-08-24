import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/speech_service.dart';
import '../state/chat_provider.dart';
import '../theme/app_colors.dart';
import '../theme/glass.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  final bool isStreaming;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SpeechService _speech = SpeechService();

  bool _hasText = false;
  bool _listening = false;
  String _preListenText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stopListening();
      setState(() => _listening = false);
      return;
    }

    _preListenText = _controller.text;
    final started = await _speech.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        final combined = _preListenText.isEmpty ? text : '$_preListenText $text';
        _controller.text = combined;
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        if (isFinal) setState(() => _listening = false);
      },
    );

    if (!mounted) return;
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Micro indisponible ou permission refusée.')),
      );
      return;
    }
    setState(() => _listening = true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.of(context).padding.bottom + 12),
      child: FloatingGlassPanel(
        borderRadius: 28,
        tintOpacity: _listening ? 0.10 : 0.07,
        borderColor: _listening ? AppColors.glassBorderStrong : null,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RoundIconButton(
              icon: _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _listening ? AppColors.amber : AppColors.creamDim,
              onTap: _toggleMic,
              pulsing: _listening,
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(color: AppColors.cream, fontSize: 15),
                  cursorColor: AppColors.amber,
                  decoration: InputDecoration(
                    hintText: _listening ? 'Je t\'écoute…' : 'Écris à Alex…',
                    hintStyle: const TextStyle(color: AppColors.creamFaint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            if (widget.isStreaming)
              _RoundIconButton(
                icon: Icons.stop_rounded,
                color: AppColors.cream,
                background: AppColors.error.withOpacity(0.85),
                onTap: widget.onStop,
              )
            else
              _RoundIconButton(
                icon: Icons.arrow_upward_rounded,
                color: AppColors.black,
                background: _hasText ? AppColors.amber : AppColors.creamGhost,
                onTap: _hasText ? _send : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    this.background,
    this.onTap,
    this.pulsing = false,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final VoidCallback? onTap;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background ?? Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: pulsing
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.amber.withOpacity(0.5), blurRadius: 12, spreadRadius: 1)],
                  )
                : null,
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}
