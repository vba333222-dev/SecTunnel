// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BrowserProfilesTable extends BrowserProfiles
    with TableInfo<$BrowserProfilesTable, BrowserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrowserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _proxyTypeMeta =
      const VerificationMeta('proxyType');
  @override
  late final GeneratedColumn<String> proxyType = GeneratedColumn<String>(
      'proxy_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _proxyHostMeta =
      const VerificationMeta('proxyHost');
  @override
  late final GeneratedColumn<String> proxyHost = GeneratedColumn<String>(
      'proxy_host', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _proxyPortMeta =
      const VerificationMeta('proxyPort');
  @override
  late final GeneratedColumn<int> proxyPort = GeneratedColumn<int>(
      'proxy_port', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _proxyUsernameMeta =
      const VerificationMeta('proxyUsername');
  @override
  late final GeneratedColumn<String> proxyUsername = GeneratedColumn<String>(
      'proxy_username', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _proxyPasswordMeta =
      const VerificationMeta('proxyPassword');
  @override
  late final GeneratedColumn<String> proxyPassword = GeneratedColumn<String>(
      'proxy_password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _proxyRotationUrlMeta =
      const VerificationMeta('proxyRotationUrl');
  @override
  late final GeneratedColumn<String> proxyRotationUrl = GeneratedColumn<String>(
      'proxy_rotation_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fingerprintJsonMeta =
      const VerificationMeta('fingerprintJson');
  @override
  late final GeneratedColumn<String> fingerprintJson = GeneratedColumn<String>(
      'fingerprint_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userDataFolderMeta =
      const VerificationMeta('userDataFolder');
  @override
  late final GeneratedColumn<String> userDataFolder = GeneratedColumn<String>(
      'user_data_folder', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keepAliveEnabledMeta =
      const VerificationMeta('keepAliveEnabled');
  @override
  late final GeneratedColumn<bool> keepAliveEnabled = GeneratedColumn<bool>(
      'keep_alive_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("keep_alive_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _clearBrowsingDataMeta =
      const VerificationMeta('clearBrowsingData');
  @override
  late final GeneratedColumn<bool> clearBrowsingData = GeneratedColumn<bool>(
      'clear_browsing_data', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("clear_browsing_data" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        proxyType,
        proxyHost,
        proxyPort,
        proxyUsername,
        proxyPassword,
        proxyRotationUrl,
        fingerprintJson,
        userDataFolder,
        keepAliveEnabled,
        clearBrowsingData,
        createdAt,
        lastUsedAt,
        tagsJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'browser_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<BrowserProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('proxy_type')) {
      context.handle(_proxyTypeMeta,
          proxyType.isAcceptableOrUnknown(data['proxy_type']!, _proxyTypeMeta));
    } else if (isInserting) {
      context.missing(_proxyTypeMeta);
    }
    if (data.containsKey('proxy_host')) {
      context.handle(_proxyHostMeta,
          proxyHost.isAcceptableOrUnknown(data['proxy_host']!, _proxyHostMeta));
    }
    if (data.containsKey('proxy_port')) {
      context.handle(_proxyPortMeta,
          proxyPort.isAcceptableOrUnknown(data['proxy_port']!, _proxyPortMeta));
    }
    if (data.containsKey('proxy_username')) {
      context.handle(
          _proxyUsernameMeta,
          proxyUsername.isAcceptableOrUnknown(
              data['proxy_username']!, _proxyUsernameMeta));
    }
    if (data.containsKey('proxy_password')) {
      context.handle(
          _proxyPasswordMeta,
          proxyPassword.isAcceptableOrUnknown(
              data['proxy_password']!, _proxyPasswordMeta));
    }
    if (data.containsKey('proxy_rotation_url')) {
      context.handle(
          _proxyRotationUrlMeta,
          proxyRotationUrl.isAcceptableOrUnknown(
              data['proxy_rotation_url']!, _proxyRotationUrlMeta));
    }
    if (data.containsKey('fingerprint_json')) {
      context.handle(
          _fingerprintJsonMeta,
          fingerprintJson.isAcceptableOrUnknown(
              data['fingerprint_json']!, _fingerprintJsonMeta));
    } else if (isInserting) {
      context.missing(_fingerprintJsonMeta);
    }
    if (data.containsKey('user_data_folder')) {
      context.handle(
          _userDataFolderMeta,
          userDataFolder.isAcceptableOrUnknown(
              data['user_data_folder']!, _userDataFolderMeta));
    } else if (isInserting) {
      context.missing(_userDataFolderMeta);
    }
    if (data.containsKey('keep_alive_enabled')) {
      context.handle(
          _keepAliveEnabledMeta,
          keepAliveEnabled.isAcceptableOrUnknown(
              data['keep_alive_enabled']!, _keepAliveEnabledMeta));
    }
    if (data.containsKey('clear_browsing_data')) {
      context.handle(
          _clearBrowsingDataMeta,
          clearBrowsingData.isAcceptableOrUnknown(
              data['clear_browsing_data']!, _clearBrowsingDataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BrowserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrowserProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      proxyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}proxy_type'])!,
      proxyHost: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}proxy_host']),
      proxyPort: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}proxy_port']),
      proxyUsername: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}proxy_username']),
      proxyPassword: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}proxy_password']),
      proxyRotationUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}proxy_rotation_url']),
      fingerprintJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}fingerprint_json'])!,
      userDataFolder: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}user_data_folder'])!,
      keepAliveEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}keep_alive_enabled'])!,
      clearBrowsingData: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}clear_browsing_data'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at'])!,
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json']),
    );
  }

  @override
  $BrowserProfilesTable createAlias(String alias) {
    return $BrowserProfilesTable(attachedDatabase, alias);
  }
}

