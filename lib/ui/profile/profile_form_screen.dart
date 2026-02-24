import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:pbrowser/ui/dashboard/widgets/profile_card.dart';
import 'package:pbrowser/ui/shared/info_tooltip.dart';

// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────

class ProfileFormScreen extends StatefulWidget {
  final ProfileRepository repository;
  final BrowserProfile? existingProfile;

  const ProfileFormScreen({
    super.key,
    required this.repository,
    this.existingProfile,
  });

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen>
    with TickerProviderStateMixin {
  // ── form key ──────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // ── General tab ───────────────────────────
  final _nameController = TextEditingController();
  String _selectedOs = 'Windows';
  String _selectedBrowser = 'Chrome';
  final _uaController = TextEditingController();
  bool _uaManualOverride = false;
  // ── Tags ───────────────────────────────────────────────
  List<String> _tags = [];
  final _tagInputController = TextEditingController();

  // ── Network tab ───────────────────────────
  ProxyType _selectedProxyType = ProxyType.none;
  final _proxyHostController = TextEditingController();
  final _proxyPortController = TextEditingController();
  final _proxyUsernameController = TextEditingController();
  final _proxyPasswordController = TextEditingController();
  final _proxyRotationUrlController = TextEditingController();
  bool _webrtcEnabled = true;

  // ── Hardware tab ──────────────────────────
  String _webglVendor = '';
  String _webglRenderer = '';
  final _canvasSaltController = TextEditingController();
  int _screenWidth = 1920;
  int _screenHeight = 1080;
  int _colorDepth = 24;
  int _hardwareConcurrency = 8;
  int _deviceMemory = 8;

  // ── Advanced tab ──────────────────────────
  String _timezone = 'Asia/Jakarta';
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _accuracyController = TextEditingController();
  bool _geoEnabled = false;
  final _customDnsController = TextEditingController();

  // ── loading ───────────────────────────────
  bool _isLoading = false;

  // ── Sparkle animation (triggered on random fingerprint) ──────────────
  late final AnimationController _sparkleController;
  bool _showSparkle = false;

  // ── Lookup maps ───────────────────────────
  static const _osList = [
    'Windows',
    'macOS',
    'Linux',
    'Android',
    'iOS',
  ];
  static const _browserList = [
    'Chrome',
    'Firefox',
    'Safari',
    'Edge',
  ];
  static const _timezones = [
    'Asia/Jakarta',
    'Asia/Singapore',
    'Asia/Tokyo',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Berlin',
    'Australia/Sydney',
  ];
  static const _resolutions = [
    '1920×1080',
    '2560×1440',
    '1366×768',
    '1280×800',
    '3840×2160',
    '390×844',
    '414×896',
    '360×800',
  ];
  static const _cpuOptions = [2, 4, 6, 8, 12, 16];
  static const _ramOptions = [2, 4, 6, 8, 16, 32];
  static const _webglOptions = [
    'Google Inc. (NVIDIA)|ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0)',
    'Google Inc. (AMD)|ANGLE (AMD, AMD Radeon RX 6700 XT Direct3D11 vs_5_0 ps_5_0)',
    'Google Inc. (Intel)|ANGLE (Intel, Intel(R) UHD Graphics 630 Direct3D11 vs_5_0 ps_5_0)',
    'Apple Inc.|Apple GPU',
    'Qualcomm|Adreno (TM) 650',
  ];

  // ──────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.existingProfile != null) {
      _populateFromProfile(widget.existingProfile!);
    } else {
      _applyRandomFingerprint(FingerprintConfig.random());
    }
  }

  void _populateFromProfile(BrowserProfile p) {
    final f = p.fingerprintConfig;
    final proxy = p.proxyConfig;

    // General
    _nameController.text = p.name;
    _uaController.text = f.userAgent;
    _uaManualOverride = true;
    _selectedOs = _detectOs(f.platform);
    _selectedBrowser = _detectBrowser(f.userAgent);
    _tags = List<String>.from(p.tags);

    // Network
    _selectedProxyType = proxy.type;
    _proxyHostController.text = proxy.host ?? '';
    _proxyPortController.text = proxy.port?.toString() ?? '';
    _proxyUsernameController.text = proxy.username ?? '';
    _proxyPasswordController.text = proxy.password ?? '';
    _proxyRotationUrlController.text = proxy.rotationUrl ?? '';
    _webrtcEnabled = f.webrtcEnabled;

    // Hardware
    _webglVendor = f.webglConfig.vendor;
    _webglRenderer = f.webglConfig.renderer;
    _canvasSaltController.text = f.canvasNoiseSalt;
    _screenWidth = f.screenResolution.width;
    _screenHeight = f.screenResolution.height;
    _colorDepth = f.screenResolution.colorDepth;
    _hardwareConcurrency = f.hardwareConcurrency;
    _deviceMemory = f.deviceMemory;

    // Advanced
    _timezone = f.timezone;
    if (f.geolocation != null) {
      _geoEnabled = true;
      _latController.text = f.geolocation!.latitude.toString();
      _lngController.text = f.geolocation!.longitude.toString();
      _accuracyController.text = f.geolocation!.accuracy.toString();
    }
  }

  String _detectOs(String platform) {
    if (platform.contains('Win')) return 'Windows';
    if (platform.contains('Mac')) return 'macOS';
    if (platform.contains('Linux') && !platform.contains('arm')) return 'Linux';
    if (platform.contains('arm') || platform.contains('Android')) {
      return 'Android';
    }
    if (platform.contains('iPhone')) return 'iOS';
    return 'Windows';
  }

  String _detectBrowser(String ua) {
    if (ua.contains('Edg/')) return 'Edge';
    if (ua.contains('Firefox')) return 'Firefox';
    if (ua.contains('Safari') && !ua.contains('Chrome')) return 'Safari';
    return 'Chrome';
  }

  /// Applies a complete FingerprintConfig to all tab controllers.
  void _applyRandomFingerprint(FingerprintConfig f) {
    setState(() {
      _uaManualOverride = false;
      _uaController.text = f.userAgent;
      _selectedOs = _detectOs(f.platform);
      _selectedBrowser = _detectBrowser(f.userAgent);
      _webrtcEnabled = f.webrtcEnabled;
      _webglVendor = f.webglConfig.vendor;
      _webglRenderer = f.webglConfig.renderer;
      _canvasSaltController.text = f.canvasNoiseSalt;
      _screenWidth = f.screenResolution.width;
      _screenHeight = f.screenResolution.height;
      _colorDepth = f.screenResolution.colorDepth;
      _hardwareConcurrency = f.hardwareConcurrency;
      _deviceMemory = f.deviceMemory;
      _timezone = f.timezone;
      // Trigger sparkle burst
      _showSparkle = true;
    });
    _sparkleController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showSparkle = false);
    });
  }

  // ── Anonymity heuristic ───────────────────────────────────────────────
  AnonymityResult _computeAnonymityScore() {
    int score = 100;
    final issues = <String>[];

    // 1. No proxy → real IP exposed
    final hasProxy = _selectedProxyType != ProxyType.none;
    if (!hasProxy) {
      score -= 30;
      issues.add('No proxy — real IP exposed');
    }

    // 2. WebRTC risk
    if (_webrtcEnabled) {
      if (!hasProxy) {
        score -= 15;
        issues.add('WebRTC leaks local IP');
      } else {
        score -= 5;
        issues.add('WebRTC enabled (minor risk)');
      }
    }

    // 3. OS / Resolution mismatch
    //    Mobile OS (Android/iOS) should have narrow resolution (≤500px wide)
    //    Desktop OS should have wide resolution (>600px wide)
    final isMobileOs = _selectedOs == 'Android' || _selectedOs == 'iOS';
    final isMobileRes = _screenWidth <= 500;
    if (isMobileOs && !isMobileRes) {
      score -= 20;
      issues.add('Resolution ≠ OS (mobile OS + desktop res)');
    } else if (!isMobileOs && isMobileRes) {
      score -= 20;
      issues.add('Resolution ≠ OS (desktop OS + mobile res)');
    }

    // 4. WebGL vendor / OS mismatch
    final vendorLower = _webglVendor.toLowerCase();
    final appleGpu = vendorLower.contains('apple');
    final qualcomm = vendorLower.contains('qualcomm') || vendorLower.contains('adreno');
    if (appleGpu && (_selectedOs == 'Windows' || _selectedOs == 'Linux' || _selectedOs == 'Android')) {
      score -= 10;
      issues.add('WebGL vendor/OS mismatch (Apple GPU ≠ $_selectedOs)');
    } else if (qualcomm && (_selectedOs == 'Windows' || _selectedOs == 'macOS' || _selectedOs == 'Linux')) {
      score -= 10;
      issues.add('WebGL vendor/OS mismatch (Qualcomm ≠ $_selectedOs)');
    }

    // 5. Canvas salt too weak
    final salt = _canvasSaltController.text.trim();
    if (salt.length < 8) {
      score -= 10;
      issues.add('Canvas noise salt too weak (< 8 chars)');
    }

    return AnonymityResult(
      score: score.clamp(0, 100),
      issues: issues,
    );
  }

  String _buildUserAgent() {
    if (_uaManualOverride) return _uaController.text.trim();
    // Auto-generate a reasonable UA from OS + Browser selection
    final rng = Random();
    final chromeVersion = 120 + rng.nextInt(6);
    switch ('$_selectedOs|$_selectedBrowser') {
      case 'Windows|Chrome':
        return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromeVersion.0.0.0 Safari/537.36';
      case 'Windows|Edge':
        return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromeVersion.0.0.0 Safari/537.36 Edg/$chromeVersion.0.0.0';
      case 'macOS|Chrome':
        return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromeVersion.0.0.0 Safari/537.36';
      case 'macOS|Safari':
        return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15';
      case 'Linux|Chrome':
        return 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromeVersion.0.0.0 Safari/537.36';
      case 'Linux|Firefox':
        return 'Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0';
      case 'Android|Chrome':
        return 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromeVersion.0.0.0 Mobile Safari/537.36';
      case 'iOS|Safari':
        return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
      default:
        return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$chromeVersion.0.0.0 Safari/537.36';
    }
  }

  FingerprintConfig _buildFingerprintConfig() {
    final wParts = _webglVendor.isNotEmpty && _webglRenderer.isNotEmpty
        ? WebGLConfig(vendor: _webglVendor, renderer: _webglRenderer)
        : WebGLConfig(
            vendor: 'Google Inc. (NVIDIA)',
            renderer: 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3060)',
          );

    GeolocationConfig? geo;
    if (_geoEnabled) {
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      final acc = double.tryParse(_accuracyController.text.trim()) ?? 50.0;
      if (lat != null && lng != null) {
        geo = GeolocationConfig(latitude: lat, longitude: lng, accuracy: acc);
      }
    }

    return FingerprintConfig(
      userAgent: _buildUserAgent(),
      platform: _platformFromOs(_selectedOs),
      language: 'en-US',
      hardwareConcurrency: _hardwareConcurrency,
      deviceMemory: _deviceMemory,
      screenResolution: ScreenResolution(
        width: _screenWidth,
        height: _screenHeight,
        colorDepth: _colorDepth,
      ),
      webglConfig: wParts,
      canvasNoiseSalt: _canvasSaltController.text.trim().isNotEmpty
          ? _canvasSaltController.text.trim()
          : FingerprintConfig.generateNewSalt(),
      webrtcEnabled: _webrtcEnabled,
      timezone: _timezone,
      geolocation: geo,
    );
  }

  String _platformFromOs(String os) {
    switch (os) {
      case 'macOS':
        return 'MacIntel';
      case 'Linux':
        return 'Linux x86_64';
      case 'Android':
        return 'Linux armv81';
      case 'iOS':
        return 'iPhone';
      default:
        return 'Win32';
    }
  }

  // ── Save ──────────────────────────────────
  Future<void> _saveProfile() async {
    // Validate; if invalid, jump to the tab containing the first error
    if (!_formKey.currentState!.validate()) {
      // Tab 0 has the name field – jump there if empty
      if (_nameController.text.trim().isEmpty) {
        _tabController.animateTo(0);
      } else if (_selectedProxyType != ProxyType.none &&
          (_proxyHostController.text.isEmpty ||
              _proxyPortController.text.isEmpty)) {
        _tabController.animateTo(1);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final proxyConfig = ProxyConfig(
        type: _selectedProxyType,
        host: _selectedProxyType != ProxyType.none
            ? _proxyHostController.text.trim()
            : null,
        port: _selectedProxyType != ProxyType.none
            ? int.tryParse(_proxyPortController.text.trim())
            : null,
        username: _proxyUsernameController.text.trim().isNotEmpty
            ? _proxyUsernameController.text.trim()
            : null,
        password: _proxyPasswordController.text.trim().isNotEmpty
            ? _proxyPasswordController.text.trim()
            : null,
        rotationUrl: _proxyRotationUrlController.text.trim().isNotEmpty
            ? _proxyRotationUrlController.text.trim()
            : null,
      );

      final profileId =
          widget.existingProfile?.id ?? widget.repository.generateProfileId();
      final userDataPath =
          await widget.repository.generateUserDataPath(profileId);
      final now = DateTime.now();

      final profile = BrowserProfile(
        id: profileId,
        name: _nameController.text.trim(),
        proxyConfig: proxyConfig,
        fingerprintConfig: _buildFingerprintConfig(),
        userDataFolder: userDataPath,
        createdAt: widget.existingProfile?.createdAt ?? now,
        lastUsedAt: now,
        tags: List<String>.from(_tags),
      );

      if (widget.existingProfile != null) {
        await widget.repository.updateProfile(profile);
      } else {
        await widget.repository.createProfile(profile);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sparkleController.dispose();
    _nameController.dispose();
    _tagInputController.dispose();
    _uaController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyUsernameController.dispose();
    _proxyPasswordController.dispose();
    _proxyRotationUrlController.dispose();
    _canvasSaltController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _accuracyController.dispose();
    _customDnsController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProfile != null;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF141414),
          surfaceTintColor: Colors.transparent,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isEdit) ...[
                Hero(
                  tag: 'os_badge_${widget.existingProfile!.id}',
                  child: OsBadge(platform: widget.existingProfile!.fingerprintConfig.platform),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEdit ? 'Edit Profile' : 'New Profile',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (isEdit)
                      Hero(
                        tag: 'profile_name_${widget.existingProfile!.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            widget.existingProfile!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Configure browser fingerprint',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.tealAccent,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: Colors.tealAccent,
            indicatorWeight: 2.5,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white54,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.person_outline, size: 18), text: 'General'),
              Tab(icon: Icon(Icons.wifi_tethering, size: 18), text: 'Network'),
              Tab(icon: Icon(Icons.memory, size: 18), text: 'Hardware'),
              Tab(icon: Icon(Icons.tune, size: 18), text: 'Advanced'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Anonymity Health Gauge ───────────────────────────
            AnonymityScoreBar(
              result: _computeAnonymityScore(),
              showSparkle: _showSparkle,
              sparkleController: _sparkleController,
            ),
            // ── Form Tabs ────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
              // ── Tab 1: General ──────────────────────────
              _GeneralTab(
                nameController: _nameController,
                uaController: _uaController,
                selectedOs: _selectedOs,
                selectedBrowser: _selectedBrowser,
                osList: _osList,
                browserList: _browserList,
                uaManualOverride: _uaManualOverride,
                onOsChanged: (v) => setState(() {
                  _selectedOs = v;
                  _uaManualOverride = false;
                }),
                onBrowserChanged: (v) => setState(() {
                  _selectedBrowser = v;
                  _uaManualOverride = false;
                }),
                onUaChanged: (_) => setState(() => _uaManualOverride = true),
                tags: _tags,
                tagController: _tagInputController,
                onTagsChanged: (t) => setState(() => _tags = t),
                onRandomize: () =>
                    _applyRandomFingerprint(FingerprintConfig.random()),
              ),

              // ── Tab 2: Network ──────────────────────────
              _NetworkTab(
                selectedProxyType: _selectedProxyType,
                hostController: _proxyHostController,
                portController: _proxyPortController,
                usernameController: _proxyUsernameController,
                passwordController: _proxyPasswordController,
                rotationUrlController: _proxyRotationUrlController,
                webrtcEnabled: _webrtcEnabled,
                onProxyTypeChanged: (v) =>
                    setState(() => _selectedProxyType = v),
                onWebrtcChanged: (v) => setState(() => _webrtcEnabled = v),
                onRandomize: () =>
                    _applyRandomFingerprint(FingerprintConfig.random()),
              ),

              // ── Tab 3: Hardware ─────────────────────────
              _HardwareTab(
                webglOptions: _webglOptions,
                currentVendor: _webglVendor,
                currentRenderer: _webglRenderer,
                canvasSaltController: _canvasSaltController,
                screenWidth: _screenWidth,
                screenHeight: _screenHeight,
                colorDepth: _colorDepth,
                hardwareConcurrency: _hardwareConcurrency,
                deviceMemory: _deviceMemory,
                resolutions: _resolutions,
                cpuOptions: _cpuOptions,
                ramOptions: _ramOptions,
                onWebglChanged: (vendor, renderer) => setState(() {
                  _webglVendor = vendor;
                  _webglRenderer = renderer;
                }),
                onResolutionChanged: (w, h, d) => setState(() {
                  _screenWidth = w;
                  _screenHeight = h;
                  _colorDepth = d;
                }),
                onCpuChanged: (v) => setState(() => _hardwareConcurrency = v),
                onRamChanged: (v) => setState(() => _deviceMemory = v),
                onRandomize: () =>
                    _applyRandomFingerprint(FingerprintConfig.random()),
              ),

              // ── Tab 4: Advanced ─────────────────────────
              _AdvancedTab(
                timezone: _timezone,
                timezones: _timezones,
                geoEnabled: _geoEnabled,
                latController: _latController,
                lngController: _lngController,
                accuracyController: _accuracyController,
                customDnsController: _customDnsController,
                onTimezoneChanged: (v) => setState(() => _timezone = v),
                onGeoToggled: (v) => setState(() => _geoEnabled = v),
                onRandomize: () =>
                    _applyRandomFingerprint(FingerprintConfig.random()),
              ),
              ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ANONYMITY SCORE BAR
// ═════════════════════════════════════════════════════════════════════════════

/// Immutable result from the heuristic scoring engine.
class AnonymityResult {
  final int score;          // 0–100
  final List<String> issues;

  const AnonymityResult({required this.score, required this.issues});

  String get grade {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'At Risk';
  }

  Color get barColor {
    if (score >= 80) return Colors.tealAccent;
    if (score >= 50) return Colors.amberAccent;
    return Colors.redAccent;
  }

  Color get gradeChipColor {
    if (score >= 80) return const Color(0xFF0D2B1E);
    if (score >= 50) return const Color(0xFF2B1E00);
    return const Color(0xFF2B0D0D);
  }

  IconData get gradeIcon {
    if (score >= 80) return Icons.verified_user_rounded;
    if (score >= 50) return Icons.security_rounded;
    return Icons.gpp_bad_rounded;
  }
}

/// Animated gauge bar displayed above the tab form.
class AnonymityScoreBar extends StatelessWidget {
  final AnonymityResult result;
  final bool showSparkle;
  final AnimationController sparkleController;

  const AnonymityScoreBar({
    super.key,
    required this.result,
    required this.showSparkle,
    required this.sparkleController,
  });

  @override
  Widget build(BuildContext context) {
    final sparkleAnimation = CurvedAnimation(
      parent: sparkleController,
      curve: Curves.easeOut,
    );

    return Container(
      color: const Color(0xFF111118),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Score row ────────────────────────────────────────────
          Row(
            children: [
              Icon(result.gradeIcon, size: 16, color: result.barColor),
              const SizedBox(width: 8),
              Text(
                'Anonymity Score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              // Animated score number
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: result.score),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (_, val, __) => Text(
                  '$val / 100',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: result.barColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              // Sparkle overlay (visible immediately on randomize)
              if (showSparkle)
                FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(sparkleAnimation),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.purpleAccent.shade100),
                      const SizedBox(width: 3),
                      Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.purpleAccent.shade200),
                      const SizedBox(width: 3),
                      Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.purpleAccent.shade100),
                    ],
                  ),
                )
              else
                // Grade chip
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: result.gradeChipColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: result.barColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    result.grade,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: result.barColor,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Animated gauge bar ────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  // Track
                  Container(
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                  // Fill
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    widthFactor: result.score / 100,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            result.barColor.withValues(alpha: 0.7),
                            result.barColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: result.barColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Issue chips ─────────────────────────────────────────
          if (result.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.issues
                  .map((issue) => _IssueChip(label: issue))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  final String label;
  const _IssueChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 11, color: Colors.redAccent.shade100),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent.shade100,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS & HELPERS
// ─────────────────────────────────────────────

/// A prominent "Generate Random Fingerprint" button shown in every tab.
class _RandomizeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RandomizeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade800,
            Colors.deepPurple.shade700,
            Colors.indigo.shade700,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white12,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shuffle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Generate Random Fingerprint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard dark-theme input decoration used across all tabs.
InputDecoration _inputDeco(String label, IconData icon,
    {String? hint, Color? accent, String? tooltip}) {
  final accentColor = accent ?? Colors.tealAccent.shade200;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
    prefixIcon: Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 20),
    suffixIcon: tooltip != null ? InfoTooltipWidget(message: tooltip) : null,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.045),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accentColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );
}

/// Section header used inside each tab.
Widget _sectionHeader(String title, {IconData? icon, String? tooltip}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.tealAccent.shade200),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.tealAccent.shade200,
            letterSpacing: 0.5,
          ),
        ),
        if (tooltip != null) InfoTooltipWidget(message: tooltip),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.tealAccent.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A dropdown that matches the dark styling of the form.
