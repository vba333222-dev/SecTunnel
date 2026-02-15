import 'package:flutter/material.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:pbrowser/repositories/profile_repository.dart';
import 'package:pbrowser/ui/profile/profile_form_screen.dart';
import 'package:pbrowser/ui/browser/browser_screen.dart';
import 'package:pbrowser/ui/dashboard/widgets/profile_card.dart';

class DashboardScreen extends StatelessWidget {
  final ProfileRepository repository;
  
  const DashboardScreen({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'PBrowser',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Profile Manager',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: 'Create New Profile',
            onPressed: () => _createNewProfile(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<BrowserProfile>>(
        stream: repository.watchAllProfiles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            );
          }
          
          final profiles = snapshot.data!;
          
          if (profiles.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              return ProfileCard(
                profile: profiles[index],
                onRun: () => _launchBrowser(context, profiles[index]),
                onEdit: () => _editProfile(context, profiles[index]),
                onDelete: () => _deleteProfile(context, profiles[index]),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 100,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Profiles Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create your first browser profile to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _createNewProfile(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _createNewProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(repository: repository),
      ),
    );
  }
  
  void _editProfile(BuildContext context, BrowserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(
          repository: repository,
          existingProfile: profile,
        ),
      ),
    );
  }
  
  Future<void> _launchBrowser(BuildContext context, BrowserProfile profile) async {
    // Mark as used
    await repository.markAsUsed(profile.id);
    
    // Navigate to browser screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BrowserScreen(profile: profile),
        ),
      );
    }
  }
  
  Future<void> _deleteProfile(BuildContext context, BrowserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text('Are you sure you want to delete "${profile.name}"? This will also delete all associated browser data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await repository.deleteProfile(profile.id);
    }
  }
}
