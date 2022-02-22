import 'package:ledcontroller/pages/static_page.dart';
import 'package:ledcontroller/utils/websocket.dart';
import 'package:flutter/material.dart';

import '../utils/screen_arguments.dart';
import 'fade_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.client}) : super(key: key);

  static const routeName = '/home';
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
    final args = ModalRoute.of(context)!.settings.arguments as ScreenArguments;
    _controller.animateTo(int.parse(args.lastMessage.substring(0,1)));

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
