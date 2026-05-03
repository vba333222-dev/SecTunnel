import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sec_tunnel/models/browser_profile.dart';
import 'package:sec_tunnel/models/fingerprint_config.dart';
import 'package:sec_tunnel/models/proxy_config.dart';
import 'package:sec_tunnel/repositories/profile_repository.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/device_preset.dart';
import 'package:sec_tunnel/services/proxy/modem_rotator_service.dart';
import 'package:sec_tunnel/ui/browser/browser_screen.dart';
import 'package:sec_tunnel/ui/debug/debug_panel.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/presets/preset_repository.dart';

import 'widgets/preset_selector_widget.dart';
import 'widgets/big_rotate_button.dart';
import 'widgets/status_card_widget.dart';
import 'widgets/activity_log_widget.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  final ProfileRepository repository;

  const DashboardScreen({
    super.key,
    required this.repository,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String globalSessionId = 'global_active_session';

  DevicePreset? _selectedPreset;

  // Advanced settings controllers
  final TextEditingController _proxyHostController = TextEditingController();
  final TextEditingController _proxyPortController = TextEditingController();
  final TextEditingController _proxyUserController = TextEditingController();
  final TextEditingController _proxyPassController = TextEditingController();

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initGlobalSession();
  }

  Future<void> _initGlobalSession() async {
    final profile = await widget.repository.getProfileById(globalSessionId);
    if (profile != null && profile.proxyConfig.type != ProxyType.none) {
      _proxyHostController.text = profile.proxyConfig.host ?? '';
      _proxyPortController.text = profile.proxyConfig.port?.toString() ?? '';
      _proxyUserController.text = profile.proxyConfig.username ?? '';
      _proxyPassController.text = profile.proxyConfig.password ?? '';
    } else {
      // Default placeholder if empty
      _proxyPortController.text = '1';
    }

    // Smart Default: Auto-select a preset if none is chosen
    if (_selectedPreset == null) {
      final defaultPreset = PresetRepository.presets.where((p) => p.category == 'mobile').firstOrNull ??
                            PresetRepository.presets.firstOrNull;
      if (defaultPreset != null) {
        _selectedPreset = defaultPreset;
      }
    }

    if (mounted) {
      setState(() {
        _isInit = true;
      });
    }
  }

  @override
  void dispose() {
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyUserController.dispose();
    _proxyPassController.dispose();
    super.dispose();
  }

  Future<void> _saveAndRotate() async {
    if (_selectedPreset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device preset first.')),
      );
      return;
    }

    // Save profile
    final proxyConfig = ProxyConfig(
      type: ProxyType.http,
      useSystemProxyPool: true,
      host: _proxyHostController.text.trim().isNotEmpty ? _proxyHostController.text.trim() : null,
      port: _proxyPortController.text.trim().isNotEmpty ? int.tryParse(_proxyPortController.text.trim()) : null,
      username: _proxyUserController.text.trim().isNotEmpty ? _proxyUserController.text.trim() : null,
      password: _proxyPassController.text.trim().isNotEmpty ? _proxyPassController.text.trim() : null,
      rotationUrl: null, // Modem rotator handles its own endpoint
    );

    final userDataPath = await widget.repository.generateUserDataPath(globalSessionId);

    final profile = BrowserProfile(
      id: globalSessionId,
      name: 'Active Session',
      proxyConfig: proxyConfig,
      fingerprintConfig: FingerprintConfig.fromPreset(_selectedPreset!),
      userDataFolder: userDataPath,
      keepAliveEnabled: true,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
      tags: ['Global'],
    );

    // Trigger rotation immediately for optimistic UI
    if (mounted) {
      context.read<ModemRotatorService>().rotateIp(globalSessionId, 'Active Session');
    }

    // Save into repo asynchronously
    widget.repository.getProfileById(globalSessionId).then((existing) {
      if (existing != null) {
        widget.repository.updateProfile(profile);
      } else {
        widget.repository.createProfile(profile);
      }
    });
  }

  Future<void> _launchBrowser() async {
    final profile = await widget.repository.getProfileById(globalSessionId);
    if (profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not ready. Please rotate IP first.')),
        );
      }
      return;
    }

    await widget.repository.markAsUsed(globalSessionId);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BrowserScreen(profile: profile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return Scaffold(
        appBar: AppBar(
          title: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: 150, height: 20, color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 24),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 32),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SecTunnel Active Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Tooltip(
            message: 'Debug Panel',
            child: IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugPanel()));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchBrowser,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.open_in_browser_rounded),
        label: const Text('Launch Session', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            const StatusCardWidget(profileId: globalSessionId),
            const SizedBox(height: 24),

            // Preset Selector
            PresetSelectorWidget(
              selectedPreset: _selectedPreset,
              onPresetSelected: (preset) {
                setState(() {
                  _selectedPreset = preset;
                });
              },
            ),
            const SizedBox(height: 32),

            // Big Rotate Button
            Center(
              child: BigRotateButton(
                profileId: globalSessionId,
                onRotate: _saveAndRotate,
                onLaunchBrowser: _launchBrowser,
              ),
            ),
            const SizedBox(height: 32),

            // Advanced Settings
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: Colors.blue[600],
                  collapsedIconColor: Colors.grey[600],
                  title: Text('Advanced Proxy Settings', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(bottom: 16.0),
                      child: Column(
                        children: [
                          _buildTextField('Proxy Port (Modem Index)', _proxyPortController, Icons.numbers),
                          const SizedBox(height: 12),
                          _buildTextField('Proxy Host (Optional override)', _proxyHostController, Icons.router_outlined),
                          const SizedBox(height: 12),
                          _buildTextField('Proxy Username (Optional)', _proxyUserController, Icons.person_outline),
                          const SizedBox(height: 12),
                          _buildTextField('Proxy Password (Optional)', _proxyPassController, Icons.lock_outline, obscureText: true),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Activity Log
            const ActivityLogWidget(profileId: globalSessionId),
            
            // Padding for FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.grey[900]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
