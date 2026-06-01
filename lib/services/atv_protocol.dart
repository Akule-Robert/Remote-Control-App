// Android TV Remote Protocol - Protobuf message builders
// Based on the open Android TV Remote Service protocol spec
// Ref: https://developers.google.com/cast/docs/android_tv_remote

import 'dart:typed_data';

/// Builds a raw protobuf-encoded pairing request message
/// Field 1 (service_name), Field 2 (client_name)
Uint8List buildPairingRequest(String serviceName, String clientName) {
  return _encodeMessage({
    1: _encodeString(serviceName),
    2: _encodeString(clientName),
  });
}

/// Builds a pairing option message (encoding + role)
Uint8List buildPairingOption() {
  // preferred_role = 1 (INPUT), encoding type = 3 (HEXADECIMAL), symbol_length = 4
  return _encodeMessage({
    2: _encodeMessage({1: _encodeVarint(3), 2: _encodeVarint(4)}),
    1: _encodeVarint(1),
  });
}

/// Builds a pairing secret message from the 4-digit PIN
Uint8List buildPairingSecret(Uint8List secret) {
  return _encodeMessage({1: _encodeBytes(secret)});
}

/// Builds a remote key message (key_code + key_event_type)
/// event: 1=down, 2=up
Uint8List buildKeyMessage(int keyCode, {int event = 1}) {
  // RemoteMessage -> remote_key_inject -> key_code + key_event_type
  return _encodeMessage({
    4: _encodeMessage({
      1: _encodeMessage({
        1: _encodeVarint(keyCode),
        2: _encodeVarint(event),
      }),
    }),
  });
}

/// Builds a remote key press (down + up combined as sequence)
List<Uint8List> buildKeyPress(int keyCode) => [
  buildKeyMessage(keyCode, event: 1),
  buildKeyMessage(keyCode, event: 2),
];

// ── Android TV key codes ──────────────────────────────────────────────────────
class AtvKey {
  static const power        = 26;
  static const home         = 3;
  static const back         = 4;
  static const menu         = 82;
  static const dpadUp       = 19;
  static const dpadDown     = 20;
  static const dpadLeft     = 21;
  static const dpadRight    = 22;
  static const dpadCenter   = 23;  // OK
  static const volumeUp     = 24;
  static const volumeDown   = 25;
  static const volumeMute   = 164;
  static const mediaPlay    = 126;
  static const mediaPause   = 127;
  static const mediaPlayPause = 85;
  static const mediaNext    = 87;
  static const mediaPrev    = 88;
  static const mediaRewind  = 89;
  static const mediaFastFwd = 90;
  static const channelUp    = 166;
  static const channelDown  = 167;
  static const source       = 178;
  static const red          = 183;
  static const green        = 184;
  static const yellow       = 185;
  static const blue         = 186;
}

// ── Minimal protobuf encoder ──────────────────────────────────────────────────

Uint8List _encodeVarint(int value) {
  final bytes = <int>[];
  while (value > 0x7F) {
    bytes.add((value & 0x7F) | 0x80);
    value >>= 7;
  }
  bytes.add(value & 0x7F);
  return Uint8List.fromList(bytes);
}

Uint8List _encodeString(String s) {
  final encoded = Uint8List.fromList(s.codeUnits);
  return Uint8List.fromList([..._encodeVarint(encoded.length), ...encoded]);
}

Uint8List _encodeBytes(Uint8List b) {
  return Uint8List.fromList([..._encodeVarint(b.length), ...b]);
}

Uint8List _encodeMessage(Map<int, Uint8List> fields) {
  final body = <int>[];
  for (final entry in fields.entries) {
    // wire type 2 (length-delimited) for all fields
    final tag = (entry.key << 3) | 2;
    body.addAll(_encodeVarint(tag));
    body.addAll(entry.value);
  }
  return Uint8List.fromList([..._encodeVarint(body.length), ...body]);
}
