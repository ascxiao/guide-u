import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/connectivity_view_model.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool? _lastOnline;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityViewModel>(
      builder: (context, connectivity, _) {
        final isOnline = connectivity.isOnline;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_lastOnline != null && _lastOnline != isOnline) {
            final message = isOnline ? "You're online" : "You're offline!";
            final color = isOnline ? Colors.green : Colors.red;
            final messenger = appScaffoldMessengerKey.currentState;
            if (messenger == null) {
              _lastOnline = isOnline;
              return;
            }

            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: color,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
          _lastOnline = isOnline;
        });
        return const SizedBox.shrink();
      },
    );
  }
}
