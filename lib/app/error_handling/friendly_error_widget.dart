import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FriendlyErrorWidget extends StatelessWidget {
  static const String _message = 'This section could not be displayed.';
  static const double _padding = 16;
  static const double _iconSize = 32;
  static const Color _foregroundColor = Color(0xFFB71C1C);
  static const Color _backgroundColor = Color(0xFFFFEBEE);

  final FlutterErrorDetails details;

  const FriendlyErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _foregroundColor, size: _iconSize),
              const Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(color: _foregroundColor, fontWeight: FontWeight.w600),
              ),
              if (kDebugMode)
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _foregroundColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
