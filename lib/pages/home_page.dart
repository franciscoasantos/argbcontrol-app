import 'package:argbcontrol_app/pages/rainbow_page.dart';
import 'package:argbcontrol_app/pages/static_page.dart';
import 'package:argbcontrol_app/utils/websocket.dart';
import 'package:flutter/material.dart';

import '../utils/screen_arguments.dart';
import 'fade_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.client});

  static const routeName = '/home';
  final WebSocket client;

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _controller;
  bool _didAnimateFromArgs = false;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAnimateFromArgs) return;
    final route = ModalRoute.of(context);
    final Object? args = route?.settings.arguments;
    if (args is ScreenArguments) {
      final String msg = args.lastMessage;
      int index = 0;
      if (msg.isNotEmpty) {
        final int? parsed = int.tryParse(msg[0]);
        if (parsed != null && parsed >= 0 && parsed < _controller.length) {
          index = parsed;
        }
      }
      _controller.animateTo(index);
    }
    _didAnimateFromArgs = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _controller,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(
              icon: Icon(Icons.palette_outlined),
              text: 'Static',
            ),
            Tab(
              icon: Icon(Icons.sync),
              text: 'Fade',
            ),
            Tab(
              icon: Icon(Icons.flash_on),
              text: 'Rainbow',
            )
          ],
        ),
        title: const Text('LedController'),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          StaticPage(wsClient: widget.client),
          FadePage(wsClient: widget.client),
          RainbowPage(wsClient: widget.client)
        ],
      ),
    );
  }
}
