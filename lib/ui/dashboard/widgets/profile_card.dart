import 'package:flutter/material.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:intl/intl.dart';
import 'package:pbrowser/services/proxy/mobile_proxy_service.dart';

class ProfileCard extends StatefulWidget {
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
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isRotatingIp = false;

  Future<void> _rotateIp() async {
    final url = widget.profile.proxyConfig.rotationUrl;
    if (url == null || url.trim().isEmpty) return;

    setState(() => _isRotatingIp = true);
    final success = await MobileProxyService.rotateIp(url);
    
    if (mounted) {
      setState(() => _isRotatingIp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'IP Rotation Successful' : 'IP Rotation Failed'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: widget.onRun,
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit();
                      } else if (value == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (context) => [
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
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.vpn_lock_outlined,
                      _getProxyText(),
                      Colors.green,
                    ),
                  ),
                  if (profile.proxyConfig.rotationUrl != null && profile.proxyConfig.rotationUrl!.isNotEmpty)
                    _isRotatingIp 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: const Icon(Icons.autorenew, color: Colors.blueAccent, size: 20),
                            onPressed: _rotateIp,
                            tooltip: 'Rotate IP',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                ],
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
                  onPressed: widget.onRun,
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
    
    switch (widget.profile.proxyConfig.type.toString()) {
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
    if (widget.profile.proxyConfig.type.toString() == 'none') {
      return 'No Proxy (Direct)';
    }
    
    final host = widget.profile.proxyConfig.host ?? 'unknown';
    final port = widget.profile.proxyConfig.port ?? 0;
    final type = widget.profile.proxyConfig.type.toString().toUpperCase();
    
    return '$type: $host:$port';
  }
  
  String _getUserAgentPreview() {
    final ua = widget.profile.fingerprintConfig.userAgent;
    
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
    final diff = now.difference(widget.profile.lastUsedAt);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(widget.profile.lastUsedAt);
    }
  }
}
