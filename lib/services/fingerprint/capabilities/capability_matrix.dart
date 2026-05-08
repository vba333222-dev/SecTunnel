import 'package:sec_tunnel/models/identity/master_identity.dart';

class CapabilityMatrix {
  final MasterIdentity identity;

  CapabilityMatrix(this.identity);

  /// Returns the font list and metrics coherence for the OS.
  Map<String, dynamic> getFontCapabilities() {
    if (identity.platform.os == 'Android') {
      return {
        'defaultFont': 'Roboto',
        'availableFonts': ['Roboto', 'Noto Sans', 'Droid Sans'],
        'metricCoherence': 1.0,
      };
    } else if (identity.platform.os == 'Windows') {
      return {
        'defaultFont': 'Segoe UI',
        'availableFonts': ['Segoe UI', 'Arial', 'Times New Roman', 'Consolas', 'Verdana'],
        'metricCoherence': 0.95,
      };
    }
    return {
      'defaultFont': 'Sans-Serif',
      'availableFonts': ['Arial', 'Helvetica'],
      'metricCoherence': 0.8,
    };
  }

  /// Returns WebGL capabilities based on GPU and Engine.
  Map<String, dynamic> getWebGLCapabilities() {
    final gpu = identity.hardware.gpu;
    return {
      'vendor': gpu.vendor,
      'renderer': gpu.renderer,
      'extensions': gpu.extensions,
      'limits': {
        'MAX_TEXTURE_SIZE': gpu.limits['MAX_TEXTURE_SIZE'] ?? 8192,
        'MAX_VIEWPORT_DIMS': gpu.limits['MAX_VIEWPORT_DIMS'] ?? [8192, 8192],
        'ALIASED_LINE_WIDTH_RANGE': [1, 1],
        'ALIASED_POINT_SIZE_RANGE': [1, 1024],
      },
      'shaderPrecision': _getShaderPrecisionForGpu(gpu.vendor),
    };
  }

  Map<String, dynamic> _getShaderPrecisionForGpu(String vendor) {
    if (vendor.contains('Google') || vendor.contains('NVIDIA')) {
      return {
        'vertex': {'high': [23, 127], 'medium': [23, 127], 'low': [23, 127]},
        'fragment': {'high': [23, 127], 'medium': [23, 127], 'low': [23, 127]},
      };
    }
    // Mobile GPUs often have lower fragment precision
    return {
      'vertex': {'high': [23, 127], 'medium': [23, 127], 'low': [23, 127]},
      'fragment': {'high': [23, 127], 'medium': [10, 15], 'low': [10, 15]},
    };
  }

  /// Returns Media/Codec capabilities.
  Map<String, dynamic> getMediaCapabilities() {
    return {
      'videoCodecs': identity.platform.isMobile 
          ? ['video/mp4', 'video/webm; codecs="vp8"'] 
          : ['video/mp4', 'video/webm', 'video/ogg'],
      'audioCodecs': ['audio/mpeg', 'audio/ogg', 'audio/wav'],
      'mediaDevices': identity.platform.isMobile ? 2 : 1, // Cameras
    };
  }
}
