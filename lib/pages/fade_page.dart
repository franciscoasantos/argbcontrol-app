import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';

class FadePage extends StatefulWidget {
  const FadePage({Key? key, required this.wsClient}) : super(key: key);

  final WebSocket wsClient;

  @override
  _FadePageState createState() => _FadePageState();
}

class _FadePageState extends State<FadePage> {
  double _currentSliderValue = 3;

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
                _calculateSpeed(value.floor());
              });
            },
          ),
        ],
      ),
    );
  }

  void _calculateSpeed(int speed) {
    int increase = 0, delay = 0;

    switch (speed) {
      case 1:
        increase = 1;
        delay = 140;
        break;

      case 2:
        increase = 1;
        delay = 100;
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
        delay = 20;
        break;

      case 6:
        increase = 5;
        delay = 20;
        break;

      case 7:
        increase = 5;
        delay = 10;
        break;

      case 8:
        increase = 17;
        delay = 60;
        break;

      case 9:
        increase = 17;
        delay = 20;
        break;

      case 10:
        increase = 17;
        delay = 0;
        break;
    }
    _sendMessage(increase, delay);
  }

  void _sendMessage(int increase, int delay) {
    widget.wsClient.sendMessage('{"M": "1", "A": "${increase.toString().padLeft(2,'0')}${delay.toString().padLeft(3,'0')}"}');
  }
}