Widget _darkDropdown<T>({
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  required InputDecoration decoration,
}) {
  return DropdownButtonFormField<T>(
    initialValue: value,
    decoration: decoration,
    dropdownColor: const Color(0xFF1E1E2A),
    style: const TextStyle(color: Colors.white, fontSize: 14),
    icon:
        Icon(Icons.keyboard_arrow_down_rounded, color: Colors.tealAccent.shade200),
    items: items,
    onChanged: onChanged,
  );
}

/// Tab-level scrollable wrapper with consistent padding.
Widget _tabScroll({required List<Widget> children}) {
  return ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
    children: children,
  );
}

// ─────────────────────────────────────────────
//  TAB 1: GENERAL
// ─────────────────────────────────────────────

class _GeneralTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController uaController;
  final String selectedOs;
  final String selectedBrowser;
  final List<String> osList;
  final List<String> browserList;
  final bool uaManualOverride;
  final ValueChanged<String> onOsChanged;
  final ValueChanged<String> onBrowserChanged;
  final ValueChanged<String> onUaChanged;
  final List<String> tags;
  final TextEditingController tagController;
  final ValueChanged<List<String>> onTagsChanged;
  final VoidCallback onRandomize;

  const _GeneralTab({
    required this.nameController,
    required this.uaController,
    required this.selectedOs,
    required this.selectedBrowser,
    required this.osList,
    required this.browserList,
    required this.uaManualOverride,
    required this.onOsChanged,
    required this.onBrowserChanged,
    required this.onUaChanged,
    required this.tags,
    required this.tagController,
    required this.onTagsChanged,
    required this.onRandomize,
  });

  @override
  Widget build(BuildContext context) {
    return _tabScroll(children: [
      _RandomizeButton(onPressed: onRandomize),
      const SizedBox(height: 28),

      // ── Profile Identity ─────────────────
      _sectionHeader('Profile Identity', icon: Icons.badge_outlined),
      TextFormField(
        controller: nameController,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDeco('Profile Name', Icons.label_outline),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Profile name is required' : null,
      ),
      const SizedBox(height: 28),

      // ── Browser Identity ─────────────────
      _sectionHeader('Browser Identity', icon: Icons.language),
      _darkDropdown<String>(
        value: selectedOs,
        items: osList
            .map((o) => DropdownMenuItem(
                  value: o,
                  child: Row(
                    children: [
                      Icon(_osIcon(o),
                          size: 18, color: Colors.tealAccent.shade100),
                      const SizedBox(width: 10),
                      Text(o),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onOsChanged(v);
        },
        decoration: _inputDeco('Operating System', Icons.computer_outlined),
      ),
      const SizedBox(height: 14),
      _darkDropdown<String>(
        value: selectedBrowser,
        items: browserList
            .map((b) => DropdownMenuItem(
                  value: b,
                  child: Text(b),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onBrowserChanged(v);
        },
        decoration: _inputDeco('Browser Engine', Icons.public),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: uaController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 3,
        minLines: 2,
        decoration: _inputDeco(
          uaManualOverride ? 'User-Agent (Manual)' : 'User-Agent (Auto)',
          Icons.fingerprint,
          hint: 'Auto-generated from OS + Browser selection',
          tooltip: 'The User-Agent tells websites your browser version and Operating System. PBrowser spoofs this to match your selection, hiding your real device identity.',
        ).copyWith(
          suffixIcon: uaManualOverride
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.orange),
                  tooltip: 'Reset to auto',
                  onPressed: () => onUaChanged(''),
                )
              : null,
        ),
        onChanged: onUaChanged,
      ),
      if (!uaManualOverride)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Edit above to override manually',
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
          ),
        ),
    ]);
  }

  IconData _osIcon(String os) {
    switch (os) {
      case 'macOS':
        return Icons.apple;
      case 'Android':
        return Icons.android;
      case 'iOS':
        return Icons.phone_iphone;
      case 'Linux':
        return Icons.terminal;
      default:
        return Icons.computer;
    }
  }
}

