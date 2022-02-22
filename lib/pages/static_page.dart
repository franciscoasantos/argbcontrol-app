import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';

class StaticPage extends StatefulWidget {
  const StaticPage({Key? key, required this.wsClient}) : super(key: key);

  final WebSocket wsClient;

  @override
  _StaticPageState createState() => _StaticPageState();
}

class _StaticPageState extends State<StaticPage>
    with AutomaticKeepAliveClientMixin<StaticPage> {
  Color _previousColor = Colors.black;

  final _controller = CircleColorPickerController(
    initialColor: const Color.fromARGB(255, 0, 0, 255),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    _sendMessage(_previousColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 48),
        Center(
          child: CircleColorPicker(
            controller: _controller,
            textStyle: const TextStyle(color: Colors.white),
            size: const Size(300, 300),
            strokeWidth: 4,
            thumbSize: 36,
            onChanged: (color) {
              setState(() => color);
              _sendMessage(color);
            },
          ),
        ),
      ],
    );
  }

  void _sendMessage(Color color) {
    if (color != _previousColor) {
      int R = color.red;
      int G = color.green;
      int B = color.blue;
      widget.wsClient
          .sendMessage('{"M": "0", "R": "$R", "G": "$G", "B": "$B"}');
    }
    _previousColor = color;
  }
}
