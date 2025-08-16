import 'package:argbcontrol_app/utils/websocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'dart:convert';

class StaticPage extends StatefulWidget {
  const StaticPage({super.key, required this.wsClient});

  final WebSocket wsClient;

  @override
  _StaticPageState createState() => _StaticPageState();
}

class _StaticPageState extends State<StaticPage>
    with AutomaticKeepAliveClientMixin<StaticPage> {
  Color _currentColor = const Color.fromARGB(0, 0, 0, 0);
  double _currentSliderValue = 0;

  final _controller = CircleColorPickerController(
    initialColor: const Color.fromARGB(0, 0, 0, 255),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              final newColor = Color.fromARGB(
                  _currentColor.alpha, color.red, color.green, color.blue);
              _sendMessage(newColor);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              const Text("White Intensity"),
              Slider(
                value: _currentSliderValue,
                max: 255,
                min: 0,
                divisions: 50,
                label: "${(_currentSliderValue / 255 * 100).floor()}%",
                onChanged: (double value) {
                  final color = Color.fromARGB(
                      value.round(),
                      _currentColor.red,
                      _currentColor.green,
                      _currentColor.blue);
                  _sendMessage(color);
                  setState(() {
                    _currentSliderValue = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage(Color color) {
    if (color != _currentColor) {
      int R = color.red;
      int G = color.green;
      int B = color.blue;
      int W = color.alpha;
      widget.wsClient.sendMessage(jsonEncode({
        "M": "0",
        "R": "$R",
        "G": "$G",
        "B": "$B",
        "W": "$W"
      }));
    }
    _currentColor = color;
  }
}
