import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_provider.dart';
import '../theme/app_theme.dart';

class PairScreen extends StatelessWidget {
  const PairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RemoteProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text('Find a TV', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text('Make sure the TV Server app is running on your TV', style: TextStyle(fontSize: 13, color: AppColors.text2)),
          const SizedBox(height: 20),

          // Scan pill
          GestureDetector(
            onTap: p.isScanning ? null : p.startScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bg3,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(children: [
                if (p.isScanning)
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                else
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  p.isScanning ? 'Scanning for TVs…' : '${p.devices.length} TV${p.devices.length == 1 ? '' : 's'} found',
                  style: const TextStyle(fontSize: 13, color: AppColors.text2),
                )),
                if (!p.isScanning)
                  const Text('Tap to rescan', style: TextStyle(fontSize: 11, color: AppColors.text3)),
              ]),
            ),
          ),

          const SizedBox(height: 24),
          const Text('AVAILABLE TVS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: AppColors.text3)),
          const SizedBox(height: 10),

          // Connected banner
          if (p.isConnected) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1229C278),
                border: Border.all(color: const Color(0x4429C278)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Connected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.green)),
                  Text(p.connectedDevice?.ip ?? '', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                ])),
                TextButton(
                  onPressed: p.disconnectDevice,
                  child: const Text('Disconnect', style: TextStyle(color: AppColors.red, fontSize: 12)),
                ),
              ]),
            ),
          ],

          // Scanning placeholder
          if (p.isScanning && p.devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Column(children: [
                CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                SizedBox(height: 16),
                Text('Looking for TV Server app on your network…', style: TextStyle(fontSize: 13, color: AppColors.text3), textAlign: TextAlign.center),
              ])),
            ),

          // Empty state
          if (!p.isScanning && p.devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Column(children: [
                Icon(Icons.tv_off, color: AppColors.text3, size: 40),
                SizedBox(height: 12),
                Text('No TVs found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text2)),
                SizedBox(height: 4),
                Text('Make sure the TV Server app is open on your TV', style: TextStyle(fontSize: 12, color: AppColors.text3), textAlign: TextAlign.center),
              ])),
            ),

          // TV list
          ...p.devices.map((d) => _TvCard(
            device: d,
            isConnected: p.connectedDevice?.ip == d.ip && p.isConnected,
            onTap: () async {
              if (p.connectedDevice?.ip == d.ip && p.isConnected) {
                p.setTab(1);
              } else {
                await p.connectToTvApp(d.ip, port: d.port);
              }
            },
          )),
        ],
      ),
    );
  }
}

class _TvCard extends StatelessWidget {
  final dynamic device;
  final bool isConnected;
  final VoidCallback onTap;
  const _TvCard({required this.device, required this.isConnected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isConnected ? const Color(0x125B6EF5) : AppColors.bg3,
          border: Border.all(color: isConnected ? const Color(0x665B6EF5) : AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.bg4, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tv, color: AppColors.text2, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(device.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text)),
            Text(device.ip, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected ? AppColors.accentDim : const Color(0x2429C278),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isConnected ? 'Connected' : 'Tap to connect',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isConnected ? AppColors.accent : AppColors.green),
            ),
          ),
        ]),
      ),
    );
  }
}
