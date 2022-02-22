import 'package:ledcontroller/pages/static_page.dart';
import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';

import 'fade_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.client}) : super(key: key);

  final WebSocket client;

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              controller: _controller,
              indicatorColor: Colors.amberAccent,
              tabs: const [
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
            controller: _controller,
            children: [
              StaticPage(wsClient: widget.client),
              FadePage(wsClient: widget.client)
            ],
          ),
        ),
      ),
    );
  }
}
