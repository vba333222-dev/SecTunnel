import 'package:pbrowser/core/database/daos/user_script_dao.dart';
import 'package:pbrowser/models/user_script.dart';
import 'package:uuid/uuid.dart';

class UserScriptService {
  final UserScriptDao _dao;
  final _uuid = const Uuid();

  UserScriptService(this._dao);

  Future<List<UserScript>> getScripts(String profileId) {
    return _dao.getScriptsByProfile(profileId);
  }

  Future<List<UserScript>> getActiveScripts(String profileId) {
    return _dao.getActiveScriptsByProfile(profileId);
  }

  Future<void> createScript({
    required String profileId,
    required String name,
    required String urlPattern,
    required String jsPayload,
    required String runAt,
  }) async {
    final script = UserScript(
      id: _uuid.v4(),
      profileId: profileId,
      name: name,
      urlPattern: urlPattern,
      jsPayload: jsPayload,
      runAt: runAt,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _dao.createScript(script);
  }

  Future<void> updateScript(UserScript script) async {
    await _dao.updateScript(script.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteScript(String id) async {
    await _dao.deleteScript(id);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _dao.toggleScriptActive(id, isActive);
  }

  /// Checks if a url matches the user script's regex pattern
  bool matchesUrl(UserScript script, String url) {
    if (script.urlPattern.isEmpty) return false;
    try {
      final regex = RegExp(script.urlPattern, caseSensitive: false);
      return regex.hasMatch(url);
    } catch (e) {
      // Return false if regex fails to compile
      return false;
    }
  }
}
