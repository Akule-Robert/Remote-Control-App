import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/tv_device.dart';

class DiscoveryService {
  static const _channel = MethodChannel('wifi_tv_remote/multicast');
  static const _mdnsAddr = '224.0.0.251';
  static const _mdnsPort = 5353;

  static Future<void> scan({
    required void Function(TvDevice) onDeviceFound,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final seen = <String>{};

    void report(TvDevice d) {
      if (seen.add(d.ip)) {
        debugPrint('[Discovery] Found: ${d.name} @ ${d.ip}');
        onDeviceFound(d);
      }
    }

    // Acquire multicast lock
    try { await _channel.invokeMethod('acquireLock'); } catch (_) {}

    try {
      // Run mDNS and subnet scan concurrently
      await Future.wait([
        _mdnsScan(report, const Duration(seconds: 8)),
        _subnetScan(report, timeout: timeout),
      ]);
    } finally {
      try { await _channel.invokeMethod('releaseLock'); } catch (_) {}
    }
  }

  // ── Raw UDP mDNS ───────────────────────────────────────────────────────────
  static Future<void> _mdnsScan(
    void Function(TvDevice) report,
    Duration timeout,
  ) async {
    RawDatagramSocket? sock;
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      sock.multicastHops = 255;
      sock.broadcastEnabled = true;

      sock.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = sock?.receive();
        if (dg == null) return;
        final ip = dg.address.address;
        final name = _parseMdnsName(dg.data) ?? 'Android TV';
        report(TvDevice(id: ip, name: name, ip: ip, port: 6466, model: 'Android TV'));
      });

      for (final svc in [
        '_androidtvremote2._tcp.local',
        '_androidtvremote._tcp.local',
      ]) {
        final q = _buildMdnsQuery(svc);
        sock.send(q, InternetAddress(_mdnsAddr), _mdnsPort);
        await Future.delayed(const Duration(milliseconds: 300));
        sock.send(q, InternetAddress(_mdnsAddr), _mdnsPort);
      }

      await Future.delayed(timeout);
    } catch (e) {
      debugPrint('[Discovery] mDNS error: $e');
    } finally {
      sock?.close();
    }
  }

  static Uint8List _buildMdnsQuery(String service) {
    final labels = service.split('.');
    final buf = BytesBuilder();
    buf.add([0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    for (final label in labels) {
      if (label.isEmpty) continue;
      buf.addByte(label.length);
      buf.add(label.codeUnits);
    }
    buf.addByte(0x00);
    buf.add([0x00, 0x0c, 0x80, 0x01]);
    return buf.toBytes();
  }

  static String? _parseMdnsName(Uint8List data) {
    try {
      int i = 12;
      final parts = <String>[];
      while (i < data.length) {
        final len = data[i];
        if (len == 0 || (len & 0xC0) == 0xC0) break;
        i++;
        if (i + len > data.length) break;
        parts.add(String.fromCharCodes(data.sublist(i, i + len)));
        i += len;
      }
      if (parts.isNotEmpty) return parts.first;
    } catch (_) {}
    return null;
  }

  // ── Subnet TCP scan — all 254 hosts fully parallel ─────────────────────────
  static Future<void> _subnetScan(
    void Function(TvDevice) report, {
    required Duration timeout,
  }) async {
    String? wifiIp;
    try { wifiIp = await NetworkInfo().getWifiIP(); } catch (_) {}
    if (wifiIp == null) {
      debugPrint('[Discovery] WiFi IP null — subnet scan skipped');
      return;
    }
    debugPrint('[Discovery] Phone IP: $wifiIp — scanning subnet');

    final subnet = wifiIp.substring(0, wifiIp.lastIndexOf('.'));
    // Probe common ports AND a wide range to find ANY device
    const tvPorts = [6466, 6467, 8008, 8009, 7000];
    const commonPorts = [80, 443, 554, 1925, 3000, 4444, 5000, 8080];
    final allPorts = [...tvPorts, ...commonPorts];

    await Future.wait([
      for (int i = 1; i <= 254; i++)
        if ('$subnet.$i' != wifiIp) _probeHost('$subnet.$i', allPorts, report),
    ]).timeout(timeout, onTimeout: () => []);
  }

  static Future<void> _probeHost(
    String ip,
    List<int> ports,
    void Function(TvDevice) report,
  ) async {
    for (final port in ports) {
      try {
        final sock = await Socket.connect(ip, port,
            timeout: const Duration(milliseconds: 600));
        sock.destroy();
        final isTv = [6466, 6467, 8008, 8009, 7000].contains(port);
        debugPrint('[Discovery] REACHABLE: $ip:$port (${isTv ? "TV port" : "other"})');
        report(TvDevice(
          id: ip,
          name: isTv ? 'Android TV ($ip)' : 'Device ($ip) port:$port',
          ip: ip,
          port: isTv ? 6466 : port,
          model: isTv ? 'Android TV' : 'Unknown Device',
        ));
        return; // one open port is enough to show the device
      } catch (_) {}
    }
  }
}
