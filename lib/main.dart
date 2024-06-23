import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'utils/websocket.dart';

const serverHost = "51.222.139.201:5000";
const clientId = "6GE7BnevZEqDnnc7hcz2bA";
const clientSecret = "9a02d1e835264f6fa7f3d0ede49cea5a";

Future<void> main() async {
  var token = await http.read(Uri.http(serverHost, '/api/token'),
      headers: {"X-Client-Id": clientId, "X-Client-Secret": clientSecret});

  final wsClient =
      WebSocket('ws://$serverHost/?client_id=$clientId&access_token=$token');

  wsClient.startStream();

  runApp(
    MaterialApp(initialRoute: LoadingPage.routeName, routes: {
      LoadingPage.routeName: (context) => LoadingPage(client: wsClient),
      HomePage.routeName: (context) => HomePage(client: wsClient)
    }),
  );
}