class BrowserProfile extends DataClass implements Insertable<BrowserProfile> {
  final String id;
  final String name;
  final String proxyType;
  final String? proxyHost;
  final int? proxyPort;
  final String? proxyUsername;
  final String? proxyPassword;
  final String? proxyRotationUrl;
  final String fingerprintJson;
  final String userDataFolder;
  final bool keepAliveEnabled;
  final bool clearBrowsingData;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final String? tagsJson;
  const BrowserProfile(
      {required this.id,
      required this.name,
      required this.proxyType,
      this.proxyHost,
      this.proxyPort,
      this.proxyUsername,
      this.proxyPassword,
      this.proxyRotationUrl,
      required this.fingerprintJson,
      required this.userDataFolder,
      required this.keepAliveEnabled,
      required this.clearBrowsingData,
      required this.createdAt,
      required this.lastUsedAt,
      this.tagsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['proxy_type'] = Variable<String>(proxyType);
    if (!nullToAbsent || proxyHost != null) {
      map['proxy_host'] = Variable<String>(proxyHost);
    }
    if (!nullToAbsent || proxyPort != null) {
      map['proxy_port'] = Variable<int>(proxyPort);
    }
    if (!nullToAbsent || proxyUsername != null) {
      map['proxy_username'] = Variable<String>(proxyUsername);
    }
    if (!nullToAbsent || proxyPassword != null) {
      map['proxy_password'] = Variable<String>(proxyPassword);
    }
    if (!nullToAbsent || proxyRotationUrl != null) {
      map['proxy_rotation_url'] = Variable<String>(proxyRotationUrl);
    }
    map['fingerprint_json'] = Variable<String>(fingerprintJson);
    map['user_data_folder'] = Variable<String>(userDataFolder);
    map['keep_alive_enabled'] = Variable<bool>(keepAliveEnabled);
    map['clear_browsing_data'] = Variable<bool>(clearBrowsingData);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    return map;
  }

  BrowserProfilesCompanion toCompanion(bool nullToAbsent) {
    return BrowserProfilesCompanion(
      id: Value(id),
      name: Value(name),
      proxyType: Value(proxyType),
      proxyHost: proxyHost == null && nullToAbsent
          ? const Value.absent()
          : Value(proxyHost),
      proxyPort: proxyPort == null && nullToAbsent
          ? const Value.absent()
          : Value(proxyPort),
      proxyUsername: proxyUsername == null && nullToAbsent
          ? const Value.absent()
          : Value(proxyUsername),
      proxyPassword: proxyPassword == null && nullToAbsent
          ? const Value.absent()
          : Value(proxyPassword),
      proxyRotationUrl: proxyRotationUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(proxyRotationUrl),
      fingerprintJson: Value(fingerprintJson),
      userDataFolder: Value(userDataFolder),
      keepAliveEnabled: Value(keepAliveEnabled),
      clearBrowsingData: Value(clearBrowsingData),
      createdAt: Value(createdAt),
      lastUsedAt: Value(lastUsedAt),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
    );
  }

  factory BrowserProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrowserProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      proxyType: serializer.fromJson<String>(json['proxyType']),
      proxyHost: serializer.fromJson<String?>(json['proxyHost']),
      proxyPort: serializer.fromJson<int?>(json['proxyPort']),
      proxyUsername: serializer.fromJson<String?>(json['proxyUsername']),
      proxyPassword: serializer.fromJson<String?>(json['proxyPassword']),
      proxyRotationUrl: serializer.fromJson<String?>(json['proxyRotationUrl']),
      fingerprintJson: serializer.fromJson<String>(json['fingerprintJson']),
      userDataFolder: serializer.fromJson<String>(json['userDataFolder']),
      keepAliveEnabled: serializer.fromJson<bool>(json['keepAliveEnabled']),
      clearBrowsingData: serializer.fromJson<bool>(json['clearBrowsingData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'proxyType': serializer.toJson<String>(proxyType),
      'proxyHost': serializer.toJson<String?>(proxyHost),
      'proxyPort': serializer.toJson<int?>(proxyPort),
      'proxyUsername': serializer.toJson<String?>(proxyUsername),
      'proxyPassword': serializer.toJson<String?>(proxyPassword),
      'proxyRotationUrl': serializer.toJson<String?>(proxyRotationUrl),
      'fingerprintJson': serializer.toJson<String>(fingerprintJson),
      'userDataFolder': serializer.toJson<String>(userDataFolder),
      'keepAliveEnabled': serializer.toJson<bool>(keepAliveEnabled),
      'clearBrowsingData': serializer.toJson<bool>(clearBrowsingData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'tagsJson': serializer.toJson<String?>(tagsJson),
    };
  }

  BrowserProfile copyWith(
          {String? id,
          String? name,
          String? proxyType,
          Value<String?> proxyHost = const Value.absent(),
          Value<int?> proxyPort = const Value.absent(),
          Value<String?> proxyUsername = const Value.absent(),
          Value<String?> proxyPassword = const Value.absent(),
          Value<String?> proxyRotationUrl = const Value.absent(),
          String? fingerprintJson,
          String? userDataFolder,
          bool? keepAliveEnabled,
          bool? clearBrowsingData,
          DateTime? createdAt,
          DateTime? lastUsedAt,
          Value<String?> tagsJson = const Value.absent()}) =>
      BrowserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        proxyType: proxyType ?? this.proxyType,
        proxyHost: proxyHost.present ? proxyHost.value : this.proxyHost,
        proxyPort: proxyPort.present ? proxyPort.value : this.proxyPort,
        proxyUsername:
            proxyUsername.present ? proxyUsername.value : this.proxyUsername,
        proxyPassword:
            proxyPassword.present ? proxyPassword.value : this.proxyPassword,
        proxyRotationUrl: proxyRotationUrl.present
            ? proxyRotationUrl.value
            : this.proxyRotationUrl,
        fingerprintJson: fingerprintJson ?? this.fingerprintJson,
        userDataFolder: userDataFolder ?? this.userDataFolder,
        keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
        clearBrowsingData: clearBrowsingData ?? this.clearBrowsingData,
        createdAt: createdAt ?? this.createdAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
      );
  BrowserProfile copyWithCompanion(BrowserProfilesCompanion data) {
    return BrowserProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      proxyType: data.proxyType.present ? data.proxyType.value : this.proxyType,
      proxyHost: data.proxyHost.present ? data.proxyHost.value : this.proxyHost,
      proxyPort: data.proxyPort.present ? data.proxyPort.value : this.proxyPort,
      proxyUsername: data.proxyUsername.present
          ? data.proxyUsername.value
          : this.proxyUsername,
      proxyPassword: data.proxyPassword.present
          ? data.proxyPassword.value
          : this.proxyPassword,
      proxyRotationUrl: data.proxyRotationUrl.present
          ? data.proxyRotationUrl.value
          : this.proxyRotationUrl,
      fingerprintJson: data.fingerprintJson.present
          ? data.fingerprintJson.value
          : this.fingerprintJson,
      userDataFolder: data.userDataFolder.present
          ? data.userDataFolder.value
          : this.userDataFolder,
      keepAliveEnabled: data.keepAliveEnabled.present
          ? data.keepAliveEnabled.value
          : this.keepAliveEnabled,
      clearBrowsingData: data.clearBrowsingData.present
          ? data.clearBrowsingData.value
          : this.clearBrowsingData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrowserProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('proxyType: $proxyType, ')
          ..write('proxyHost: $proxyHost, ')
          ..write('proxyPort: $proxyPort, ')
          ..write('proxyUsername: $proxyUsername, ')
          ..write('proxyPassword: $proxyPassword, ')
          ..write('proxyRotationUrl: $proxyRotationUrl, ')
          ..write('fingerprintJson: $fingerprintJson, ')
          ..write('userDataFolder: $userDataFolder, ')
          ..write('keepAliveEnabled: $keepAliveEnabled, ')
          ..write('clearBrowsingData: $clearBrowsingData, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      proxyType,
      proxyHost,
      proxyPort,
      proxyUsername,
      proxyPassword,
      proxyRotationUrl,
      fingerprintJson,
      userDataFolder,
      keepAliveEnabled,
      clearBrowsingData,
      createdAt,
      lastUsedAt,
      tagsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrowserProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.proxyType == this.proxyType &&
          other.proxyHost == this.proxyHost &&
          other.proxyPort == this.proxyPort &&
          other.proxyUsername == this.proxyUsername &&
          other.proxyPassword == this.proxyPassword &&
          other.proxyRotationUrl == this.proxyRotationUrl &&
          other.fingerprintJson == this.fingerprintJson &&
          other.userDataFolder == this.userDataFolder &&
          other.keepAliveEnabled == this.keepAliveEnabled &&
          other.clearBrowsingData == this.clearBrowsingData &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt &&
          other.tagsJson == this.tagsJson);
}

class BrowserProfilesCompanion extends UpdateCompanion<BrowserProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> proxyType;
  final Value<String?> proxyHost;
  final Value<int?> proxyPort;
  final Value<String?> proxyUsername;
  final Value<String?> proxyPassword;
  final Value<String?> proxyRotationUrl;
  final Value<String> fingerprintJson;
  final Value<String> userDataFolder;
  final Value<bool> keepAliveEnabled;
  final Value<bool> clearBrowsingData;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastUsedAt;
  final Value<String?> tagsJson;
  final Value<int> rowid;
  const BrowserProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.proxyType = const Value.absent(),
    this.proxyHost = const Value.absent(),
    this.proxyPort = const Value.absent(),
    this.proxyUsername = const Value.absent(),
    this.proxyPassword = const Value.absent(),
    this.proxyRotationUrl = const Value.absent(),
    this.fingerprintJson = const Value.absent(),
    this.userDataFolder = const Value.absent(),
    this.keepAliveEnabled = const Value.absent(),
    this.clearBrowsingData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrowserProfilesCompanion.insert({
    required String id,
    required String name,
    required String proxyType,
    this.proxyHost = const Value.absent(),
    this.proxyPort = const Value.absent(),
    this.proxyUsername = const Value.absent(),
    this.proxyPassword = const Value.absent(),
    this.proxyRotationUrl = const Value.absent(),
    required String fingerprintJson,
    required String userDataFolder,
    this.keepAliveEnabled = const Value.absent(),
    this.clearBrowsingData = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastUsedAt,
    this.tagsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        proxyType = Value(proxyType),
        fingerprintJson = Value(fingerprintJson),
        userDataFolder = Value(userDataFolder),
        createdAt = Value(createdAt),
        lastUsedAt = Value(lastUsedAt);
  static Insertable<BrowserProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? proxyType,
    Expression<String>? proxyHost,
    Expression<int>? proxyPort,
    Expression<String>? proxyUsername,
    Expression<String>? proxyPassword,
    Expression<String>? proxyRotationUrl,
    Expression<String>? fingerprintJson,
    Expression<String>? userDataFolder,
    Expression<bool>? keepAliveEnabled,
    Expression<bool>? clearBrowsingData,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUsedAt,
    Expression<String>? tagsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (proxyType != null) 'proxy_type': proxyType,
      if (proxyHost != null) 'proxy_host': proxyHost,
      if (proxyPort != null) 'proxy_port': proxyPort,
      if (proxyUsername != null) 'proxy_username': proxyUsername,
      if (proxyPassword != null) 'proxy_password': proxyPassword,
      if (proxyRotationUrl != null) 'proxy_rotation_url': proxyRotationUrl,
      if (fingerprintJson != null) 'fingerprint_json': fingerprintJson,
      if (userDataFolder != null) 'user_data_folder': userDataFolder,
      if (keepAliveEnabled != null) 'keep_alive_enabled': keepAliveEnabled,
      if (clearBrowsingData != null) 'clear_browsing_data': clearBrowsingData,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrowserProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? proxyType,
      Value<String?>? proxyHost,
      Value<int?>? proxyPort,
      Value<String?>? proxyUsername,
      Value<String?>? proxyPassword,
      Value<String?>? proxyRotationUrl,
      Value<String>? fingerprintJson,
      Value<String>? userDataFolder,
      Value<bool>? keepAliveEnabled,
      Value<bool>? clearBrowsingData,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastUsedAt,
      Value<String?>? tagsJson,
      Value<int>? rowid}) {
    return BrowserProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      proxyUsername: proxyUsername ?? this.proxyUsername,
      proxyPassword: proxyPassword ?? this.proxyPassword,
      proxyRotationUrl: proxyRotationUrl ?? this.proxyRotationUrl,
      fingerprintJson: fingerprintJson ?? this.fingerprintJson,
      userDataFolder: userDataFolder ?? this.userDataFolder,
      keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
      clearBrowsingData: clearBrowsingData ?? this.clearBrowsingData,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      tagsJson: tagsJson ?? this.tagsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (proxyType.present) {
      map['proxy_type'] = Variable<String>(proxyType.value);
    }
    if (proxyHost.present) {
      map['proxy_host'] = Variable<String>(proxyHost.value);
    }
    if (proxyPort.present) {
      map['proxy_port'] = Variable<int>(proxyPort.value);
    }
    if (proxyUsername.present) {
      map['proxy_username'] = Variable<String>(proxyUsername.value);
    }
    if (proxyPassword.present) {
      map['proxy_password'] = Variable<String>(proxyPassword.value);
    }
    if (proxyRotationUrl.present) {
      map['proxy_rotation_url'] = Variable<String>(proxyRotationUrl.value);
    }
    if (fingerprintJson.present) {
      map['fingerprint_json'] = Variable<String>(fingerprintJson.value);
    }
    if (userDataFolder.present) {
      map['user_data_folder'] = Variable<String>(userDataFolder.value);
    }
    if (keepAliveEnabled.present) {
      map['keep_alive_enabled'] = Variable<bool>(keepAliveEnabled.value);
    }
    if (clearBrowsingData.present) {
      map['clear_browsing_data'] = Variable<bool>(clearBrowsingData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrowserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('proxyType: $proxyType, ')
          ..write('proxyHost: $proxyHost, ')
          ..write('proxyPort: $proxyPort, ')
          ..write('proxyUsername: $proxyUsername, ')
          ..write('proxyPassword: $proxyPassword, ')
          ..write('proxyRotationUrl: $proxyRotationUrl, ')
          ..write('fingerprintJson: $fingerprintJson, ')
          ..write('userDataFolder: $userDataFolder, ')
          ..write('keepAliveEnabled: $keepAliveEnabled, ')
          ..write('clearBrowsingData: $clearBrowsingData, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserScriptsTable extends UserScripts
    with TableInfo<$UserScriptsTable, UserScriptEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserScriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlPatternMeta =
      const VerificationMeta('urlPattern');
  @override
  late final GeneratedColumn<String> urlPattern = GeneratedColumn<String>(
      'url_pattern', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsPayloadMeta =
      const VerificationMeta('jsPayload');
  @override
  late final GeneratedColumn<String> jsPayload = GeneratedColumn<String>(
      'js_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _runAtMeta = const VerificationMeta('runAt');
  @override
  late final GeneratedColumn<String> runAt = GeneratedColumn<String>(
      'run_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('document_idle'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        urlPattern,
        jsPayload,
        isActive,
        runAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_scripts';
  @override
  VerificationContext validateIntegrity(Insertable<UserScriptEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url_pattern')) {
      context.handle(
          _urlPatternMeta,
          urlPattern.isAcceptableOrUnknown(
              data['url_pattern']!, _urlPatternMeta));
    } else if (isInserting) {
      context.missing(_urlPatternMeta);
    }
    if (data.containsKey('js_payload')) {
      context.handle(_jsPayloadMeta,
          jsPayload.isAcceptableOrUnknown(data['js_payload']!, _jsPayloadMeta));
    } else if (isInserting) {
      context.missing(_jsPayloadMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('run_at')) {
      context.handle(
          _runAtMeta, runAt.isAcceptableOrUnknown(data['run_at']!, _runAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserScriptEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserScriptEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      urlPattern: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url_pattern'])!,
      jsPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}js_payload'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      runAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserScriptsTable createAlias(String alias) {
    return $UserScriptsTable(attachedDatabase, alias);
  }
}

class UserScriptEntity extends DataClass
    implements Insertable<UserScriptEntity> {
  final String id;
  final String profileId;
  final String name;
  final String urlPattern;
  final String jsPayload;
  final bool isActive;
  final String runAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserScriptEntity(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.urlPattern,
      required this.jsPayload,
      required this.isActive,
      required this.runAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['url_pattern'] = Variable<String>(urlPattern);
    map['js_payload'] = Variable<String>(jsPayload);
    map['is_active'] = Variable<bool>(isActive);
    map['run_at'] = Variable<String>(runAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserScriptsCompanion toCompanion(bool nullToAbsent) {
    return UserScriptsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      urlPattern: Value(urlPattern),
      jsPayload: Value(jsPayload),
      isActive: Value(isActive),
      runAt: Value(runAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserScriptEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserScriptEntity(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      urlPattern: serializer.fromJson<String>(json['urlPattern']),
      jsPayload: serializer.fromJson<String>(json['jsPayload']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      runAt: serializer.fromJson<String>(json['runAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'urlPattern': serializer.toJson<String>(urlPattern),
      'jsPayload': serializer.toJson<String>(jsPayload),
      'isActive': serializer.toJson<bool>(isActive),
      'runAt': serializer.toJson<String>(runAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserScriptEntity copyWith(
          {String? id,
          String? profileId,
          String? name,
          String? urlPattern,
          String? jsPayload,
          bool? isActive,
          String? runAt,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      UserScriptEntity(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        urlPattern: urlPattern ?? this.urlPattern,
        jsPayload: jsPayload ?? this.jsPayload,
        isActive: isActive ?? this.isActive,
        runAt: runAt ?? this.runAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UserScriptEntity copyWithCompanion(UserScriptsCompanion data) {
    return UserScriptEntity(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      urlPattern:
          data.urlPattern.present ? data.urlPattern.value : this.urlPattern,
      jsPayload: data.jsPayload.present ? data.jsPayload.value : this.jsPayload,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      runAt: data.runAt.present ? data.runAt.value : this.runAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserScriptEntity(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('urlPattern: $urlPattern, ')
          ..write('jsPayload: $jsPayload, ')
          ..write('isActive: $isActive, ')
          ..write('runAt: $runAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, name, urlPattern, jsPayload,
      isActive, runAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserScriptEntity &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.urlPattern == this.urlPattern &&
          other.jsPayload == this.jsPayload &&
          other.isActive == this.isActive &&
          other.runAt == this.runAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserScriptsCompanion extends UpdateCompanion<UserScriptEntity> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<String> urlPattern;
  final Value<String> jsPayload;
  final Value<bool> isActive;
  final Value<String> runAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserScriptsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.urlPattern = const Value.absent(),
    this.jsPayload = const Value.absent(),
    this.isActive = const Value.absent(),
    this.runAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserScriptsCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    required String urlPattern,
    required String jsPayload,
    this.isActive = const Value.absent(),
    this.runAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        name = Value(name),
        urlPattern = Value(urlPattern),
        jsPayload = Value(jsPayload),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<UserScriptEntity> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<String>? urlPattern,
    Expression<String>? jsPayload,
    Expression<bool>? isActive,
    Expression<String>? runAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (urlPattern != null) 'url_pattern': urlPattern,
      if (jsPayload != null) 'js_payload': jsPayload,
      if (isActive != null) 'is_active': isActive,
      if (runAt != null) 'run_at': runAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserScriptsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? name,
      Value<String>? urlPattern,
      Value<String>? jsPayload,
      Value<bool>? isActive,
      Value<String>? runAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserScriptsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      urlPattern: urlPattern ?? this.urlPattern,
      jsPayload: jsPayload ?? this.jsPayload,
      isActive: isActive ?? this.isActive,
      runAt: runAt ?? this.runAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (urlPattern.present) {
      map['url_pattern'] = Variable<String>(urlPattern.value);
    }
    if (jsPayload.present) {
      map['js_payload'] = Variable<String>(jsPayload.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (runAt.present) {
      map['run_at'] = Variable<String>(runAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserScriptsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('urlPattern: $urlPattern, ')
          ..write('jsPayload: $jsPayload, ')
          ..write('isActive: $isActive, ')
          ..write('runAt: $runAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BrowserProfilesTable browserProfiles =
      $BrowserProfilesTable(this);
  late final $UserScriptsTable userScripts = $UserScriptsTable(this);
  late final UserScriptDao userScriptDao = UserScriptDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [browserProfiles, userScripts];
}

typedef $$BrowserProfilesTableCreateCompanionBuilder = BrowserProfilesCompanion
    Function({
  required String id,
  required String name,
  required String proxyType,
  Value<String?> proxyHost,
  Value<int?> proxyPort,
  Value<String?> proxyUsername,
  Value<String?> proxyPassword,
  Value<String?> proxyRotationUrl,
  required String fingerprintJson,
  required String userDataFolder,
  Value<bool> keepAliveEnabled,
  Value<bool> clearBrowsingData,
  required DateTime createdAt,
  required DateTime lastUsedAt,
  Value<String?> tagsJson,
  Value<int> rowid,
});
typedef $$BrowserProfilesTableUpdateCompanionBuilder = BrowserProfilesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> proxyType,
  Value<String?> proxyHost,
  Value<int?> proxyPort,
  Value<String?> proxyUsername,
  Value<String?> proxyPassword,
  Value<String?> proxyRotationUrl,
  Value<String> fingerprintJson,
  Value<String> userDataFolder,
  Value<bool> keepAliveEnabled,
  Value<bool> clearBrowsingData,
  Value<DateTime> createdAt,
  Value<DateTime> lastUsedAt,
  Value<String?> tagsJson,
  Value<int> rowid,
});

class $$BrowserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BrowserProfilesTable> {
  $$BrowserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proxyType => $composableBuilder(
      column: $table.proxyType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proxyHost => $composableBuilder(
      column: $table.proxyHost, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get proxyPort => $composableBuilder(
      column: $table.proxyPort, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proxyUsername => $composableBuilder(
      column: $table.proxyUsername, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proxyPassword => $composableBuilder(
      column: $table.proxyPassword, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proxyRotationUrl => $composableBuilder(
      column: $table.proxyRotationUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprintJson => $composableBuilder(
      column: $table.fingerprintJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userDataFolder => $composableBuilder(
      column: $table.userDataFolder,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get keepAliveEnabled => $composableBuilder(
      column: $table.keepAliveEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get clearBrowsingData => $composableBuilder(
      column: $table.clearBrowsingData,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));
}

class $$BrowserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BrowserProfilesTable> {
  $$BrowserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proxyType => $composableBuilder(
      column: $table.proxyType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proxyHost => $composableBuilder(
      column: $table.proxyHost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get proxyPort => $composableBuilder(
      column: $table.proxyPort, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proxyUsername => $composableBuilder(
      column: $table.proxyUsername,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proxyPassword => $composableBuilder(
      column: $table.proxyPassword,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proxyRotationUrl => $composableBuilder(
      column: $table.proxyRotationUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprintJson => $composableBuilder(
      column: $table.fingerprintJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userDataFolder => $composableBuilder(
      column: $table.userDataFolder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get keepAliveEnabled => $composableBuilder(
      column: $table.keepAliveEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get clearBrowsingData => $composableBuilder(
      column: $table.clearBrowsingData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));
}

class $$BrowserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrowserProfilesTable> {
  $$BrowserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get proxyType =>
      $composableBuilder(column: $table.proxyType, builder: (column) => column);

  GeneratedColumn<String> get proxyHost =>
      $composableBuilder(column: $table.proxyHost, builder: (column) => column);

  GeneratedColumn<int> get proxyPort =>
      $composableBuilder(column: $table.proxyPort, builder: (column) => column);

  GeneratedColumn<String> get proxyUsername => $composableBuilder(
      column: $table.proxyUsername, builder: (column) => column);

  GeneratedColumn<String> get proxyPassword => $composableBuilder(
      column: $table.proxyPassword, builder: (column) => column);

  GeneratedColumn<String> get proxyRotationUrl => $composableBuilder(
      column: $table.proxyRotationUrl, builder: (column) => column);

  GeneratedColumn<String> get fingerprintJson => $composableBuilder(
      column: $table.fingerprintJson, builder: (column) => column);

  GeneratedColumn<String> get userDataFolder => $composableBuilder(
      column: $table.userDataFolder, builder: (column) => column);

  GeneratedColumn<bool> get keepAliveEnabled => $composableBuilder(
      column: $table.keepAliveEnabled, builder: (column) => column);

  GeneratedColumn<bool> get clearBrowsingData => $composableBuilder(
      column: $table.clearBrowsingData, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);
}

class $$BrowserProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BrowserProfilesTable,
    BrowserProfile,
    $$BrowserProfilesTableFilterComposer,
    $$BrowserProfilesTableOrderingComposer,
    $$BrowserProfilesTableAnnotationComposer,
    $$BrowserProfilesTableCreateCompanionBuilder,
    $$BrowserProfilesTableUpdateCompanionBuilder,
    (
      BrowserProfile,
      BaseReferences<_$AppDatabase, $BrowserProfilesTable, BrowserProfile>
    ),
    BrowserProfile,
    PrefetchHooks Function()> {
  $$BrowserProfilesTableTableManager(
      _$AppDatabase db, $BrowserProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrowserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrowserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrowserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> proxyType = const Value.absent(),
            Value<String?> proxyHost = const Value.absent(),
            Value<int?> proxyPort = const Value.absent(),
            Value<String?> proxyUsername = const Value.absent(),
            Value<String?> proxyPassword = const Value.absent(),
            Value<String?> proxyRotationUrl = const Value.absent(),
            Value<String> fingerprintJson = const Value.absent(),
            Value<String> userDataFolder = const Value.absent(),
            Value<bool> keepAliveEnabled = const Value.absent(),
            Value<bool> clearBrowsingData = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastUsedAt = const Value.absent(),
            Value<String?> tagsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BrowserProfilesCompanion(
            id: id,
            name: name,
            proxyType: proxyType,
            proxyHost: proxyHost,
            proxyPort: proxyPort,
            proxyUsername: proxyUsername,
            proxyPassword: proxyPassword,
            proxyRotationUrl: proxyRotationUrl,
            fingerprintJson: fingerprintJson,
            userDataFolder: userDataFolder,
            keepAliveEnabled: keepAliveEnabled,
            clearBrowsingData: clearBrowsingData,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            tagsJson: tagsJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String proxyType,
            Value<String?> proxyHost = const Value.absent(),
            Value<int?> proxyPort = const Value.absent(),
            Value<String?> proxyUsername = const Value.absent(),
            Value<String?> proxyPassword = const Value.absent(),
            Value<String?> proxyRotationUrl = const Value.absent(),
            required String fingerprintJson,
            required String userDataFolder,
            Value<bool> keepAliveEnabled = const Value.absent(),
            Value<bool> clearBrowsingData = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastUsedAt,
            Value<String?> tagsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BrowserProfilesCompanion.insert(
            id: id,
            name: name,
            proxyType: proxyType,
            proxyHost: proxyHost,
            proxyPort: proxyPort,
            proxyUsername: proxyUsername,
            proxyPassword: proxyPassword,
            proxyRotationUrl: proxyRotationUrl,
            fingerprintJson: fingerprintJson,
            userDataFolder: userDataFolder,
            keepAliveEnabled: keepAliveEnabled,
            clearBrowsingData: clearBrowsingData,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            tagsJson: tagsJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BrowserProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BrowserProfilesTable,
    BrowserProfile,
    $$BrowserProfilesTableFilterComposer,
    $$BrowserProfilesTableOrderingComposer,
    $$BrowserProfilesTableAnnotationComposer,
    $$BrowserProfilesTableCreateCompanionBuilder,
    $$BrowserProfilesTableUpdateCompanionBuilder,
    (
      BrowserProfile,
      BaseReferences<_$AppDatabase, $BrowserProfilesTable, BrowserProfile>
    ),
    BrowserProfile,
    PrefetchHooks Function()>;
typedef $$UserScriptsTableCreateCompanionBuilder = UserScriptsCompanion
    Function({
  required String id,
  required String profileId,
  required String name,
  required String urlPattern,
  required String jsPayload,
  Value<bool> isActive,
  Value<String> runAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UserScriptsTableUpdateCompanionBuilder = UserScriptsCompanion
    Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> name,
  Value<String> urlPattern,
  Value<String> jsPayload,
  Value<bool> isActive,
  Value<String> runAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserScriptsTableFilterComposer
    extends Composer<_$AppDatabase, $UserScriptsTable> {
  $$UserScriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get urlPattern => $composableBuilder(
      column: $table.urlPattern, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jsPayload => $composableBuilder(
      column: $table.jsPayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get runAt => $composableBuilder(
      column: $table.runAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserScriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserScriptsTable> {
  $$UserScriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get urlPattern => $composableBuilder(
      column: $table.urlPattern, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jsPayload => $composableBuilder(
      column: $table.jsPayload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get runAt => $composableBuilder(
      column: $table.runAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserScriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserScriptsTable> {
  $$UserScriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get urlPattern => $composableBuilder(
      column: $table.urlPattern, builder: (column) => column);

  GeneratedColumn<String> get jsPayload =>
      $composableBuilder(column: $table.jsPayload, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get runAt =>
      $composableBuilder(column: $table.runAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserScriptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserScriptsTable,
    UserScriptEntity,
    $$UserScriptsTableFilterComposer,
    $$UserScriptsTableOrderingComposer,
    $$UserScriptsTableAnnotationComposer,
    $$UserScriptsTableCreateCompanionBuilder,
    $$UserScriptsTableUpdateCompanionBuilder,
    (
      UserScriptEntity,
      BaseReferences<_$AppDatabase, $UserScriptsTable, UserScriptEntity>
    ),
    UserScriptEntity,
    PrefetchHooks Function()> {
  $$UserScriptsTableTableManager(_$AppDatabase db, $UserScriptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserScriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserScriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserScriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> urlPattern = const Value.absent(),
            Value<String> jsPayload = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> runAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserScriptsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            urlPattern: urlPattern,
            jsPayload: jsPayload,
            isActive: isActive,
            runAt: runAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String name,
            required String urlPattern,
            required String jsPayload,
            Value<bool> isActive = const Value.absent(),
            Value<String> runAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserScriptsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            urlPattern: urlPattern,
            jsPayload: jsPayload,
            isActive: isActive,
            runAt: runAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserScriptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserScriptsTable,
    UserScriptEntity,
    $$UserScriptsTableFilterComposer,
    $$UserScriptsTableOrderingComposer,
    $$UserScriptsTableAnnotationComposer,
    $$UserScriptsTableCreateCompanionBuilder,
    $$UserScriptsTableUpdateCompanionBuilder,
    (
      UserScriptEntity,
      BaseReferences<_$AppDatabase, $UserScriptsTable, UserScriptEntity>
    ),
    UserScriptEntity,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BrowserProfilesTableTableManager get browserProfiles =>
      $$BrowserProfilesTableTableManager(_db, _db.browserProfiles);
  $$UserScriptsTableTableManager get userScripts =>
      $$UserScriptsTableTableManager(_db, _db.userScripts);
}
