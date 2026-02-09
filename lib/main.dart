import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'services/websocket_service.dart';
import 'utils/token_manager.dart';

const serverHost = "srv1.franciscosantos.net:5000";
const clientId = "6GE7BnevZEqDnnc7hcz2bA";
const clientSecret = "9a02d1e835264f6fa7f3d0ede49cea5a";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final wsScheme = 'ws://';
  final tokenManager = TokenManager(
    serverHost: serverHost,
    clientId: clientId,
    clientSecret: clientSecret,
  );

  // Cria o serviço WebSocket com provider de URI
  final wsService = WebSocketService(
    uriProvider: () async {
      final tokenInfo = await tokenManager.getValidToken();
      return Uri.parse(
        '$wsScheme$serverHost/?client_id=$clientId&access_token=${tokenInfo.token}',
      );
    },
  );

  // Inicia conexão
  wsService.connect();

  runApp(MyApp(wsService: wsService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.wsService});

  final WebSocketService wsService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WebSocketService>.value(
      value: wsService,
      child: MaterialApp(
        title: 'LED Controller',
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
        home: const HomePage(),
      ),
    );
  }
}
