import 'package:flutter/material.dart';
 
import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'utils/websocket.dart';

void main() {
  final wsClient =
      WebSocket('ws://services.franciscosantos.net:5000/?socketId=d8455cdd6f2a4d9bb49c41b3909f1fe3&clientId=8b0e0a0117ee4a7a999958fa1a592ead');
      wsClient.startStream();
  runApp(
    MaterialApp(initialRoute: LoadingPage.routeName, routes: {
      LoadingPage.routeName: (context) => LoadingPage(client: wsClient),
      HomePage.routeName: (context) => HomePage(client: wsClient)
    }),
  );
}
