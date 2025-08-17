import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:argbcontrol_app/utils/logger.dart';
import 'package:argbcontrol_app/models/led_status.dart';

class LedWebSocketClient {
  WebSocketChannel? _channel;
  bool _isWebsocketRunning = false;
  bool _isDisposed = false;
  bool _isConnecting = false;
  final ValueNotifier<bool> _connectedListenable = ValueNotifier<bool>(false);
  final ValueNotifier<LedStatus?> _statusListenable = ValueNotifier<LedStatus?>(null);

  String _lastMessage = "";
  String? _lastSentMessage;
  String? _lastNonOffSentMessage;
  late Uri _uri;
  Future<Uri> Function()? _uriProvider;

  LedWebSocketClient(String uri) {
    _uri = Uri.parse(uri);
  }

  LedWebSocketClient.withUriProvider(Future<Uri> Function() uriProvider) {
    _uriProvider = uriProvider;
  }

  void sendMessage(String message) {
    final channel = _channel;
    if (channel == null) {
      ensureConnected();
      _lastSentMessage = message;
      AppLogger.d('[WS][out][queued] $message');
      return;
    }
    channel.sink.add(message);
    _lastSentMessage = message;
    AppLogger.d('[WS][out] $message');
  }

  void sendUserMessage(String message, {bool isPowerOff = false}) {
    if (!isPowerOff) {
      _lastNonOffSentMessage = message;
    }
    sendMessage(message);
  }

  String getLastMessage() {
    return _lastMessage;
  }

  bool isWebsocketRunning() {
    return _isWebsocketRunning;
  }

  void startStream() async {
    if (_isWebsocketRunning || _isDisposed || _isConnecting) return;
    _isConnecting = true;
    _connectedListenable.value = false;
    try {
      Uri uriToConnect;
      if (_uriProvider != null) {
        try {
          uriToConnect = await _uriProvider!();
        } catch (_) {
          _isConnecting = false;
          restartStream();
          return;
        }
      } else {
        uriToConnect = _uri;
      }
      _channel = WebSocketChannel.connect(uriToConnect);
    } catch (_) {
      _isConnecting = false;
      restartStream();
      return;
    }

    _channel!.stream.listen(
      (event) {
        if (!_isWebsocketRunning) _isWebsocketRunning = true;
        _lastMessage = event;
        AppLogger.d('[WS][in] $event');
        _currentReconnectDelayMs = _initialReconnectDelayMs;
        if (_connectedListenable.value == false) {
          _connectedListenable.value = true;
        }
        final parsed = LedStatus.tryParse(event);
        if (parsed != null) {
          _statusListenable.value = parsed;
        }
        final pending = _lastSentMessage;
        if (pending != null) {
          try {
            _channel?.sink.add(pending);
          } catch (_) {}
          _lastSentMessage = null;
        }
      },
      onDone: () {
        restartStream();
      },
      onError: (err) {
        restartStream();
      },
    );
    _isConnecting = false;
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
    _isConnecting = false;
    if (_connectedListenable.value == true) {
      _connectedListenable.value = false;
    }
    _channel = null;
  }

  // Backoff settings
  static const int _initialReconnectDelayMs = 800;
  static const int _maxReconnectDelayMs = 10000;
  int _currentReconnectDelayMs = _initialReconnectDelayMs;

  void dispose() {
    _isDisposed = true;
    closeStream();
  }

  void ensureConnected() {
    if (_isDisposed) return;
    if (!_isWebsocketRunning) {
      startStream();
    }
  }

  ValueListenable<bool> get connectionListenable => _connectedListenable;
  ValueListenable<LedStatus?> get statusListenable => _statusListenable;

  String? getLastNonOffSentMessage() => _lastNonOffSentMessage;
}


