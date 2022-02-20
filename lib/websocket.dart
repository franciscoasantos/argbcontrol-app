import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket {
  late WebSocketChannel _channel;
  String _lastMessage = "";
  
  WebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse('ws://services.franciscosantos.net:3000/?clientId=1'));

    _channel.stream.listen((message) {
      _lastMessage = message;
    });
  }

  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  String getLastMessage(){
    return _lastMessage;
  }
}
