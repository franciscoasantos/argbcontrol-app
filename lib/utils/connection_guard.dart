import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:argbcontrol_app/services/websocket_service.dart';

class ConnectionGuard extends StatelessWidget {
  const ConnectionGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketService>(
      builder: (context, wsService, _) {
        final connected = wsService.isConnected;

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
                        const Text(
                          'Reconectando...',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => wsService.reconnect(),
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
