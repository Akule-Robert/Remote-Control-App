import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_provider.dart';
import '../theme/app_theme.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});
  @override State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  String _text = '';
  bool _shifted = false;
  bool _sending = false;

  void _type(String c) => setState(() {
    _text += _shifted ? c.toUpperCase() : c;
    if (_shifted) _shifted = false;
  });

  void _backspace() => setState(() { if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1); });

  Future<void> _send() async {
    if (_text.trim().isEmpty) { _toast('Nothing to send'); return; }
    setState(() => _sending = true);
    context.read<RemoteProvider>().sendText(_text);
    if (!mounted) return;
    _toast('Sent: "${_text.length > 20 ? '${_text.substring(0, 20)}…' : _text}"');
    setState(() { _text = ''; _sending = false; });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating, shape: const StadiumBorder(),
      backgroundColor: const Color(0xF01E1E2C),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TV INPUT FIELD', style: TextStyle(fontSize: 11, color: AppColors.text3, letterSpacing: 1.0, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.bg3, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: _text, style: const TextStyle(fontSize: 16, color: AppColors.text)),
              const WidgetSpan(child: _Cursor()),
            ])),
          ),
          const SizedBox(height: 12),
          _buildKeyboard(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send to TV ↵', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    const rows = [
      ['q','w','e','r','t','y','u','i','o','p'],
      ['a','s','d','f','g','h','j','k','l'],
      ['z','x','c','v','b','n','m'],
    ];
    return Column(children: [
      ...rows.asMap().entries.map((e) => _KeyRow(
        keys: e.value.map((k) => _Key(label: _shifted ? k.toUpperCase() : k, onTap: () => _type(k))).toList(),
        prefix: e.key == 2 ? _Key(label: '⇧', wide: true, active: _shifted, onTap: () => setState(() => _shifted = !_shifted)) : null,
        suffix: e.key == 2 ? _Key(label: '⌫', wide: true, onTap: _backspace) : null,
      )),
      _KeyRow(keys: [
        _Key(label: '123', wide: true, onTap: () => _toast('Number pad coming soon')),
        _Key(label: 'space', space: true, onTap: () => _type(' ')),
        _Key(label: '😊', wide: true, emoji: true, onTap: () => _type('😊')),
        _Key(label: 'Send', send: true, onTap: _send),
      ]),
    ]);
  }
}

class _KeyRow extends StatelessWidget {
  final List<_Key> keys;
  final _Key? prefix, suffix;
  const _KeyRow({required this.keys, this.prefix, this.suffix});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefix != null) ...[prefix!, const SizedBox(width: 5)],
        ...keys.expand((k) => [k, const SizedBox(width: 5)]).toList()..removeLast(),
        if (suffix != null) ...[const SizedBox(width: 5), suffix!],
      ],
    ),
  );
}

class _Key extends StatelessWidget {
  final String label;
  final bool wide, space, send, emoji, active;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap, this.wide = false, this.space = false, this.send = false, this.emoji = false, this.active = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      width: space ? 180 : wide ? 56 : send ? 72 : null,
      constraints: space || wide || send ? null : const BoxConstraints(minWidth: 30, maxWidth: 38),
      decoration: BoxDecoration(
        color: send ? AppColors.accent : active ? AppColors.accentDim : AppColors.bg3,
        border: Border.all(color: active ? AppColors.accent : send ? AppColors.accent : AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
        fontSize: emoji ? 20 : send || wide ? 12 : 16,
        fontWeight: send ? FontWeight.w600 : FontWeight.w500,
        color: send ? Colors.white : active ? AppColors.accent : AppColors.text,
      )),
    ),
  );
}

class _Cursor extends StatefulWidget {
  const _Cursor();
  @override State<_Cursor> createState() => _CursorState();
}
class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(
    opacity: _c,
    child: const Text('|', style: TextStyle(fontSize: 16, color: AppColors.accent)),
  );
}
