import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/ws_client.dart';
import 'utils/token_manager.dart';
 

const serverHost = "51.222.139.201:5000";
const clientId = "6GE7BnevZEqDnnc7hcz2bA";
const clientSecret = "9a02d1e835264f6fa7f3d0ede49cea5a";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenInfo = await TokenManager(
    serverHost: serverHost,
    clientId: clientId,
    clientSecret: clientSecret,
  ).getValidToken();

  final wsScheme = 'ws://';
  final wsClient = LedWebSocketClient(
      '$wsScheme$serverHost/?client_id=$clientId&access_token=${tokenInfo.token}');

  wsClient.startStream();

  runApp(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      initialRoute: HomePage.routeName,
      routes: {
        HomePage.routeName: (context) => HomePage(client: wsClient)
      },
    ),
  );
}
