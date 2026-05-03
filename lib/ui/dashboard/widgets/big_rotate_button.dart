import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sec_tunnel/services/proxy/modem_rotator_service.dart';

class BigRotateButton extends StatefulWidget {
  final String profileId;
  final VoidCallback onRotate;
  final VoidCallback onLaunchBrowser;

  const BigRotateButton({
    super.key,
    required this.profileId,
    required this.onRotate,
    required this.onLaunchBrowser,
  });

  @override
  State<BigRotateButton> createState() => _BigRotateButtonState();
}

class _BigRotateButtonState extends State<BigRotateButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final rotator = context.watch<ModemRotatorService>();
    final state = rotator.getState(widget.profileId);
    final isCoolingDown = rotator.isCoolingDown(widget.profileId);
    final cooldownSeconds = rotator.getRemainingCooldownSeconds(widget.profileId);

    // Determine colors and text based on state
    Color bgColor = Colors.blue[600]!;
    Color fgColor = Colors.white;
    String text = 'Rotate IP & Connect';
    IconData icon = Icons.sync;
    bool isBusy = false;

    if (state == RotationState.connecting ||
        state == RotationState.rotating ||
        state == RotationState.validating) {
      bgColor = Colors.blue[400]!;
      if (state == RotationState.connecting) {
        text = 'Connecting...';
      } else if (state == RotationState.rotating) {
        text = 'Acquiring IP...';
      } else if (state == RotationState.validating) {
        text = 'Validating Network...';
      }
      isBusy = true;
    } else if (state == RotationState.success) {
      bgColor = Colors.green[600]!;
      fgColor = Colors.white;
      text = 'Launch Browser';
      icon = Icons.open_in_browser;
    } else if (state == RotationState.failed) {
      bgColor = Colors.red[600]!;
      fgColor = Colors.white;
      text = 'Rotation Failed - Retry';
      icon = Icons.error_outline;
    }

    if (isCoolingDown && !isBusy) {
      bgColor = Colors.grey[300]!;
      fgColor = Colors.grey[600]!;
      text = 'Cooling Down ($cooldownSeconds s)';
      icon = Icons.ac_unit;
      isBusy = true; // prevent clicks
    }

    return AnimatedScale(
      scale: _isPressed && !isBusy ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isBusy && state != RotationState.success)
              BoxShadow(
                color: bgColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) {
              if (!isBusy) setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              if (!isBusy) setState(() => _isPressed = false);
            },
            onTapCancel: () {
              if (!isBusy) setState(() => _isPressed = false);
            },
            onTap: isBusy
                ? null
                : () {
                    if (state == RotationState.success) {
                      widget.onLaunchBrowser();
                    } else {
                      widget.onRotate();
                    }
                  },
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBusy)
                    const _DelayedSpinner()
                  else
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Icon(icon, key: ValueKey<IconData>(icon), color: fgColor, size: 28),
                    ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      text,
                      key: ValueKey<String>('$state$text$isCoolingDown$cooldownSeconds'),
                      style: TextStyle(
                        color: fgColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DelayedSpinner extends StatefulWidget {
  const _DelayedSpinner();

  @override
  State<_DelayedSpinner> createState() => _DelayedSpinnerState();
}

class _DelayedSpinnerState extends State<_DelayedSpinner> {
  bool _show = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
