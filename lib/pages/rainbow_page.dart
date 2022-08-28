import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';

class RainbowPage extends StatefulWidget {
  const RainbowPage({Key? key, required this.wsClient}) : super(key: key);

  final WebSocket wsClient;

  @override
  _RainbowPageState createState() => _RainbowPageState();
}

class _RainbowPageState extends State<RainbowPage> {
  double _currentSliderValue = 7;
  int _previousDelay = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text("Speed"),
          Slider(
            value: _currentSliderValue,
            max: 8,
            min: 1,
            divisions: 7,
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

  int _calculateSpeed(int speed) {
    int delay = 0;

    switch (speed) {
      case 1:
        delay = 640;
        break;

      case 2:
        delay = 320;
        break;

      case 3:
        delay = 160;
        break;

      case 4:
        delay = 80;
        break;

      case 5:
        delay = 40;
        break;

      case 6:
        delay = 20;
        break;

      case 7:
        delay = 10;
        break;

      case 8:
        delay = 0;
        break;
    }
    return delay;
  }

  void _sendMessage(int delay) {
    if (_previousDelay != delay) {
      widget.wsClient.sendMessage(
          '{"M": "2", "A": "${delay.toString().padLeft(4, '0')}"}');
      _previousDelay = delay;
    }
  }
}
