import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_provider.dart';
import '../theme/app_theme.dart';

class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating, shape: const StadiumBorder(),
      backgroundColor: const Color(0xF01E1E2C),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RemoteProvider>();
    final connected = p.isConnected;
    void key(String k) { p.remote.sendKey(k); }
    void toast(String m) => _toast(context, m);

    return SingleChildScrollView(
      child: Column(children: [

        // ── Connection bar ────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            border: Border.all(color: connected ? const Color(0x4429C278) : AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
              color: connected ? AppColors.green : AppColors.text3,
              shape: BoxShape.circle,
            )),
            const SizedBox(width: 10),
            Expanded(child: Text(
              connected ? 'Connected · ${p.connectedDevice?.ip ?? ""}' : 'Not connected — go to Pair tab',
              style: const TextStyle(fontSize: 13, color: AppColors.text2),
            )),
            if (!connected)
              GestureDetector(
                onTap: () => p.setTab(0),
                child: const Text('Connect', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ),
          ]),
        ),

        // ── Power / Source / Menu ─────────────────────────────────────────
        _Sec(child: Row(children: [
          _RBtn(label: 'Power', icon: Icons.power_settings_new, red: true,
            onTap: () { key('power'); toast('Power'); }),
          const SizedBox(width: 10),
          _RBtn(label: 'Source', icon: Icons.input,
            onTap: () { key('source'); toast('Source'); }),
          const SizedBox(width: 10),
          _RBtn(label: 'Menu', icon: Icons.menu,
            onTap: () { key('menu'); toast('Menu'); }),
          const SizedBox(width: 10),
          _RBtn(label: 'Info', icon: Icons.info_outline,
            onTap: () { key('info'); toast('Info'); }),
        ])),

        // ── Volume ────────────────────────────────────────────────────────
        _Sec(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.bg3, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            _VolCircle(label: '−', onTap: () { key('volume_down'); toast('Vol −'); }),
            const SizedBox(width: 8),
            _VolCircle(label: '+', onTap: () { key('volume_up'); toast('Vol +'); }),
            const SizedBox(width: 12),
            const Icon(Icons.volume_up_outlined, color: AppColors.text3, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Volume', style: TextStyle(fontSize: 13, color: AppColors.text2))),
            GestureDetector(
              onTap: () { key('volume_mute'); toast('Mute'); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.bg4, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                child: const Text('Mute', style: TextStyle(fontSize: 12, color: AppColors.text)),
              ),
            ),
          ]),
        )),

        // ── D-Pad ─────────────────────────────────────────────────────────
        _Sec(child: Center(child: SizedBox(
          width: 220, height: 220,
          child: GridView.count(
            crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const SizedBox(),
              _DBtn(label: '▲', onTap: () { key('dpad_up'); toast('Up'); }),
              const SizedBox(),
              _DBtn(label: '◀', onTap: () { key('dpad_left'); toast('Left'); }),
              _DBtn(label: 'OK', isOk: true, onTap: () { key('dpad_center'); toast('OK'); }),
              _DBtn(label: '▶', onTap: () { key('dpad_right'); toast('Right'); }),
              const SizedBox(),
              _DBtn(label: '▼', onTap: () { key('dpad_down'); toast('Down'); }),
              const SizedBox(),
            ],
          ),
        ))),

        // ── Back / Home / CH ──────────────────────────────────────────────
        _Sec(child: Row(children: [
          _RBtn(label: 'Back', icon: Icons.arrow_back_ios,
            onTap: () { key('back'); toast('Back'); }),
          const SizedBox(width: 10),
          _RBtn(label: 'Home', icon: Icons.home_outlined, accent: true,
            onTap: () { key('home'); toast('Home'); }),
          const SizedBox(width: 10),
          _RBtn(label: 'CH +', icon: Icons.keyboard_arrow_up,
            onTap: () { key('ch_up'); toast('CH+'); }),
          const SizedBox(width: 10),
          _RBtn(label: 'CH −', icon: Icons.keyboard_arrow_down,
            onTap: () { key('ch_down'); toast('CH−'); }),
        ])),

        // ── Media controls ────────────────────────────────────────────────
        _Sec(child: Row(children: [
          _RBtn(label: '⏮', icon: Icons.skip_previous,
            onTap: () { key('prev'); toast('Previous'); }),
          const SizedBox(width: 8),
          _RBtn(label: '⏪', icon: Icons.fast_rewind,
            onTap: () { key('rewind'); toast('Rewind'); }),
          const SizedBox(width: 8),
          _RBtn(label: '⏯', icon: Icons.play_circle_outline, accent: true,
            onTap: () { key('play_pause'); toast('Play/Pause'); }),
          const SizedBox(width: 8),
          _RBtn(label: '⏩', icon: Icons.fast_forward,
            onTap: () { key('fast_forward'); toast('Forward'); }),
          const SizedBox(width: 8),
          _RBtn(label: '⏭', icon: Icons.skip_next,
            onTap: () { key('next'); toast('Next'); }),
        ])),

        // ── Mic ───────────────────────────────────────────────────────────
        _Sec(child: _MicBtn()),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Sec extends StatelessWidget {
  final Widget child;
  const _Sec({required this.child});
  @override Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: child);
}

class _RBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool red, accent;
  final VoidCallback onTap;
  const _RBtn({required this.label, required this.icon, this.red = false, this.accent = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = red ? AppColors.red : accent ? AppColors.accent : AppColors.text;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: accent ? AppColors.accentDim : AppColors.bg3,
            border: Border.all(color: accent ? const Color(0x4D5B6EF5) : AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _VolCircle extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _VolCircle({required this.label, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: AppColors.bg4, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: AppColors.text)),
    ),
  );
}

class _DBtn extends StatelessWidget {
  final String label;
  final bool isOk;
  final VoidCallback onTap;
  const _DBtn({required this.label, this.isOk = false, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: isOk ? AppColors.accent : AppColors.bg3,
        border: Border.all(color: isOk ? AppColors.accent : AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
        fontSize: isOk ? 13 : 18,
        fontWeight: isOk ? FontWeight.w600 : FontWeight.normal,
        color: Colors.white,
      )),
    ),
  );
}


class _MicBtn extends StatelessWidget {
  const _MicBtn();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RemoteProvider>();
    return GestureDetector(
      onTapDown: (_) => p.startListening(),
      onTapUp: (_) async {
        await p.stopListening();
        if (p.lastVoiceResult.isNotEmpty) {
          p.remote.sendText(p.lastVoiceResult);
        }
      },
      onTapCancel: () => p.stopListening(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: p.isListening ? const Color(0x1AF04545) : AppColors.bg3,
          border: Border.all(color: p.isListening ? const Color(0x66F04545) : AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(Icons.mic, size: 22, color: p.isListening ? AppColors.red : AppColors.text),
          const SizedBox(width: 14),
          Expanded(child: Text(
            p.isListening
                ? (p.lastVoiceResult.isNotEmpty ? p.lastVoiceResult : 'Listening…')
                : 'Hold for Voice Search',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
              color: p.isListening ? AppColors.red : AppColors.text),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
    );
  }
}
