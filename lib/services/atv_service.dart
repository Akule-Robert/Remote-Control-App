import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'atv_protocol.dart';

enum AtvState { disconnected, connecting, pairing, paired, error }

class AtvService {
  SecureSocket? _socket;
  AtvState _state = AtvState.disconnected;
  String? _lastError;

  AtvState get state => _state;
  String? get lastError => _lastError;

  final _stateCtrl = StreamController<AtvState>.broadcast();
  Stream<AtvState> get stateStream => _stateCtrl.stream;

  // ── Connect & start pairing ────────────────────────────────────────────────
  Future<void> startPairing(String ip, {int port = 6467}) async {
    _setState(AtvState.connecting);
    try {
      _socket = await SecureSocket.connect(
        ip, port,
        onBadCertificate: (_) => true, // TV uses self-signed cert
        timeout: const Duration(seconds: 5),
      );
      _setState(AtvState.pairing);

      // Send pairing request
      _send(buildPairingRequest('wifi_tv_remote', 'Flutter Remote'));
      // Send encoding options
      _send(buildPairingOption());
    } catch (e) {
      _lastError = e.toString();
      _setState(AtvState.error);
    }
  }

  // ── Submit PIN entered by user ─────────────────────────────────────────────
  Future<bool> submitPin(String pin) async {
    if (_socket == null) return false;
    try {
      // Derive secret: SHA-256 of (client_cert_bytes + server_cert_bytes + pin_bytes)
      // For the prototype we send the PIN bytes directly as the secret
      final secret = Uint8List.fromList(pin.codeUnits);
      _send(buildPairingSecret(secret));

      // Wait for acknowledgement (any response = success for prototype)
      final completer = Completer<bool>();
      _socket!.listen(
        (data) { if (!completer.isCompleted) completer.complete(true); },
        onError: (_) { if (!completer.isCompleted) completer.complete(false); },
        onDone: () { if (!completer.isCompleted) completer.complete(false); },
        cancelOnError: true,
      );
      final ok = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (ok) _setState(AtvState.paired);
      return ok;
    } catch (e) {
      _lastError = e.toString();
      _setState(AtvState.error);
      return false;
    }
  }

  // ── Connect to already-paired TV (remote port) ─────────────────────────────
  Future<void> connectRemote(String ip, {int port = 6466}) async {
    _setState(AtvState.connecting);
    try {
      _socket = await SecureSocket.connect(
        ip, port,
        onBadCertificate: (_) => true,
        timeout: const Duration(seconds: 5),
      );
      _setState(AtvState.paired);
    } catch (e) {
      _lastError = e.toString();
      _setState(AtvState.error);
    }
  }

  // ── Send a key press (down + up) ───────────────────────────────────────────
  Future<void> sendKey(int keyCode) async {
    if (_socket == null || _state != AtvState.paired) return;
    try {
      for (final msg in buildKeyPress(keyCode)) {
        _send(msg);
        await Future.delayed(const Duration(milliseconds: 80));
      }
    } catch (e) {
      _lastError = e.toString();
      _setState(AtvState.error);
    }
  }

  // ── Send text character by character ──────────────────────────────────────
  Future<void> sendText(String text) async {
    for (final char in text.runes) {
      // Map common chars to key codes; TV handles the rest via IME
      final key = _charToKeyCode(char);
      if (key != null) await sendKey(key);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _setState(AtvState.disconnected);
  }

  void _send(Uint8List data) {
    // ATV framing: 2-byte big-endian length prefix
    final frame = ByteData(2 + data.length);
    frame.setUint16(0, data.length, Endian.big);
    for (int i = 0; i < data.length; i++) {
      frame.setUint8(2 + i, data[i]);
    }
    _socket?.add(frame.buffer.asUint8List());
  }

  void _setState(AtvState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  void dispose() {
    disconnect();
    _stateCtrl.close();
  }

  // Basic char → Android keycode mapping
  int? _charToKeyCode(int char) {
    if (char >= 'a'.codeUnitAt(0) && char <= 'z'.codeUnitAt(0)) {
      return 29 + (char - 'a'.codeUnitAt(0)); // KEYCODE_A = 29
    }
    if (char >= 'A'.codeUnitAt(0) && char <= 'Z'.codeUnitAt(0)) {
      return 29 + (char - 'A'.codeUnitAt(0));
    }
    if (char >= '0'.codeUnitAt(0) && char <= '9'.codeUnitAt(0)) {
      return 7 + (char - '0'.codeUnitAt(0)); // KEYCODE_0 = 7
    }
    if (char == ' '.codeUnitAt(0)) return 62; // KEYCODE_SPACE
    return null;
  }
}
