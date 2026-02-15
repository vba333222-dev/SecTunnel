import 'package:pbrowser/core/database/daos/profile_dao.dart';
import 'package:pbrowser/models/browser_profile.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Business logic layer for profile management
class ProfileRepository {
  final ProfileDao _profileDao;
  final _uuid = const Uuid();
  
  ProfileRepository(this._profileDao);
  
  Stream<List<BrowserProfile>> watchAllProfiles() => _profileDao.watchAllProfiles();
  
  Future<List<BrowserProfile>> getAllProfiles() => _profileDao.getAllProfiles();
  
  Future<BrowserProfile?> getProfileById(String id) => _profileDao.getProfileById(id);
  
  Future<void> createProfile(BrowserProfile profile) async {
    // Ensure user data folder exists
    final folder = Directory(profile.userDataFolder);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    
    await _profileDao.createProfile(profile);
  }
  
  Future<void> updateProfile(BrowserProfile profile) => _profileDao.updateProfile(profile);
  
  Future<void> deleteProfile(String id) async {
    final profile = await _profileDao.getProfileById(id);
    if (profile != null) {
      // Delete user data folder
      final folder = Directory(profile.userDataFolder);
      if (await folder.exists()) {
        await folder.delete(recursive: true);
      }
      
      await _profileDao.deleteProfile(id);
    }
  }
  
  Future<void> markAsUsed(String id) => _profileDao.updateLastUsed(id);
  
  /// Generate user data folder path for a profile
  Future<String> generateUserDataPath(String profileId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, 'profiles', profileId);
  }
  
  /// Create a new profile ID
  String generateProfileId() => _uuid.v4();
}
