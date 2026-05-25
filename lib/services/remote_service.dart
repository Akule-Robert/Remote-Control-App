import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum TvConnectionState { disconnected, connecting, connected, error }

class RemoteService extends ChangeNotifier {
  WebSocketChannel? _channel;
  TvConnectionState _state = TvConnectionState.disconnected;
  String? _error;

  TvConnectionState get state => _state;
  String? get error => _error;
  bool get isConnected => _state == TvConnectionState.connected;

  Future<bool> connect(String ip, {int port = 9000}) async {
    _setState(TvConnectionState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://$ip:$port'));
      await _channel!.ready;
      _channel!.stream.listen(
        (_) {},
        onError: (e) { _error = e.toString(); _setState(TvConnectionState.error); },
        onDone: () => _setState(TvConnectionState.disconnected),
      );
      _setState(TvConnectionState.connected);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('[Remote] Connect error: $e');
      _setState(TvConnectionState.error);
      return false;
    }
  }

  void send(Map<String, dynamic> msg) {
    if (!isConnected) return;
    _channel?.sink.add(jsonEncode(msg));
  }

  void sendKey(String key) => send({'type': 'key', 'key': key});
  void sendText(String text) => send({'type': 'text', 'value': text});

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _setState(TvConnectionState.disconnected);
  }

  void _setState(TvConnectionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
