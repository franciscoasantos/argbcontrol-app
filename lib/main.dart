import 'package:appflutter/websocket.dart';
import 'package:flutter/material.dart';

import 'static_page.dart';
import 'fade_page.dart';

void main() {
  runApp(
    const MaterialApp(
      home: HomePage(),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static WebSocket client = WebSocket();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.flash_on),
                  text: 'Static',
                ),
                Tab(
                  icon: Icon(Icons.sync),
                  text: 'Fade',
                )
              ],
            ),
            title: const Text('LedController'),
          ),
          body: TabBarView(
            children: [
              StaticPage(wsClient: client),
              FadePage(wsClient: client)
            ],
          ),
        ),
      ),
    );
  }
}
