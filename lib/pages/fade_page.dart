import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';

class FadePage extends StatefulWidget {
  const FadePage({Key? key, required this.wsClient}) : super(key: key);

  final WebSocket wsClient;

  @override
  _FadePageState createState() => _FadePageState();
}

class _FadePageState extends State<FadePage> {
  @override
  Widget build(BuildContext context) {
    _sendMessage(const Color.fromARGB(255, 0, 0, 0));
    return Center(
      child: Column(
        children: const [
          Text("TODO"),
        ],
      ),
    );
  }

  void _sendMessage(Color color) {
    int R = color.red;
    int G = color.green;
    int B = color.blue;
    widget.wsClient.sendMessage('{"M": "1", "R": "$R", "G": "$G", "B": "$B"}');
  }
}
