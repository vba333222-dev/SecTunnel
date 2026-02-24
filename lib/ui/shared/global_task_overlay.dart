import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbrowser/services/proxy/modem_rotator_service.dart';

class GlobalTaskOverlay extends StatelessWidget {
  final Widget child;

  const GlobalTaskOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 30, // Hover above safe area
          child: Consumer<ModemRotatorService>(
            builder: (context, service, _) {
              final isVisible = service.targetProfileName != null;
              final isRotating = service.isRotating;
              final hasError = service.errorMessage != null;

              return AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                offset: isVisible ? Offset.zero : const Offset(0, 2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isVisible ? 1.0 : 0.0,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161F).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasError
                              ? Colors.redAccent.withValues(alpha: 0.5)
                              : isRotating
                                  ? Colors.tealAccent.withValues(alpha: 0.3)
                                  : Colors.greenAccent.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRotating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.tealAccent,
                              ),
                            )
                          else if (hasError)
                            const Icon(Icons.error_outline, size: 18, color: Colors.redAccent)
                          else
                            const Icon(Icons.check_circle_outline, size: 18, color: Colors.greenAccent),
                          
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              isRotating
                                  ? 'Rotating IP: \${service.targetProfileName}...'
                                  : hasError
                                      ? 'Rotation Failed: \${service.targetProfileName}'
                                      : 'Rotation Complete: \${service.targetProfileName}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
