import 'package:argbcontrol_app/services/ws_client.dart';
import 'package:flutter/material.dart';
import 'package:argbcontrol_app/models/message_builder.dart';

class RainbowPage extends StatefulWidget {
  const RainbowPage({super.key, required this.wsClient});

  final LedWebSocketClient wsClient;

  @override
  _RainbowPageState createState() => _RainbowPageState();
}

class _RainbowPageState extends State<RainbowPage> {
  double _currentSliderValue = 7;
  int _previousDelay = 0;
  bool _appliedInitial = false;

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
      final payload = MessageBuilder.rainbow(delay: delay);
      widget.wsClient.sendUserMessage(payload);
      _previousDelay = delay;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.wsClient.statusListenable.addListener(_applyInitialFromStatus);
    _applyInitialFromStatus();
  }

  @override
  void dispose() {
    widget.wsClient.statusListenable.removeListener(_applyInitialFromStatus);
    super.dispose();
  }

  void _applyInitialFromStatus() {
    if (_appliedInitial) return;
    final s = widget.wsClient.statusListenable.value;
    if (s == null || s.mode != 2) return;
    final int delay = s.rainbowDelay ?? 0;
    // Inverter delay-> slider aproximado
    int speed = 7;
    if (delay >= 640) speed = 1;
    else if (delay >= 320) speed = 2;
    else if (delay >= 160) speed = 3;
    else if (delay >= 80) speed = 4;
    else if (delay >= 40) speed = 5;
    else if (delay >= 20) speed = 6;
    else if (delay >= 10) speed = 7;
    else speed = 8;
    setState(() {
      _currentSliderValue = speed.toDouble();
      _previousDelay = delay;
    });
    _appliedInitial = true;
  }
}
