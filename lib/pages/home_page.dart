import 'package:argbcontrol_app/pages/rainbow_page.dart';
import 'package:argbcontrol_app/pages/static_page.dart';
import 'package:argbcontrol_app/services/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'fade_page.dart';
import 'package:argbcontrol_app/utils/connection_guard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime? _lastResumeTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);

    // Listener para atualizar UI quando muda de aba
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Listener para mudanças de status do WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsService = context.read<WebSocketService>();
      wsService.addListener(_onWebSocketStatusChanged);
      _syncTabWithStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final wsService = context.read<WebSocketService>();
    wsService.removeListener(_onWebSocketStatusChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() {
    // Debounce: evita múltiplas reconexões se o evento vier muito rápido
    final now = DateTime.now();
    if (_lastResumeTime != null &&
        now.difference(_lastResumeTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastResumeTime = now;

    // Aguarda app estabilizar e então reconecta se necessário
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final wsService = context.read<WebSocketService>();
      if (!wsService.isConnected) {
        wsService.reconnect();
      }
    });
  }

  void _onWebSocketStatusChanged() {
    if (!mounted) return;
    _syncTabWithStatus();
  }

  void _syncTabWithStatus() {
    final wsService = context.read<WebSocketService>();
    final status = wsService.currentStatus;

    if (status != null &&
        status.mode >= 0 &&
        status.mode < _tabController.length) {
      if (_tabController.index != status.mode) {
        _tabController.animateTo(status.mode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _ConnectionAppBarTitle(),
        actions: const [_PowerButton(), SizedBox(width: 8)],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ConnectionGuard(child: StaticPage()),
          ConnectionGuard(child: FadePage()),
          ConnectionGuard(child: RainbowPage()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabController.index,
        onDestinationSelected: (index) => _tabController.animateTo(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            label: 'Static',
          ),
          NavigationDestination(icon: Icon(Icons.sync), label: 'Fade'),
          NavigationDestination(icon: Icon(Icons.flash_on), label: 'Rainbow'),
        ],
      ),
    );
  }
}

class _ConnectionAppBarTitle extends StatelessWidget {
  const _ConnectionAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketService>(
      builder: (context, wsService, _) {
        final connected = wsService.isConnected;
        return Row(
          children: [
            const Text('LED Controller'),
            const SizedBox(width: 12),
            InputChip(
              label: Text(connected ? 'Conectado' : 'Reconectando...'),
              avatar: Icon(
                connected ? Icons.check_circle : Icons.wifi_off,
                color: connected ? Colors.greenAccent : Colors.orangeAccent,
                size: 18,
              ),
              onPressed: () {
                if (!connected) {
                  wsService.reconnect();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _PowerButton extends StatefulWidget {
  const _PowerButton();

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> {
  bool _isOn = true;

  @override
  Widget build(BuildContext context) {
    final wsService = context.read<WebSocketService>();

    return IconButton(
      tooltip: _isOn ? 'Desligar' : 'Ligar',
      icon: Icon(_isOn ? Icons.power_settings_new : Icons.power),
      onPressed: () {
        setState(() => _isOn = !_isOn);

        if (_isOn) {
          // Restaura última mensagem não-off
          final restore = wsService.lastNonOffSentMessage;
          if (restore != null) {
            wsService.sendMessage(restore);
          }
        } else {
          // Desliga (todos os canais em 0)
          wsService.sendMessage(
            '{"M": "0", "R": "0", "G": "0", "B": "0", "W": "0"}',
            isPowerOff: true,
          );
        }
      },
    );
  }
}
