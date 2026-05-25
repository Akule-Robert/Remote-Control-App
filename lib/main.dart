import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/remote_provider.dart';
import 'screens/pair_screen.dart';
import 'screens/remote_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => RemoteProvider(),
      child: const WifiTvRemoteApp(),
    ),
  );
}

class WifiTvRemoteApp extends StatelessWidget {
  const WifiTvRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi TV Remote',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _screens = [
    PairScreen(),
    RemoteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<RemoteProvider>().currentTab;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _screens[tab]),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  static const _items = [
    (icon: Icons.wifi, label: 'Pair'),
    (icon: Icons.settings_remote, label: 'Remote'),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<RemoteProvider>().currentTab;
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: _items.asMap().entries.map((e) {
          final active = e.key == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => context.read<RemoteProvider>().setTab(e.key),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(e.value.icon, size: 22, color: active ? AppColors.accent : AppColors.text3),
                  const SizedBox(height: 4),
                  Text(e.value.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: active ? AppColors.accent : AppColors.text3)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
