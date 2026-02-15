// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dao.dart';

// ignore_for_file: type=lint
mixin _$ProfileDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrowserProfilesTable get browserProfiles => attachedDatabase.browserProfiles;
  ProfileDaoManager get managers => ProfileDaoManager(this);
}

class ProfileDaoManager {
  final _$ProfileDaoMixin _db;
  ProfileDaoManager(this._db);
  $$BrowserProfilesTableTableManager get browserProfiles =>
      $$BrowserProfilesTableTableManager(
          _db.attachedDatabase, _db.browserProfiles);
}
