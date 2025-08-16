import 'package:argbcontrol_app/pages/home_page.dart';
import 'package:argbcontrol_app/utils/screen_arguments.dart';
import 'package:argbcontrol_app/utils/websocket.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key, required this.client});

  static const routeName = '/LoadingPage';
  final WebSocket client;

  @override
  _LoadingPage createState() => _LoadingPage();
}

class _LoadingPage extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => waitConnection());
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
        Text(
          "Tentando conectar ao servidor...",
          style: TextStyle(color: Colors.white, fontSize: 10),
        )
      ],
    ));
  }

  void waitConnection() async {
    if (!mounted) return;
    Future.delayed(
      const Duration(seconds: 1),
      (() {
        if (!mounted) return;
        if (widget.client.isWebsocketRunning()) {
          Navigator.pushReplacementNamed(context, HomePage.routeName,
              arguments: ScreenArguments(
                  widget.client, widget.client.getLastMessage()));
        } else {
          waitConnection();
        }
      }),
    );
  }
}
