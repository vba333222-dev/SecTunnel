import 'package:flutter/material.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/models/proxy_config.dart';
import 'package:pbrowser/models/fingerprint_config.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:pbrowser/services/browser/cookie_manager_service.dart';
import 'package:pbrowser/services/browser/userscript_service.dart';
import 'package:pbrowser/ui/profile/user_scripts_screen.dart';
import 'package:provider/provider.dart';

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

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _proxyHostController = TextEditingController();
  final _proxyPortController = TextEditingController();
  final _proxyUsernameController = TextEditingController();
  final _proxyPasswordController = TextEditingController();
  final _cookiesController = TextEditingController();
  
  ProxyType _selectedProxyType = ProxyType.none;
  late FingerprintConfig _fingerprintConfig;
  late String _profileId;
  bool _keepAliveEnabled = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.existingProfile != null) {
      // Edit mode
      _profileId = widget.existingProfile!.id;
      _nameController.text = widget.existingProfile!.name;
      _selectedProxyType = widget.existingProfile!.proxyConfig.type;
      _proxyHostController.text = widget.existingProfile!.proxyConfig.host ?? '';
      _proxyPortController.text = widget.existingProfile!.proxyConfig.port?.toString() ?? '';
      _proxyUsernameController.text = widget.existingProfile!.proxyConfig.username ?? '';
      _proxyPasswordController.text = widget.existingProfile!.proxyConfig.password ?? '';
      _fingerprintConfig = widget.existingProfile!.fingerprintConfig;
      _keepAliveEnabled = widget.existingProfile!.keepAliveEnabled;
    } else {
      // Create mode
      _profileId = widget.repository.generateProfileId();
      _fingerprintConfig = FingerprintConfig.random();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyUsernameController.dispose();
    _proxyPasswordController.dispose();
    _cookiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(widget.existingProfile != null ? 'Edit Profile' : 'Create Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSection('Profile Information', [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Profile Name', Icons.label_outline),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a profile name';
                  }
                  return null;
                },
              ),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Proxy Configuration', [
              DropdownButtonFormField<ProxyType>(
                initialValue: _selectedProxyType,
                decoration: _inputDecoration('Proxy Type', Icons.vpn_lock),
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: ProxyType.none, child: Text('No Proxy (Direct)')),
                  DropdownMenuItem(value: ProxyType.http, child: Text('HTTP Proxy')),
                  DropdownMenuItem(value: ProxyType.socks5, child: Text('SOCKS5 Proxy')),
                ],
                onChanged: (value) {
                  setState(() => _selectedProxyType = value!);
                },
              ),
              
              if (_selectedProxyType != ProxyType.none) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _proxyHostController,
                  decoration: _inputDecoration('Proxy Host', Icons.dns),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (_selectedProxyType != ProxyType.none && (value == null || value.trim().isEmpty)) {
                      return 'Please enter proxy host';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _proxyPortController,
                  decoration: _inputDecoration('Proxy Port', Icons.pin),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedProxyType != ProxyType.none) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter proxy port';
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return 'Invalid port number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _proxyUsernameController,
                  decoration: _inputDecoration('Username (optional)', Icons.person_outline),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _proxyPasswordController,
                  decoration: _inputDecoration('Password (optional)', Icons.lock_outline),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                ),
              ],
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Session Import', [
              TextFormField(
                controller: _cookiesController,
                decoration: _inputDecoration('Paste Cookies (JSON or Netscape)', Icons.cookie_outlined),
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                minLines: 2,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Paste EditThisCookie JSON or Netscape format to automatically inject the session when the profile launches.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ]),
            
            const SizedBox(height: 32),
            
            _buildSection('Fingerprint Configuration', [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Fingerprint',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _fingerprintConfig = FingerprintConfig.random();
                            });
                          },
                          icon: const Icon(Icons.shuffle, size: 18),
                          label: const Text('Randomize'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFingerprintDetail('User Agent', _fingerprintConfig.userAgent),
                    _buildFingerprintDetail('Platform', _fingerprintConfig.platform),
                    _buildFingerprintDetail('Language', _fingerprintConfig.language),
                    _buildFingerprintDetail('CPU Cores', '${_fingerprintConfig.hardwareConcurrency}'),
                    _buildFingerprintDetail('Device Memory', '${_fingerprintConfig.deviceMemory} GB'),
                    _buildFingerprintDetail('Screen', '${_fingerprintConfig.screenResolution.width}x${_fingerprintConfig.screenResolution.height}'),
                    _buildFingerprintDetail('WebGL Vendor', _fingerprintConfig.webglConfig.vendor),
                    _buildFingerprintDetail('WebRTC', _fingerprintConfig.webrtcEnabled ? 'Enabled' : 'Disabled'),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 32),

            _buildSection('Background Keep-Alive', [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: SwitchListTile(
                  title: const Text('Enable Keep-Alive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                    'Runs a Headless WebView in an Android Foreground Service so your session stays active (WebSocket/Mining) when app is minimized.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _keepAliveEnabled,
                  onChanged: (val) {
                    setState(() => _keepAliveEnabled = val);
                  },
                  activeThumbColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ]),

            const SizedBox(height: 32),

            _buildSection('Automation', [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final userScriptService = Provider.of<UserScriptService>(context, listen: false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserScriptsScreen(
                          service: userScriptService,
                          profileId: _profileId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('Manage UserScripts (Mini-Tampermonkey)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Inject custom JavaScript automatically when visiting matching URLs.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
  
  Widget _buildFingerprintDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueGrey),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Build proxy config
      final proxyConfig = ProxyConfig(
        type: _selectedProxyType,
        host: _selectedProxyType != ProxyType.none ? _proxyHostController.text.trim() : null,
        port: _selectedProxyType != ProxyType.none ? int.parse(_proxyPortController.text.trim()) : null,
        username: _proxyUsernameController.text.trim().isNotEmpty ? _proxyUsernameController.text.trim() : null,
        password: _proxyPasswordController.text.trim().isNotEmpty ? _proxyPasswordController.text.trim() : null,
      );
      
      // Create or update profile
      final userDataPath = await widget.repository.generateUserDataPath(_profileId);
      final now = DateTime.now();
      
      final profile = BrowserProfile(
        id: _profileId,
        name: _nameController.text.trim(),
        proxyConfig: proxyConfig,
        fingerprintConfig: _fingerprintConfig,
        userDataFolder: userDataPath,
        keepAliveEnabled: _keepAliveEnabled,
        createdAt: widget.existingProfile?.createdAt ?? now,
        lastUsedAt: widget.existingProfile?.lastUsedAt ?? now,
      );
      
      if (widget.existingProfile != null) {
        await widget.repository.updateProfile(profile);
      } else {
        await widget.repository.createProfile(profile);
      }
      
      // Handle pending cookies
      if (_cookiesController.text.trim().isNotEmpty) {
        await CookieManagerService.savePendingCookies(userDataPath, _cookiesController.text.trim());
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
