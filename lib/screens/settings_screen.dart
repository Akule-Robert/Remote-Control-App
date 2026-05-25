import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toast(String msg) {
    if (!mounted) return;
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 20),

          _Group(label: 'Paired TVs', children: [
            if (p.devices.isEmpty)
              const _Item(icon: Icons.tv_off, title: 'No TVs paired yet', subtitle: 'Go to Pair tab to find your TV'),
            ...p.devices.map((d) => _Item(
              icon: Icons.tv,
              title: d.name,
              subtitle: '${d.ip} · ${d.isConnected ? "Active" : d.isPaired ? "Paired" : "Saved"}',
              trailing: d.isConnected
                  ? _badge('Active')
                  : d.isPaired
                      ? _badge('Paired', green: true)
                      : IconButton(
                          icon: const Icon(Icons.link_off, color: AppColors.text3, size: 16),
                          onPressed: () => p.disconnectDevice(),
                        ),
            )),
          ]),

          _Group(label: 'Appearance', children: [
            _Item(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Theme',
              subtitle: p.darkTheme ? 'Currently enabled' : 'Currently disabled',
              trailing: _Toggle(
                value: p.darkTheme,
                onChanged: (v) async {
                  p.darkTheme = v;
                  await p.saveSetting('darkTheme', v);
                  _toast('Theme updated (restart to apply)');
                },
              ),
            ),
          ]),

          _Group(label: 'Screen Mirroring', children: [
            _Item(
              icon: Icons.cast,
              title: 'Stream Quality',
              trailing: _Select(
                value: 'Medium',
                options: const ['Low', 'Medium', 'High'],
                onChanged: (v) => _toast('Quality: $v'),
              ),
            ),
            _Item(
              icon: Icons.play_circle_outline,
              title: 'Auto-connect on launch',
              subtitle: 'Reconnect to last TV automatically',
              trailing: _Toggle(
                value: true,
                onChanged: (v) => _toast('Saved'),
              ),
            ),
          ]),

          _Group(label: 'Voice', children: [
            _Item(
              icon: Icons.language,
              title: 'Language',
              trailing: _Select(
                value: p.voiceLanguage,
                options: const ['English (US)', 'English (UK)', 'Español', 'Français'],
                onChanged: (v) async {
                  p.voiceLanguage = v!;
                  await p.saveSetting('voiceLanguage', v);
                  _toast(v);
                },
              ),
            ),
          ]),

          _Group(label: 'Connection', children: [
            _Item(
              icon: Icons.wifi_find,
              title: 'Scan for TVs',
              subtitle: 'Refresh the device list',
              trailing: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.accent, size: 20),
                onPressed: () async {
                  await p.scanDevices();
                  _toast('${p.devices.length} device(s) found');
                },
              ),
            ),
            if (p.connectedDevice != null)
              _Item(
                icon: Icons.link_off,
                title: 'Disconnect',
                subtitle: 'Disconnect from ${p.connectedDevice!.name}',
                trailing: TextButton(
                  onPressed: () { p.disconnectDevice(); _toast('Disconnected'); },
                  child: const Text('Disconnect', style: TextStyle(color: AppColors.red, fontSize: 13)),
                ),
              ),
          ]),

          _Group(label: 'About', children: const [
            _Item(icon: Icons.info_outline, title: 'WiFi TV Remote', subtitle: 'Version 1.0.0'),
            _Item(icon: Icons.code, title: 'Protocol', subtitle: 'Android TV Remote v2 (ATV)'),
          ]),
        ],
      ),
    );
  }

  Widget _badge(String label, {bool green = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: green ? const Color(0x2429C278) : AppColors.accentDim,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: green ? AppColors.green : AppColors.accent)),
  );
}

class _Group extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _Group({required this.label, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: AppColors.text3)),
      ),
      Container(
        decoration: BoxDecoration(color: AppColors.bg3, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(22)),
        child: Column(
          children: children.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < children.length - 1) const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
          ])).toList(),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _Item({required this.icon, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: AppColors.bg4, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.accent),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
        if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
      ])),
      ?trailing,
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46, height: 26,
      decoration: BoxDecoration(color: value ? AppColors.accent : AppColors.bg4, borderRadius: BorderRadius.circular(13)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20, height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 3)]),
        ),
      ),
    ),
  );
}

class _Select extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _Select({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppColors.bg4, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.text),
        dropdownColor: AppColors.bg3,
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.text3),
      ),
    ),
  );
}
