import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket {
  WebSocketChannel? _channel;
  bool _isWebsocketRunning = false;
  bool _isDisposed = false;

  String _lastMessage = "";
  late Uri _uri;

  WebSocket(String uri) {
    _uri = Uri.parse(uri);
  }

  void sendMessage(String message) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(message);
  }

  String getLastMessage() {
    return _lastMessage;
  }

  String getCurrentMode() {
    return _lastMessage.substring(0, 1);
  }

  bool isWebsocketRunning() {
    return _isWebsocketRunning;
  }

  void startStream() async {
    if (_isWebsocketRunning || _isDisposed) return;
    
    _channel = WebSocketChannel.connect(_uri);

    _channel!.stream.listen(
      (event) {
        if (!_isWebsocketRunning) _isWebsocketRunning = true;
        _lastMessage = event;
        _currentReconnectDelayMs = _initialReconnectDelayMs;
      },
      onDone: () {
        restartStream();
      },
      onError: (err) {
        restartStream();
      },
    );
  }

  void restartStream() async {
    if (_isDisposed) return;
    await Future.delayed(Duration(milliseconds: _currentReconnectDelayMs), () {
      if (_isDisposed) return;
      closeStream();
      startStream();
    });
    _currentReconnectDelayMs = math.min(_currentReconnectDelayMs * 2, _maxReconnectDelayMs);
  }

  void closeStream() {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.close();
    _isWebsocketRunning = false;
  }

  // Backoff settings
  static const int _initialReconnectDelayMs = 800;
  static const int _maxReconnectDelayMs = 10000;
  int _currentReconnectDelayMs = _initialReconnectDelayMs;

  void dispose() {
    _isDisposed = true;
    closeStream();
  }
}
