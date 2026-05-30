import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/tv_device.dart';
import '../services/remote_service.dart';

class RemoteProvider extends ChangeNotifier {
  // ── Navigation ─────────────────────────────────────────────────────────────
  int currentTab = 0;

  // ── Devices ────────────────────────────────────────────────────────────────
  List<TvDevice> devices = [];
  TvDevice? connectedDevice;
  bool isScanning = false;
  RawDatagramSocket? _udpSocket;

  // ── Voice ──────────────────────────────────────────────────────────────────
  bool isListening = false;
  String lastVoiceResult = '';
  final _stt = SpeechToText();
  bool _sttAvailable = false;

  // ── Settings ───────────────────────────────────────────────────────────────
  bool darkTheme = true;
  String voiceLanguage = 'English (US)';

  // ── WebSocket remote service ───────────────────────────────────────────────
  final remote = RemoteService();
  bool get isConnected => remote.isConnected;

  RemoteProvider() {
    remote.addListener(notifyListeners);
    _initStt();
    _loadSettings();
    startScan();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void setTab(int i) { currentTab = i; notifyListeners(); }

  // ── UDP Discovery ──────────────────────────────────────────────────────────
  Future<void> startScan() async {
    isScanning = true;
    devices = [];
    notifyListeners();

    try {
      _udpSocket?.close();
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 9001);
      _udpSocket!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = _udpSocket?.receive();
        if (dg == null) return;
        final msg = String.fromCharCodes(dg.data).trim();
        // Expected format: TV_SERVER:<ip>:<port>
        if (!msg.startsWith('TV_SERVER:')) return;
        final parts = msg.split(':');
        if (parts.length < 3) return;
        final ip = parts[1];
        final port = int.tryParse(parts[2]) ?? 9000;
        if (!devices.any((d) => d.ip == ip)) {
          devices.add(TvDevice(id: ip, name: 'WiFi TV ($ip)', ip: ip, port: port, model: 'TV Server'));
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('[Scan] UDP listen error: $e');
    }

    // Stop scanning indicator after 15s but keep socket open
    Future.delayed(const Duration(seconds: 15), () {
      isScanning = false;
      notifyListeners();
    });
  }

  void stopScan() {
    _udpSocket?.close();
    _udpSocket = null;
    isScanning = false;
    notifyListeners();
  }

  // ── Connect to TV server app ───────────────────────────────────────────────
  Future<bool> connectToTvApp(String ip, {int port = 9000}) async {
    final ok = await remote.connect(ip, port: port);
    if (ok) {
      connectedDevice = TvDevice(id: ip, name: 'My TV', ip: ip, port: port, model: 'TV Server');
      await _saveConnected(connectedDevice!);
      setTab(1);
    }
    notifyListeners();
    return ok;
  }

  void disconnectDevice() {
    remote.disconnect();
    connectedDevice = null;
    notifyListeners();
  }

  // ── Remote commands ────────────────────────────────────────────────────────
  void sendKey(String key) => remote.sendKey(key);
  void sendText(String text) => remote.sendText(text);

  // ── Voice ──────────────────────────────────────────────────────────────────
  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize();
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_sttAvailable) return;
    isListening = true;
    notifyListeners();
    await _stt.listen(
      onResult: (r) { lastVoiceResult = r.recognizedWords; notifyListeners(); },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: _sttLocale(),
      ),
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    isListening = false;
    notifyListeners();
  }

  String _sttLocale() {
    switch (voiceLanguage) {
      case 'English (UK)': return 'en_GB';
      case 'Español': return 'es_ES';
      default: return 'en_US';
    }
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    darkTheme = prefs.getBool('darkTheme') ?? true;
    voiceLanguage = prefs.getString('voiceLanguage') ?? 'English (US)';
    if (prefs.get('volume') is int) await prefs.remove('volume');

    final savedIp = prefs.getString('connectedIp');
    final savedPort = prefs.getInt('connectedPort') ?? 9000;
    if (savedIp != null) {
      connectedDevice = TvDevice(id: savedIp, name: 'My TV', ip: savedIp, port: savedPort, model: 'TV Server');
      await remote.connect(savedIp, port: savedPort);
    }
    notifyListeners();
  }

  Future<void> _saveConnected(TvDevice d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connectedIp', d.ip);
    await prefs.setInt('connectedPort', d.port);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _udpSocket?.close();
    remote.dispose();
    _stt.cancel();
    super.dispose();
  }
}
