import 'package:flutter/material.dart';

/// Badge widget for showing notification counts
class Badge extends StatelessWidget {
  final Widget child;
  final String? count;
  final bool showZero;

  const Badge({
    super.key,
    required this.child,
    this.count,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == null || (count == "0" && !showZero)) {
      return child;
    }

    final countInt = int.tryParse(count ?? "0") ?? 0;
    final displayCount = countInt > 99 ? "99+" : count;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: countInt > 9 ? 6 : 4,
              vertical: 4,
            ),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              displayCount!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
