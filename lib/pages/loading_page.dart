import 'package:ledcontroller/pages/home_page.dart';
import 'package:ledcontroller/utils/screen_arguments.dart';
import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key, required this.client}) : super(key: key);

  static const routeName = '/LoadingPage';
  final WebSocket client;

  @override
  _LoadingPage createState() => _LoadingPage();
}

class _LoadingPage extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => waitConnection());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(child: CircularProgressIndicator(), width: 32, height: 32),
        Text(
          "Tentando conectar ao servidor...",
          style: TextStyle(color: Colors.white, fontSize: 10),
        )
      ],
    ));
  }

  void waitConnection() async {
    Future.delayed(
      const Duration(seconds: 1),
      (() {
        if (widget.client.isWebsocketRunning()) {
          Navigator.pushNamed(context, HomePage.routeName,
              arguments: ScreenArguments(
                  widget.client, widget.client.getLastMessage()));
        } else {
          waitConnection();
        }
      }),
    );
  }
}
