import 'package:argbcontrol_app/utils/websocket.dart';

class ScreenArguments {
  final WebSocket client;
  final String lastMessage;

  ScreenArguments(this.client, this.lastMessage);
}