import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LedController',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(title: 'Escolha uma cor'),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _channel = WebSocketChannel.connect(
      Uri.parse('ws://services.franciscosantos.net:3000/?clientId=1'));
  Color _currentColor = Colors.blue;
  Color _oldColor = Colors.black;
  final _controller = CircleColorPickerController(
    initialColor: Colors.blue,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _currentColor,
          title: Text(widget.title),
        ),
        body: Container(
          decoration: const BoxDecoration(color: Colors.black12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 48),
              Center(
                child: CircleColorPicker(
                  controller: _controller,
                  size: const Size(300, 300),
                  strokeWidth: 8,
                  thumbSize: 40,
                  onChanged: (color) {
                    setState(() => _currentColor = color);
                    _sendMessage(color);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage(Color color) {
    if (color != _oldColor) {
      int R = color.red;
      int G = color.green;
      int B = color.blue;
      _channel.sink.add('{"R": "${R}", "G": "${G}", "B": "${B}"}');
    }
    _oldColor = color;
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
