import 'package:argbcontrol_app/utils/fade_arguments.dart';
import 'package:argbcontrol_app/utils/websocket.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class FadePage extends StatefulWidget {
  const FadePage({super.key, required this.wsClient});

  final WebSocket wsClient;

  @override
  _FadePageState createState() => _FadePageState();
}

class _FadePageState extends State<FadePage> {
  double _currentSliderValue = 3;
  FadeArguments _previousArguments = FadeArguments(0, 0);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text("Speed"),
          Slider(
            value: _currentSliderValue,
            max: 10,
            min: 1,
            divisions: 9,
            label: _currentSliderValue.floor().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSliderValue = value;
                _sendMessage(_calculateSpeed(value.floor()));
              });
            },
          ),
        ],
      ),
    );
  }

  FadeArguments _calculateSpeed(int speed) {
    int increase = 0, delay = 0;

    switch (speed) {
      case 1:
        increase = 1;
        delay = 200;
        break;

      case 2:
        increase = 1;
        delay = 120;
        break;

      case 3:
        increase = 1;
        delay = 60;
        break;

      case 4:
        increase = 1;
        delay = 20;
        break;

      case 5:
        increase = 3;
        delay = 40;
        break;

      case 6:
        increase = 5;
        delay = 25;
        break;

      case 7:
        increase = 5;
        delay = 10;
        break;

      case 8:
        increase = 17;
        delay = 20;
        break;

      case 9:
        increase = 17;
        delay = 10;
        break;

      case 10:
        increase = 17;
        delay = 0;
        break;
    }
    return FadeArguments(increase, delay);
  }

  void _sendMessage(FadeArguments arguments) {
    if (_previousArguments != arguments) {
      final payload = jsonEncode({
        "M": "1",
        "A": "${arguments.increase.toString().padLeft(2, '0')}${arguments.delay.toString().padLeft(3, '0')}"
      });
      widget.wsClient.sendMessage(payload);
      _previousArguments = arguments;
    }
  }
}
