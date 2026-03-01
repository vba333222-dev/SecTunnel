// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_script_dao.dart';

// ignore_for_file: type=lint
mixin _$UserScriptDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserScriptsTable get userScripts => attachedDatabase.userScripts;
  UserScriptDaoManager get managers => UserScriptDaoManager(this);
}

class UserScriptDaoManager {
  final _$UserScriptDaoMixin _db;
  UserScriptDaoManager(this._db);
  $$UserScriptsTableTableManager get userScripts =>
      $$UserScriptsTableTableManager(_db.attachedDatabase, _db.userScripts);
}
