import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/services/browser/cookie_manager_service.dart';
import 'package:pbrowser/services/background/headless_keep_alive_service.dart';
import 'package:intl/intl.dart';

class ProfileCard extends StatelessWidget {
  final BrowserProfile profile;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const ProfileCard({
    super.key,
    required this.profile,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onRun,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  _buildProxyIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.keepAliveEnabled)
                    const Tooltip(
                      message: 'Keep-Alive Enabled',
                      child: Icon(Icons.flash_on, color: Colors.yellow, size: 16),
                    ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      } else if (value == 'export') {
                        _handleExportSession(context);
                      } else if (value == 'start_bg') {
                        final success = await HeadlessKeepAliveService.startHeadlessSession(profile.id, profile.name);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Started Background Farm' : 'Failed to start')),
                          );
                        }
                      } else if (value == 'stop_bg') {
                        await HeadlessKeepAliveService.stopHeadlessSession();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stopped Background Farm')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (profile.keepAliveEnabled) ...[
                        const PopupMenuItem(
                          value: 'start_bg',
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_fill, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Start Farm (Bg)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stop_bg',
                          child: Row(
                            children: [
                              Icon(Icons.stop_circle, size: 20, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Stop Farm'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                      ],
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.cookie, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Export Session'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Proxy Info
              _buildInfoRow(
                Icons.vpn_lock_outlined,
                _getProxyText(),
                Colors.green,
              ),
              
              const SizedBox(height: 8),
              
              // User Agent Info
              _buildInfoRow(
                Icons.phone_android,
                _getUserAgentPreview(),
                Colors.blue,
              ),
              
              const Spacer(),
              
              // Last Used
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    _getLastUsedText(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Run Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRun,
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Launch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProxyIcon() {
    IconData icon;
    Color color;
    
    switch (profile.proxyConfig.type.toString()) {
      case 'http':
        icon = Icons.http;
        color = Colors.orange;
        break;
      case 'socks5':
        icon = Icons.security;
        color = Colors.purple;
        break;
      default:
        icon = Icons.public_off;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  String _getProxyText() {
    if (profile.proxyConfig.type.toString() == 'none') {
      return 'No Proxy (Direct)';
    }
    
    final host = profile.proxyConfig.host ?? 'unknown';
    final port = profile.proxyConfig.port ?? 0;
    final type = profile.proxyConfig.type.toString().toUpperCase();
    
    return '$type: $host:$port';
  }
  
  String _getUserAgentPreview() {
    final ua = profile.fingerprintConfig.userAgent;
    
    // Extract browser name
    if (ua.contains('Chrome/')) {
      final match = RegExp(r'Chrome/(\d+)').firstMatch(ua);
      if (match != null) {
        return 'Chrome ${match.group(1)}';
      }
    }
    
    return ua.substring(0, ua.length > 30 ? 30 : ua.length);
  }
  
  String _getLastUsedText() {
    final now = DateTime.now();
    final diff = now.difference(profile.lastUsedAt);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(profile.lastUsedAt);
    }
  }

  Future<void> _handleExportSession(BuildContext context) async {
    try {
      final jsonCookies = await CookieManagerService.exportCookies(profile.id);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('Exported Cookies', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonCookies,
                  style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonCookies));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Copy to Clipboard', style: TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export cookies: $e')),
        );
      }
    }
  }
}
