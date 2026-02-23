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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        proxyType,
        proxyHost,
        proxyPort,
        proxyUsername,
        proxyPassword,
        fingerprintJson,
        userDataFolder,
        createdAt,
        lastUsedAt
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
      fingerprintJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}fingerprint_json'])!,
      userDataFolder: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}user_data_folder'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at'])!,
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
  final String fingerprintJson;
  final String userDataFolder;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  const BrowserProfile(
      {required this.id,
      required this.name,
      required this.proxyType,
      this.proxyHost,
      this.proxyPort,
      this.proxyUsername,
      this.proxyPassword,
      required this.fingerprintJson,
      required this.userDataFolder,
      required this.createdAt,
      required this.lastUsedAt});
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
    map['fingerprint_json'] = Variable<String>(fingerprintJson);
    map['user_data_folder'] = Variable<String>(userDataFolder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
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
      fingerprintJson: Value(fingerprintJson),
      userDataFolder: Value(userDataFolder),
      createdAt: Value(createdAt),
      lastUsedAt: Value(lastUsedAt),
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
      fingerprintJson: serializer.fromJson<String>(json['fingerprintJson']),
      userDataFolder: serializer.fromJson<String>(json['userDataFolder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
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
      'fingerprintJson': serializer.toJson<String>(fingerprintJson),
      'userDataFolder': serializer.toJson<String>(userDataFolder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
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
          String? fingerprintJson,
          String? userDataFolder,
          DateTime? createdAt,
          DateTime? lastUsedAt}) =>
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
        fingerprintJson: fingerprintJson ?? this.fingerprintJson,
        userDataFolder: userDataFolder ?? this.userDataFolder,
        createdAt: createdAt ?? this.createdAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
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
      fingerprintJson: data.fingerprintJson.present
          ? data.fingerprintJson.value
          : this.fingerprintJson,
      userDataFolder: data.userDataFolder.present
          ? data.userDataFolder.value
          : this.userDataFolder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
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
          ..write('fingerprintJson: $fingerprintJson, ')
          ..write('userDataFolder: $userDataFolder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
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
      fingerprintJson,
      userDataFolder,
      createdAt,
      lastUsedAt);
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
          other.fingerprintJson == this.fingerprintJson &&
          other.userDataFolder == this.userDataFolder &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class BrowserProfilesCompanion extends UpdateCompanion<BrowserProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> proxyType;
  final Value<String?> proxyHost;
  final Value<int?> proxyPort;
  final Value<String?> proxyUsername;
  final Value<String?> proxyPassword;
  final Value<String> fingerprintJson;
  final Value<String> userDataFolder;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const BrowserProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.proxyType = const Value.absent(),
    this.proxyHost = const Value.absent(),
    this.proxyPort = const Value.absent(),
    this.proxyUsername = const Value.absent(),
    this.proxyPassword = const Value.absent(),
    this.fingerprintJson = const Value.absent(),
    this.userDataFolder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
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
    required String fingerprintJson,
    required String userDataFolder,
    required DateTime createdAt,
    required DateTime lastUsedAt,
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
    Expression<String>? fingerprintJson,
    Expression<String>? userDataFolder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUsedAt,
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
      if (fingerprintJson != null) 'fingerprint_json': fingerprintJson,
      if (userDataFolder != null) 'user_data_folder': userDataFolder,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
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
      Value<String>? fingerprintJson,
      Value<String>? userDataFolder,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastUsedAt,
      Value<int>? rowid}) {
    return BrowserProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      proxyUsername: proxyUsername ?? this.proxyUsername,
      proxyPassword: proxyPassword ?? this.proxyPassword,
      fingerprintJson: fingerprintJson ?? this.fingerprintJson,
      userDataFolder: userDataFolder ?? this.userDataFolder,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
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
    if (fingerprintJson.present) {
      map['fingerprint_json'] = Variable<String>(fingerprintJson.value);
    }
    if (userDataFolder.present) {
      map['user_data_folder'] = Variable<String>(userDataFolder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
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
          ..write('fingerprintJson: $fingerprintJson, ')
          ..write('userDataFolder: $userDataFolder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [browserProfiles];
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
  required String fingerprintJson,
  required String userDataFolder,
  required DateTime createdAt,
  required DateTime lastUsedAt,
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
  Value<String> fingerprintJson,
  Value<String> userDataFolder,
  Value<DateTime> createdAt,
  Value<DateTime> lastUsedAt,
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

  ColumnFilters<String> get fingerprintJson => $composableBuilder(
      column: $table.fingerprintJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userDataFolder => $composableBuilder(
      column: $table.userDataFolder,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get fingerprintJson => $composableBuilder(
      column: $table.fingerprintJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userDataFolder => $composableBuilder(
      column: $table.userDataFolder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get fingerprintJson => $composableBuilder(
      column: $table.fingerprintJson, builder: (column) => column);

  GeneratedColumn<String> get userDataFolder => $composableBuilder(
      column: $table.userDataFolder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);
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
            Value<String> fingerprintJson = const Value.absent(),
            Value<String> userDataFolder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastUsedAt = const Value.absent(),
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
            fingerprintJson: fingerprintJson,
            userDataFolder: userDataFolder,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
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
            required String fingerprintJson,
            required String userDataFolder,
            required DateTime createdAt,
            required DateTime lastUsedAt,
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
            fingerprintJson: fingerprintJson,
            userDataFolder: userDataFolder,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BrowserProfilesTableTableManager get browserProfiles =>
      $$BrowserProfilesTableTableManager(_db, _db.browserProfiles);
}
