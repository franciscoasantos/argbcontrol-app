import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket {
  WebSocketChannel? _channel;
  bool _isWebsocketRunning = false;

  String _lastMessage = "";
  late Uri _uri;

  WebSocket(String uri) {
    _uri = Uri.parse(uri);
  }

  void sendMessage(String message) {
    _channel!.sink.add(message);
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
    if (_isWebsocketRunning) return;
    
    _channel = WebSocketChannel.connect(_uri);

    _channel!.stream.listen(
      (event) {
        if (!_isWebsocketRunning) _isWebsocketRunning = true;
        _lastMessage = event;
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
    await Future.delayed(const Duration(milliseconds: 500), () {
      closeStream();
      startStream();
    });
  }

  void closeStream() {
    _channel!.sink.close();
    _isWebsocketRunning = false;
  }
}
