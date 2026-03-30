import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/connectivity_view_model.dart';

class InternetRequiredNotice extends StatelessWidget {
  final String featureName;

  const InternetRequiredNotice({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityViewModel>().isOnline;
    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.wifi_off, color: Color(0xFF8A6D3B), size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$featureName requires an internet connection to work properly.',
              style: const TextStyle(
                color: Color(0xFF8A6D3B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
