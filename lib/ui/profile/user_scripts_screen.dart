import 'package:flutter/material.dart';
import 'package:pbrowser/models/user_script.dart';
import 'package:pbrowser/services/browser/userscript_service.dart';

class UserScriptsScreen extends StatefulWidget {
  final UserScriptService service;
  final String profileId;

  const UserScriptsScreen({
    super.key,
    required this.service,
    required this.profileId,
  });

  @override
  State<UserScriptsScreen> createState() => _UserScriptsScreenState();
}

class _UserScriptsScreenState extends State<UserScriptsScreen> {
  List<UserScript> _scripts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    setState(() => _isLoading = true);
    try {
      final scripts = await widget.service.getScripts(widget.profileId);
      setState(() {
        _scripts = scripts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading scripts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Manage UserScripts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showScriptForm(null),
            tooltip: 'Add Script',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scripts.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text(
            'No UserScripts',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Automate tasks with JavaScript injections',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showScriptForm(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Script'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scripts.length,
      itemBuilder: (context, index) {
        final script = _scripts[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(script.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Matches: ${script.urlPattern}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Runs at: ${script.runAt}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
            trailing: Switch(
              value: script.isActive,
              onChanged: (val) async {
                await widget.service.toggleActive(script.id, val);
                _loadScripts();
              },
              activeThumbColor: Colors.green, // activeColor maps to activeThumbColor in newer versions, but we should use activeColor if activeThumbColor does not exist. Actually, let's keep activeColor if we want, or use activeThumbColor
            ),
            isThreeLine: true,
            onTap: () => _showScriptForm(script),
            onLongPress: () => _confirmDelete(script),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(UserScript script) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Delete Script', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${script.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await widget.service.deleteScript(script.id);
      _loadScripts();
    }
  }

  void _showScriptForm(UserScript? existingScript) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ScriptFormSheet(
          existingScript: existingScript,
          profileId: widget.profileId,
          service: widget.service,
          onSaved: _loadScripts,
        ),
      ),
    );
  }
}

class ScriptFormSheet extends StatefulWidget {
  final UserScript? existingScript;
  final String profileId;
  final UserScriptService service;
  final VoidCallback onSaved;

  const ScriptFormSheet({
    super.key,
    this.existingScript,
    required this.profileId,
    required this.service,
    required this.onSaved,
  });

  @override
  State<ScriptFormSheet> createState() => _ScriptFormSheetState();
}

class _ScriptFormSheetState extends State<ScriptFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _jsCtrl = TextEditingController();
  String _runAt = 'document_idle';

  @override
  void initState() {
    super.initState();
    if (widget.existingScript != null) {
      _nameCtrl.text = widget.existingScript!.name;
      _urlCtrl.text = widget.existingScript!.urlPattern;
      _jsCtrl.text = widget.existingScript!.jsPayload;
      _runAt = widget.existingScript!.runAt;
    } else {
      _urlCtrl.text = '.*'; // Default match all
      // Default auto-claim example script
      _jsCtrl.text = '''(function() {
  console.log("UserScript running...");
  // Add your javascript automation here
})();''';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _jsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existingScript == null ? 'New UserScript' : 'Edit UserScript',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: _deco('Script Name', Icons.title),
              style: const TextStyle(color: Colors.white),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlCtrl,
              decoration: _deco('URL Regex Match', Icons.link),
              style: const TextStyle(color: Colors.white),
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                try {
                  RegExp(v);
                  return null;
                } catch (e) {
                  return 'Invalid Regex';
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _runAt,
              decoration: _deco('Run At', Icons.access_time),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'document_start', child: Text('Document Start (Before load)')),
                DropdownMenuItem(value: 'document_idle', child: Text('Document Idle (After load)')),
              ],
              onChanged: (v) => setState(() => _runAt = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jsCtrl,
              decoration: _deco('JavaScript Payload', Icons.code).copyWith(alignLabelWithHint: true),
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
              maxLines: 10,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Script'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (widget.existingScript != null) {
      final updated = widget.existingScript!.copyWith(
        name: _nameCtrl.text.trim(),
        urlPattern: _urlCtrl.text.trim(),
        jsPayload: _jsCtrl.text.trim(),
        runAt: _runAt,
      );
      await widget.service.updateScript(updated);
    } else {
      await widget.service.createScript(
        profileId: widget.profileId,
        name: _nameCtrl.text.trim(),
        urlPattern: _urlCtrl.text.trim(),
        jsPayload: _jsCtrl.text.trim(),
        runAt: _runAt,
      );
    }
    
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}
