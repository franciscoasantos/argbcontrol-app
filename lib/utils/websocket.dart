import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket {
  late WebSocketChannel _channel;
  String _lastMessage = "";

  WebSocket(String uri) {
    _channel = WebSocketChannel.connect(Uri.parse(uri));

    _channel.stream.listen((message) {
      _lastMessage = message;
      log(_lastMessage);
    });
  }

  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  String getLastMessage() {
    return _lastMessage;
  }

  String getCurrentFunction() {
    return _lastMessage.substring(0, 1);
  }

  bool isConnected() {
    return _lastMessage != "";
  }
}
