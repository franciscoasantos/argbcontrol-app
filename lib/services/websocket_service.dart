import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:argbcontrol_app/utils/logger.dart';
import 'package:argbcontrol_app/models/led_status.dart';

/// Serviço singleton para gerenciar a conexão WebSocket com retry automático
/// e gerenciamento adequado do ciclo de vida
class WebSocketService extends ChangeNotifier {
  static WebSocketService? _instance;

  factory WebSocketService({required Future<Uri> Function() uriProvider}) {
    _instance ??= WebSocketService._internal(uriProvider);
    return _instance!;
  }

  WebSocketService._internal(this._uriProvider);

  // Dependências
  final Future<Uri> Function() _uriProvider;

  // Estado da conexão
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;
  Timer? _reconnectTimer;
  Uri? _cachedUri;

  // Flags de controle
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDisposed = false;
  bool _manualDisconnect = false;

  // Contadores e backoff
  int _reconnectAttempts = 0;
  int _currentReconnectDelayMs = _initialReconnectDelayMs;
  static const int _initialReconnectDelayMs = 1000;
  static const int _maxReconnectDelayMs = 10000;
  static const int _maxConsecutiveFailures = 10;

  // Estado da aplicação
  LedStatus? _currentStatus;
  String? _lastSentMessage;
  String? _lastNonOffSentMessage;
  final List<String> _messageQueue = [];

  // Getters públicos
  bool get isConnected => _isConnected;
  LedStatus? get currentStatus => _currentStatus;
  String? get lastNonOffSentMessage => _lastNonOffSentMessage;

  /// Inicia a conexão WebSocket
  Future<void> connect() async {
    if (_isDisposed || _isConnecting || _isConnected) return;

    _isConnecting = true;
    _manualDisconnect = false;
    notifyListeners();

    try {
      // Limita tentativas consecutivas
      if (_reconnectAttempts >= _maxConsecutiveFailures) {
        AppLogger.d('[WS] Max consecutive failures reached. Waiting longer...');
        _currentReconnectDelayMs = _maxReconnectDelayMs;
      }

      // Obtém URI (usa cache se disponível e não é primeira tentativa)
      Uri uri;
      if (_cachedUri != null && _reconnectAttempts > 0) {
        uri = _cachedUri!;
      } else {
        try {
          uri = await _uriProvider();
          _cachedUri = uri;
        } catch (e) {
          AppLogger.d('[WS] Failed to get URI: $e');
          _isConnecting = false;
          _scheduleReconnect();
          return;
        }
      }

      AppLogger.d('[WS] Connecting... (attempt ${_reconnectAttempts + 1})');

      // Cria conexão
      _channel = WebSocketChannel.connect(uri);

      // Configura listener
      _streamSubscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onConnectionClosed,
        onError: _onError,
        cancelOnError: false,
      );

      _reconnectAttempts++;
    } catch (e) {
      AppLogger.d('[WS] Connection failed: $e');
      _isConnecting = false;
      _cleanup();
      _scheduleReconnect();
    }
  }

  /// Desconecta do WebSocket
  void disconnect() {
    _manualDisconnect = true;
    _cleanup();
    notifyListeners();
  }

  /// Reconecta forçadamente (limpa cache e reseta contador)
  Future<void> reconnect() async {
    AppLogger.d('[WS] Force reconnect requested');

    // Cancela qualquer reconexão agendada
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Limpa cache e reseta contadores
    _cachedUri = null;
    _reconnectAttempts = 0;
    _currentReconnectDelayMs = _initialReconnectDelayMs;

    // Desconecta e reconecta
    _cleanup();

    // Aguarda um momento para garantir limpeza
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_isDisposed) {
      await connect();
    }
  }

  /// Envia mensagem ao servidor
  void sendMessage(String message, {bool isPowerOff = false}) {
    if (!isPowerOff) {
      _lastNonOffSentMessage = message;
    }

    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(message);
        _lastSentMessage = null;
        AppLogger.d('[WS][out] $message');
      } catch (e) {
        AppLogger.d('[WS] Failed to send message: $e');
        _messageQueue.add(message);
      }
    } else {
      // Enfileira mensagem para envio quando conectar
      _lastSentMessage = message;
      _messageQueue.add(message);
      AppLogger.d('[WS][out][queued] $message');

      // Tenta conectar se não estiver conectado
      if (!_isConnecting) {
        connect();
      }
    }
  }

  /// Processa mensagens recebidas
  void _onMessage(dynamic event) {
    if (!_isConnected) {
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _currentReconnectDelayMs = _initialReconnectDelayMs;
      AppLogger.d('[WS] Connected successfully');
      notifyListeners();

      // Processa fila de mensagens
      _processMessageQueue();
    }

    final message = event.toString();
    AppLogger.d('[WS][in] $message');

    // Parseia status
    final status = LedStatus.tryParse(message);
    if (status != null) {
      _currentStatus = status;
      notifyListeners();
    }
  }

  /// Processa fila de mensagens pendentes
  void _processMessageQueue() {
    // Envia última mensagem pendente primeiro
    if (_lastSentMessage != null && _channel != null) {
      try {
        _channel!.sink.add(_lastSentMessage!);
        AppLogger.d('[WS][out][queued->sent] $_lastSentMessage');
      } catch (_) {}
      _lastSentMessage = null;
    }

    // Envia demais mensagens da fila
    while (_messageQueue.isNotEmpty && _channel != null) {
      final msg = _messageQueue.removeAt(0);
      try {
        _channel!.sink.add(msg);
        AppLogger.d('[WS][out][queued->sent] $msg');
      } catch (_) {
        break;
      }
    }
  }

  /// Trata fechamento da conexão
  void _onConnectionClosed() {
    AppLogger.d('[WS] Connection closed');
    final wasConnected = _isConnected;
    _cleanup();

    if (wasConnected) {
      notifyListeners();
    }

    if (!_manualDisconnect && !_isDisposed) {
      _scheduleReconnect();
    }
  }

  /// Trata erros da conexão
  void _onError(dynamic error) {
    AppLogger.d('[WS] Stream error: $error');
    _onConnectionClosed();
  }

  /// Agenda reconexão com backoff exponencial
  void _scheduleReconnect() {
    if (_isDisposed || _manualDisconnect || _reconnectTimer != null) return;

    AppLogger.d('[WS] Reconnecting in ${_currentReconnectDelayMs}ms...');

    _reconnectTimer = Timer(
      Duration(milliseconds: _currentReconnectDelayMs),
      () {
        _reconnectTimer = null;
        if (!_isDisposed && !_manualDisconnect) {
          connect();
        }
      },
    );

    // Aumenta delay para próxima tentativa
    _currentReconnectDelayMs = math.min(
      (_currentReconnectDelayMs * 1.5).round(),
      _maxReconnectDelayMs,
    );
  }

  /// Limpa recursos da conexão
  void _cleanup() {
    _isConnected = false;
    _isConnecting = false;

    _streamSubscription?.cancel();
    _streamSubscription = null;

    _channel?.sink.close();
    _channel = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _manualDisconnect = true;
    _cleanup();
    _messageQueue.clear();
    super.dispose();
  }

  /// Reseta o singleton (útil para testes)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}
