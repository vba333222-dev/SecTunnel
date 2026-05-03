import 'package:flutter/foundation.dart';

@immutable
class BrowserState {
  final bool isLoading;
  final bool isWebViewLoading;
  final bool isControllerInitialized;
  final bool isProxyHealthy;
  final double progress;
  final String currentUrl;
  final String? currentPublicIp;
  final bool isIpFetching;
  final bool isRotating;
  final bool hudExpanded;
  final String? errorReason;

  const BrowserState({
    this.isLoading = true,
    this.isWebViewLoading = false,
    this.isControllerInitialized = false,
    this.isProxyHealthy = true,
    this.progress = 0.0,
    this.currentUrl = 'https://duckduckgo.com',
    this.currentPublicIp,
    this.isIpFetching = false,
    this.isRotating = false,
    this.hudExpanded = false,
    this.errorReason,
  });

  BrowserState copyWith({
    bool? isLoading,
    bool? isWebViewLoading,
    bool? isControllerInitialized,
    bool? isProxyHealthy,
    double? progress,
    String? currentUrl,
    String? currentPublicIp,
    bool? isIpFetching,
    bool? isRotating,
    bool? hudExpanded,
    String? errorReason,
  }) {
    return BrowserState(
      isLoading: isLoading ?? this.isLoading,
      isWebViewLoading: isWebViewLoading ?? this.isWebViewLoading,
      isControllerInitialized: isControllerInitialized ?? this.isControllerInitialized,
      isProxyHealthy: isProxyHealthy ?? this.isProxyHealthy,
      progress: progress ?? this.progress,
      currentUrl: currentUrl ?? this.currentUrl,
      currentPublicIp: currentPublicIp ?? this.currentPublicIp,
      isIpFetching: isIpFetching ?? this.isIpFetching,
      isRotating: isRotating ?? this.isRotating,
      hudExpanded: hudExpanded ?? this.hudExpanded,
      errorReason: errorReason ?? this.errorReason,
    );
  }
}
