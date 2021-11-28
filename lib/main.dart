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
    initialColor: const Color.fromARGB(255, 0, 0, 255),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _currentColor,
          title: Text(widget.title),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 48),
            Center(
              child: CircleColorPicker(
                controller: _controller,
                size: const Size(300, 300),
                strokeWidth: 5,
                thumbSize: 40,
                onChanged: (color) {
                  setState(() => _currentColor = color);
                  _sendMessage(color);
                },
              ),
            ),
            const SizedBox(height: 48),
            StreamBuilder(
              stream: _channel.stream,
              builder: (context, snapshot) {
                return Text(snapshot.hasData
                    ? _messageToJSON(snapshot.data.toString())
                    : '');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(Color color) {
    if (color != _oldColor) {
      int R = color.red;
      int G = color.green;
      int B = color.blue;
      _channel.sink.add('{"M": "0", "R": "$R", "G": "$G", "B": "$B"}');
    }
    _oldColor = color;
  }

  String _messageToJSON(String message) {
    String M = message.substring(0, 1);
    String R = message.substring(1, 4);
    String G = message.substring(4, 7);
    String B = message.substring(7, 10);

    return '{"M": "$M", "R": "$R", "G": "$G", "B": "$B"}';
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
