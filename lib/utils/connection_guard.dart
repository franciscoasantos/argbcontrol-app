import 'package:flutter/material.dart';
import 'package:argbcontrol_app/services/ws_client.dart';

class ConnectionGuard extends StatelessWidget {
  const ConnectionGuard({super.key, required this.client, required this.child});

  final LedWebSocketClient client;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: client.connectionListenable,
      builder: (context, connected, _) {
        return Stack(
          children: [
            AbsorbPointer(absorbing: !connected, child: child),
            if (!connected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text('Reconectando...', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: client.ensureConnected,
                          icon: const Icon(Icons.wifi),
                          label: const Text('Tentar agora'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}


