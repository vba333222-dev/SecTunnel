import 'package:flutter/material.dart';

class GlobalTaskOverlay extends StatelessWidget {
  final Widget child;

  const GlobalTaskOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Notification/Snackbar overlay removed as per user request
      ],
    );
  }
}
