import 'package:flutter/material.dart';
import '../../../game/config/game_config.dart';

/// Contextual pilot & base station radio chatter overlay.
class RadioChatterOverlay extends StatelessWidget {
  final String? message;
  final String sender;

  const RadioChatterOverlay({
    super.key,
    required this.message,
    this.sender = 'BASE-COMM',
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD0F1218),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameConfig.colorPrimary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: GameConfig.colorPrimary.withOpacity(0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: GameConfig.colorPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.radio_rounded, color: GameConfig.colorPrimary, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '[$sender // 142.8 MHz]',
                      style: const TextStyle(
                        color: GameConfig.colorPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
