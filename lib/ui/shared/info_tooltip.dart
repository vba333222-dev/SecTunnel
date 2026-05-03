import 'package:flutter/material.dart';

/// A reusable tooltip widget designed to explain complex terminology 
/// to non-expert users in the PBrowser application.
/// It displays a faded question mark icon that, when tapped or hovered over,
/// shows a styled Material tooltip with educational microcopy.
class InfoTooltipWidget extends StatelessWidget {
  /// The educational text to display inside the tooltip.
  final String message;
  
  /// Optional custom icon, defaults to a faded outline question mark.
  final IconData icon;

  /// Optional icon size, defaults to 16.
  final double iconSize;

  const InfoTooltipWidget({
    super.key,
    required this.message,
    this.icon = Icons.help_outline_rounded,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A35).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 6, right: 2),
        // Faded icon to prevent visual clutter
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
