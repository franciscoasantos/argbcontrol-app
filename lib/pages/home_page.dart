import 'package:argbcontrol_app/pages/rainbow_page.dart';
import 'package:argbcontrol_app/pages/static_page.dart';
import 'package:argbcontrol_app/services/ws_client.dart';
import 'package:flutter/material.dart';

import 'fade_page.dart';
import 'package:argbcontrol_app/utils/connection_guard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.client});

  static const routeName = '/home';
  final LedWebSocketClient client;

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _controller;
  bool _didAnimateFromArgs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TabController(length: 3, vsync: this);
    widget.client.statusListenable.addListener(_onStatusUpdate);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAnimateFromArgs) return;
    // Sem tela de loading: tenta animar com base na última mensagem conhecida
    final String msg = widget.client.getLastMessage();
    int index = 0;
    if (msg.isNotEmpty) {
      final int? parsed = int.tryParse(msg[0]);
      if (parsed != null && parsed >= 0 && parsed < _controller.length) {
        index = parsed;
      }
    }
    _controller.animateTo(index);
    _didAnimateFromArgs = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.client.statusListenable.removeListener(_onStatusUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.client.ensureConnected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _ConnectionAppBarTitle(client: widget.client),
        actions: [
          _PowerButton(client: widget.client),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          ConnectionGuard(
              client: widget.client, child: StaticPage(wsClient: widget.client)),
          ConnectionGuard(
              client: widget.client, child: FadePage(wsClient: widget.client)),
          ConnectionGuard(
              client: widget.client, child: RainbowPage(wsClient: widget.client)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _controller.index,
        onDestinationSelected: (index) => _controller.animateTo(index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.palette_outlined), label: 'Static'),
          NavigationDestination(icon: Icon(Icons.sync), label: 'Fade'),
          NavigationDestination(
              icon: Icon(Icons.flash_on), label: 'Rainbow'),
        ],
      ),
    );
  }

  void _onStatusUpdate() {
    final status = widget.client.statusListenable.value;
    if (status == null) return;
    final int mode = status.mode;
    if (mode >= 0 && mode < _controller.length) {
      _controller.animateTo(mode);
    }
  }
}

class _ConnectionAppBarTitle extends StatelessWidget {
  const _ConnectionAppBarTitle({required this.client});
  final LedWebSocketClient client;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: client.connectionListenable,
      builder: (context, connected, _) {
        return Row(
          children: [
            const Text('LedController'),
            const SizedBox(width: 12),
            InputChip(
              label: Text(connected ? 'Conectado' : 'Reconectando...'),
              avatar: Icon(
                connected ? Icons.check_circle : Icons.wifi_off,
                color: connected ? Colors.greenAccent : Colors.orangeAccent,
                size: 18,
              ),
              onPressed: client.ensureConnected,
            )
          ],
        );
      },
    );
  }
}

class _PowerButton extends StatefulWidget {
  const _PowerButton({required this.client});
  final LedWebSocketClient client;

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> {
  bool _isOn = true;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _isOn ? 'Desligar' : 'Ligar',
      icon: Icon(_isOn ? Icons.power_settings_new : Icons.power),
      onPressed: () {
        setState(() => _isOn = !_isOn);
        if (_isOn) {
          final restore = widget.client.getLastNonOffSentMessage();
          if (restore != null) {
            widget.client.sendMessage(restore);
          }
        } else {
          widget.client.sendUserMessage(
            '{"M": "0", "R": "0", "G": "0", "B": "0", "W": "0"}',
            isPowerOff: true,
          );
        }
      },
    );
  }
}
