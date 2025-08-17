import 'package:argbcontrol_app/utils/fade_arguments.dart';
import 'package:argbcontrol_app/services/ws_client.dart';
import 'package:flutter/material.dart';
import 'package:argbcontrol_app/models/message_builder.dart';

class FadePage extends StatefulWidget {
  const FadePage({super.key, required this.wsClient});

  final LedWebSocketClient wsClient;

  @override
  _FadePageState createState() => _FadePageState();
}

class _FadePageState extends State<FadePage> {
  double _currentSliderValue = 3;
  FadeArguments _previousArguments = FadeArguments(0, 0);
  bool _appliedInitial = false;

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
      final payload = MessageBuilder.fade(
        increase: arguments.increase,
        delay: arguments.delay,
      );
      widget.wsClient.sendUserMessage(payload);
      _previousArguments = arguments;
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
    if (s == null || s.mode != 1) return;
    // Mapear delay-> slider aproximado
    final int delay = s.fadeDelay ?? 0;
    // Inverter usando heurística das faixas definidas no cálculo
    int speed = 3;
    if (delay >= 200) speed = 1;
    else if (delay >= 120) speed = 2;
    else if (delay >= 60) speed = 3;
    else if (delay >= 20 && delay < 60) speed = 4;
    else if (delay >= 40) speed = 5; // coberto acima
    else if (delay >= 25) speed = 6;
    else if (delay >= 10) speed = 7;
    else if (delay >= 0) speed = 10;
    setState(() {
      _currentSliderValue = speed.toDouble();
      _previousArguments = _calculateSpeed(speed);
    });
    _appliedInitial = true;
  }
}
