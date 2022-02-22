import 'dart:developer';

import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key, required this.client}) : super(key: key);

  final WebSocket client;

  @override
  _LoadingPage createState() => _LoadingPage();
}

class _LoadingPage extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => verifyConnection());
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

  void verifyConnection() async {
    Future.delayed(const Duration(seconds: 1), (() {
      log("verificando...");
      if (widget.client.isConnected()) {
        Navigator.pushNamed(context, '/home');
      } else {
        verifyConnection();
      }
    }));
  }
}
