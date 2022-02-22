import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'utils/websocket.dart';

void main() {
  final WebSocket wsClient =
      WebSocket('ws://services.franciscosantos.net:3000/?clientId=1');
  runApp(
    MaterialApp(initialRoute: '/', routes: {
      '/': (context) => LoadingPage(client: wsClient),
      '/home': (context) => HomePage(client: wsClient)
    }),
  );
}
