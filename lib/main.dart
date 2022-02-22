import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'utils/websocket.dart';

void main() {
  final WebSocket wsClient =
      WebSocket('ws://services.franciscosantos.net:3000/?clientId=1');
  runApp(
    MaterialApp(initialRoute: LoadingPage.routeName, routes: {
      LoadingPage.routeName: (context) => LoadingPage(client: wsClient),
      HomePage.routeName: (context) => HomePage(client: wsClient)
    }),
  );
}
