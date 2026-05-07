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
  final bool hasConnectionError;
  final int? lastErrorCode;
  final String? errorReason;
  final bool isDownloading;
  final double downloadProgress;
  final String? downloadFileName;

  const BrowserState({
    this.isLoading = true,
    this.isWebViewLoading = false,
    this.isControllerInitialized = false,
    this.isProxyHealthy = true,
    this.progress = 0.0,
    this.currentUrl = 'https://www.startpage.com/',
    this.currentPublicIp,
    this.isIpFetching = false,
    this.isRotating = false,
    this.hudExpanded = false,
    this.errorReason,
    this.hasConnectionError = false,
    this.lastErrorCode,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.downloadFileName,
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
    bool? hasConnectionError,
    int? lastErrorCode,
    bool? isDownloading,
    double? downloadProgress,
    String? downloadFileName,
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
      hasConnectionError: hasConnectionError ?? this.hasConnectionError,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadFileName: downloadFileName ?? this.downloadFileName,
    );
  }
}