// ─────────────────────────────────────────────
//  TAB 2: NETWORK
// ─────────────────────────────────────────────

class _NetworkTab extends StatelessWidget {
  final ProxyType selectedProxyType;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController rotationUrlController;
  final bool webrtcEnabled;
  final ValueChanged<ProxyType> onProxyTypeChanged;
  final ValueChanged<bool> onWebrtcChanged;
  final VoidCallback onRandomize;

  const _NetworkTab({
    required this.selectedProxyType,
    required this.hostController,
    required this.portController,
    required this.usernameController,
    required this.passwordController,
    required this.rotationUrlController,
    required this.webrtcEnabled,
    required this.onProxyTypeChanged,
    required this.onWebrtcChanged,
    required this.onRandomize,
  });

  @override
  Widget build(BuildContext context) {
    final hasProxy = selectedProxyType != ProxyType.none;
    return _tabScroll(children: [
      _RandomizeButton(onPressed: onRandomize),
      const SizedBox(height: 28),

      // ── Proxy Configuration ───────────────
      _sectionHeader('Proxy Configuration', icon: Icons.vpn_lock_outlined, tooltip: 'Proxies hide your real IP address. Selecting HTTP or SOCKS5 routes your browser traffic through a remote server.'),
      _darkDropdown<ProxyType>(
        value: selectedProxyType,
        items: const [
          DropdownMenuItem(
            value: ProxyType.none,
            child: Text('No Proxy  (Direct Connection)'),
          ),
          DropdownMenuItem(
            value: ProxyType.http,
            child: Text('HTTP Proxy'),
          ),
          DropdownMenuItem(
            value: ProxyType.socks5,
            child: Text('SOCKS5 Proxy'),
          ),
        ],
        onChanged: (v) {
          if (v != null) onProxyTypeChanged(v);
        },
        decoration: _inputDeco('Proxy Type', Icons.vpn_lock,
            accent: Colors.orangeAccent),
      ),

      if (hasProxy) ...[
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: hostController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Host / IP', Icons.dns_outlined,
                    hint: 'e.g. 192.168.1.1',
                    accent: Colors.orangeAccent),
                validator: (v) => hasProxy && (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: portController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDeco('Port', Icons.pin_outlined,
                    hint: '1080', accent: Colors.orangeAccent),
                validator: (v) {
                  if (!hasProxy) return null;
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final p = int.tryParse(v);
                  if (p == null || p < 1 || p > 65535) return 'Invalid';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: usernameController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('Username', Icons.person_outline,
              hint: 'Optional', accent: Colors.orangeAccent),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: passwordController,
          style: const TextStyle(color: Colors.white),
          obscureText: true,
          decoration: _inputDeco('Password', Icons.lock_outline,
              hint: 'Optional', accent: Colors.orangeAccent),
        ),
        const SizedBox(height: 28),
        _sectionHeader('Modem Rotator', icon: Icons.autorenew, tooltip: 'Automatically forces a physical 4G/5G mobile router to fetch a new IP address before launching the browser.'),
        TextFormField(
          controller: rotationUrlController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          keyboardType: TextInputType.url,
          decoration: _inputDeco(
            'IP Rotation API URL',
            Icons.link,
            hint: 'https://api.provider.com/rotate?key=...',
            accent: Colors.orangeAccent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Leave empty to disable automatic IP rotation',
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
          ),
        ),
      ],

      const SizedBox(height: 28),
      // ── WebRTC ────────────────────────────
      _sectionHeader('WebRTC', icon: Icons.wifi_channel, tooltip: 'WebRTC is used for real-time video/audio. If enabled without a proxy, it will leak your real local IP address. Disabling it is safer but may break video conferencing sites.'),
      _SettingsToggleCard(
        title: 'WebRTC Enabled',
        subtitle: 'Disable to prevent IP leakage through WebRTC',
        value: webrtcEnabled,
        onChanged: onWebrtcChanged,
        activeColor: Colors.orangeAccent,
        icon: Icons.cell_wifi,
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
//  TAB 3: HARDWARE
// ─────────────────────────────────────────────

class _HardwareTab extends StatelessWidget {
  final List<String> webglOptions;
  final String currentVendor;
  final String currentRenderer;
  final TextEditingController canvasSaltController;
  final int screenWidth;
  final int screenHeight;
  final int colorDepth;
  final int hardwareConcurrency;
  final int deviceMemory;
  final List<String> resolutions;
  final List<int> cpuOptions;
  final List<int> ramOptions;
  final void Function(String vendor, String renderer) onWebglChanged;
  final void Function(int w, int h, int d) onResolutionChanged;
  final ValueChanged<int> onCpuChanged;
  final ValueChanged<int> onRamChanged;
  final VoidCallback onRandomize;

  const _HardwareTab({
    required this.webglOptions,
    required this.currentVendor,
    required this.currentRenderer,
    required this.canvasSaltController,
    required this.screenWidth,
    required this.screenHeight,
    required this.colorDepth,
    required this.hardwareConcurrency,
    required this.deviceMemory,
    required this.resolutions,
    required this.cpuOptions,
    required this.ramOptions,
    required this.onWebglChanged,
    required this.onResolutionChanged,
    required this.onCpuChanged,
    required this.onRamChanged,
    required this.onRandomize,
  });

  String get _currentWebglKey => '$currentVendor|$currentRenderer';

  @override
  Widget build(BuildContext context) {
    // Ensure the current webgl value exists in the list, else use first
    final resolvedWebgl = webglOptions.any((e) => e == _currentWebglKey)
        ? _currentWebglKey
        : webglOptions.first;

    // Resolution dropdown value
    final resolutionItems = resolutions.toList();
    final currentResKey = '$screenWidth×$screenHeight';
    final resolvedRes = resolutionItems.any((r) => r.startsWith(currentResKey))
        ? currentResKey
        : resolutionItems.first;

    return _tabScroll(children: [
      _RandomizeButton(onPressed: onRandomize),
      const SizedBox(height: 28),

      // ── WebGL ─────────────────────────────
      _sectionHeader('WebGL Fingerprint', icon: Icons.grain, tooltip: 'Graphics hardware exposes a unique identifier. Matching this to your Operating System is crucial to avoid bot-detection (e.g., do not use an Apple GPU on Windows).'),
      _darkDropdown<String>(
        value: resolvedWebgl,
        items: webglOptions
            .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    o.split('|').first,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            final parts = v.split('|');
            onWebglChanged(parts[0], parts.length > 1 ? parts[1] : '');
          }
        },
        decoration: _inputDeco('GPU Vendor', Icons.videogame_asset_outlined,
            accent: Colors.purpleAccent),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Renderer',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              currentRenderer.isNotEmpty ? currentRenderer : '—',
              style: const TextStyle(
                  color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),

      // ── Canvas ────────────────────────────
      _sectionHeader('Canvas Fingerprint', icon: Icons.brush_outlined, tooltip: 'Canvas Spoofing adds invisible, microscopic noise to images rendered by the browser. This prevents tracking scripts from linking your device to a persistent identity.'),
      TextFormField(
        controller: canvasSaltController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: _inputDeco(
          'Canvas Noise Salt',
          Icons.texture,
          hint: 'Random 32-char string',
          accent: Colors.purpleAccent,
          tooltip: 'The cryptographic seed used to generate the unique image noise. Generating a new fingerprint changes this salt.',
        ),
      ),
      const SizedBox(height: 28),

      // ── Screen ────────────────────────────
      _sectionHeader('Screen & Display', icon: Icons.monitor),
      _darkDropdown<String>(
        value: resolvedRes,
        items: resolutionItems
            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            final parts = v.split('×');
            if (parts.length == 2) {
              onResolutionChanged(int.parse(parts[0]), int.parse(parts[1]), 24);
            }
          }
        },
        decoration: _inputDeco('Screen Resolution', Icons.aspect_ratio,
            accent: Colors.purpleAccent),
      ),
      const SizedBox(height: 28),

      // ── CPU / RAM ─────────────────────────
      _sectionHeader('CPU & Memory', icon: Icons.memory),
      Row(
        children: [
          Expanded(
            child: _darkDropdown<int>(
              value: cpuOptions.contains(hardwareConcurrency)
                  ? hardwareConcurrency
                  : cpuOptions.last,
              items: cpuOptions
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text('$c Cores')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onCpuChanged(v);
              },
              decoration: _inputDeco('CPU Cores', Icons.developer_board,
                  accent: Colors.purpleAccent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _darkDropdown<int>(
              value: ramOptions.contains(deviceMemory)
                  ? deviceMemory
                  : ramOptions.last,
              items: ramOptions
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text('$r GB RAM')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onRamChanged(v);
              },
              decoration: _inputDeco('Device Memory', Icons.sd_card_outlined,
                  accent: Colors.purpleAccent),
            ),
          ),
        ],
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
//  TAB 4: ADVANCED
// ─────────────────────────────────────────────

class _AdvancedTab extends StatelessWidget {
  final String timezone;
  final List<String> timezones;
  final bool geoEnabled;
  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController accuracyController;
  final TextEditingController customDnsController;
  final ValueChanged<String> onTimezoneChanged;
  final ValueChanged<bool> onGeoToggled;
  final VoidCallback onRandomize;

  const _AdvancedTab({
    required this.timezone,
    required this.timezones,
    required this.geoEnabled,
    required this.latController,
    required this.lngController,
    required this.accuracyController,
    required this.customDnsController,
    required this.onTimezoneChanged,
    required this.onGeoToggled,
    required this.onRandomize,
  });

  @override
  Widget build(BuildContext context) {
    return _tabScroll(children: [
      _RandomizeButton(onPressed: onRandomize),
      const SizedBox(height: 28),

      // ── Timezone ──────────────────────────
      _sectionHeader('Timezone', icon: Icons.schedule_outlined),
      _darkDropdown<String>(
        value: timezones.contains(timezone) ? timezone : timezones.first,
        items: timezones
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (v) {
          if (v != null) onTimezoneChanged(v);
        },
        decoration: _inputDeco('Timezone', Icons.public,
            accent: Colors.cyanAccent),
      ),
      const SizedBox(height: 28),

      // ── Geolocation ───────────────────────
      _sectionHeader('Geolocation', icon: Icons.location_on_outlined),
      _SettingsToggleCard(
        title: 'Override Geolocation',
        subtitle: 'Inject custom GPS coordinates into the browser',
        value: geoEnabled,
        onChanged: onGeoToggled,
        activeColor: Colors.cyanAccent,
        icon: Icons.my_location,
      ),
      if (geoEnabled) ...[
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: latController,
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: _inputDeco('Latitude', Icons.explore_outlined,
                    hint: '−90 to 90', accent: Colors.cyanAccent),
                validator: (v) {
                  if (!geoEnabled) return null;
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < -90 || val > 90) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: lngController,
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: _inputDeco('Longitude', Icons.explore,
                    hint: '−180 to 180', accent: Colors.cyanAccent),
                validator: (v) {
                  if (!geoEnabled) return null;
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < -180 || val > 180) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: accuracyController,
          style: const TextStyle(color: Colors.white),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDeco('Accuracy (meters)', Icons.gps_fixed,
              hint: '50.0', accent: Colors.cyanAccent),
        ),
      ],
      const SizedBox(height: 28),

      // ── Custom DNS ────────────────────────
      _sectionHeader('Custom DNS', icon: Icons.dns_outlined),
      TextFormField(
        controller: customDnsController,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDeco('Custom DNS Server', Icons.dns,
            hint: 'e.g. 1.1.1.1 (Cloudflare)', accent: Colors.cyanAccent),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(
          'Feature coming soon — field saved for compatibility',
          style: TextStyle(
              fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
        ),
      ),
      const SizedBox(height: 28),

      // ── API Polyfills (placeholder) ───────
      _sectionHeader('API Polyfills', icon: Icons.code),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 18, color: Colors.cyanAccent.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Speech Synthesis, Battery API, and Bluetooth spoofing are always active when a profile is in use.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
//  REUSABLE TOGGLE CARD
// ─────────────────────────────────────────────

class _SettingsToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final IconData icon;

  const _SettingsToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? activeColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 20, color: value ? activeColor : Colors.white38),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: activeColor,
        activeTrackColor: activeColor.withValues(alpha: 0.35),
        inactiveThumbColor: Colors.white38,
        inactiveTrackColor: Colors.white12,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TAG INPUT COMPONENT
// ─────────────────────────────────────────────

class _TagInputField extends StatefulWidget {
  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<List<String>> onTagsChanged;

  const _TagInputField({
    required this.tags,
    required this.controller,
    required this.onTagsChanged,
  });

  @override
  State<_TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<_TagInputField> {
  static const int _maxTags = 8;
  final FocusNode _focusNode = FocusNode();

  void _addTag() {
    final t = widget.controller.text.trim().toLowerCase();
    if (t.isEmpty) return;
    
    // Split by comma in case user pastes comma-separated
    final newTags = t.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    
    bool varied = false;
    final current = List<String>.from(widget.tags);
    for (final tag in newTags) {
      if (current.length >= _maxTags) break;
      if (!current.contains(tag)) {
        current.add(tag);
        varied = true;
      }
    }

    if (varied) {
      widget.onTagsChanged(current);
    }
    
    // Keep focus, just clear text
    widget.controller.clear();
    _focusNode.requestFocus();
  }

  void _removeTag(String tag) {
    final current = List<String>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(current);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate color palette for chips locally (or use random deterministic)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.tags.map((tag) {
                // simple deterministic color
                final colors = [
                  Colors.tealAccent,
                  Colors.purpleAccent,
                  Colors.amberAccent,
                  Colors.blueAccent,
                  Colors.greenAccent,
                  Colors.orangeAccent,
                  Colors.pinkAccent,
                  Colors.cyanAccent,
                ];
                final color = colors[tag.hashCode.abs() % colors.length];

                return Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                  deleteIcon: Icon(Icons.close_rounded, size: 16, color: color),
                  onDeleted: () => _removeTag(tag),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ),
        
        // Input Field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: _inputDeco('Add a tag...', Icons.local_offer_outlined).copyWith(
            helperText: 'Press Enter or type a comma to add. Max $_maxTags tags.',
            helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.tealAccent),
              onPressed: _addTag,
              tooltip: 'Add tag',
            ),
          ),
          enabled: widget.tags.length < _maxTags,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _addTag(),
          onChanged: (val) {
            if (val.contains(',')) {
              _addTag();
            }
          },
        ),
      ],
    );
  }
}
