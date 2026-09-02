// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalAuthenticatedUsersTable extends LocalAuthenticatedUsers
    with TableInfo<$LocalAuthenticatedUsersTable, LocalAuthenticatedUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAuthenticatedUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nombreVisibleMeta = const VerificationMeta(
    'nombreVisible',
  );
  @override
  late final GeneratedColumn<String> nombreVisible = GeneratedColumn<String>(
    'nombre_visible',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastValidatedAtMeta = const VerificationMeta(
    'lastValidatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastValidatedAt =
      GeneratedColumn<DateTime>(
        'last_validated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _offlineSessionValidUntilMeta =
      const VerificationMeta('offlineSessionValidUntil');
  @override
  late final GeneratedColumn<DateTime> offlineSessionValidUntil =
      GeneratedColumn<DateTime>(
        'offline_session_valid_until',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    nombreVisible,
    city,
    lastValidatedAt,
    offlineSessionValidUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_authenticated_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAuthenticatedUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('nombre_visible')) {
      context.handle(
        _nombreVisibleMeta,
        nombreVisible.isAcceptableOrUnknown(
          data['nombre_visible']!,
          _nombreVisibleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreVisibleMeta);
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('last_validated_at')) {
      context.handle(
        _lastValidatedAtMeta,
        lastValidatedAt.isAcceptableOrUnknown(
          data['last_validated_at']!,
          _lastValidatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastValidatedAtMeta);
    }
    if (data.containsKey('offline_session_valid_until')) {
      context.handle(
        _offlineSessionValidUntilMeta,
        offlineSessionValidUntil.isAcceptableOrUnknown(
          data['offline_session_valid_until']!,
          _offlineSessionValidUntilMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offlineSessionValidUntilMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalAuthenticatedUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAuthenticatedUser(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      nombreVisible: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_visible'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      lastValidatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_validated_at'],
      )!,
      offlineSessionValidUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}offline_session_valid_until'],
      )!,
    );
  }

  @override
  $LocalAuthenticatedUsersTable createAlias(String alias) {
    return $LocalAuthenticatedUsersTable(attachedDatabase, alias);
  }
}

class LocalAuthenticatedUser extends DataClass
    implements Insertable<LocalAuthenticatedUser> {
  final int userId;
  final String nombreVisible;
  final String city;
  final DateTime lastValidatedAt;
  final DateTime offlineSessionValidUntil;
  const LocalAuthenticatedUser({
    required this.userId,
    required this.nombreVisible,
    required this.city,
    required this.lastValidatedAt,
    required this.offlineSessionValidUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['nombre_visible'] = Variable<String>(nombreVisible);
    map['city'] = Variable<String>(city);
    map['last_validated_at'] = Variable<DateTime>(lastValidatedAt);
    map['offline_session_valid_until'] = Variable<DateTime>(
      offlineSessionValidUntil,
    );
    return map;
  }

  LocalAuthenticatedUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalAuthenticatedUsersCompanion(
      userId: Value(userId),
      nombreVisible: Value(nombreVisible),
      city: Value(city),
      lastValidatedAt: Value(lastValidatedAt),
      offlineSessionValidUntil: Value(offlineSessionValidUntil),
    );
  }

  factory LocalAuthenticatedUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAuthenticatedUser(
      userId: serializer.fromJson<int>(json['userId']),
      nombreVisible: serializer.fromJson<String>(json['nombreVisible']),
      city: serializer.fromJson<String>(json['city']),
      lastValidatedAt: serializer.fromJson<DateTime>(json['lastValidatedAt']),
      offlineSessionValidUntil: serializer.fromJson<DateTime>(
        json['offlineSessionValidUntil'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'nombreVisible': serializer.toJson<String>(nombreVisible),
      'city': serializer.toJson<String>(city),
      'lastValidatedAt': serializer.toJson<DateTime>(lastValidatedAt),
      'offlineSessionValidUntil': serializer.toJson<DateTime>(
        offlineSessionValidUntil,
      ),
    };
  }

  LocalAuthenticatedUser copyWith({
    int? userId,
    String? nombreVisible,
    String? city,
    DateTime? lastValidatedAt,
    DateTime? offlineSessionValidUntil,
  }) => LocalAuthenticatedUser(
    userId: userId ?? this.userId,
    nombreVisible: nombreVisible ?? this.nombreVisible,
    city: city ?? this.city,
    lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
    offlineSessionValidUntil:
        offlineSessionValidUntil ?? this.offlineSessionValidUntil,
  );
  LocalAuthenticatedUser copyWithCompanion(
    LocalAuthenticatedUsersCompanion data,
  ) {
    return LocalAuthenticatedUser(
      userId: data.userId.present ? data.userId.value : this.userId,
      nombreVisible: data.nombreVisible.present
          ? data.nombreVisible.value
          : this.nombreVisible,
      city: data.city.present ? data.city.value : this.city,
      lastValidatedAt: data.lastValidatedAt.present
          ? data.lastValidatedAt.value
          : this.lastValidatedAt,
      offlineSessionValidUntil: data.offlineSessionValidUntil.present
          ? data.offlineSessionValidUntil.value
          : this.offlineSessionValidUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAuthenticatedUser(')
          ..write('userId: $userId, ')
          ..write('nombreVisible: $nombreVisible, ')
          ..write('city: $city, ')
          ..write('lastValidatedAt: $lastValidatedAt, ')
          ..write('offlineSessionValidUntil: $offlineSessionValidUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    nombreVisible,
    city,
    lastValidatedAt,
    offlineSessionValidUntil,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAuthenticatedUser &&
          other.userId == this.userId &&
          other.nombreVisible == this.nombreVisible &&
          other.city == this.city &&
          other.lastValidatedAt == this.lastValidatedAt &&
          other.offlineSessionValidUntil == this.offlineSessionValidUntil);
}

class LocalAuthenticatedUsersCompanion
    extends UpdateCompanion<LocalAuthenticatedUser> {
  final Value<int> userId;
  final Value<String> nombreVisible;
  final Value<String> city;
  final Value<DateTime> lastValidatedAt;
  final Value<DateTime> offlineSessionValidUntil;
  const LocalAuthenticatedUsersCompanion({
    this.userId = const Value.absent(),
    this.nombreVisible = const Value.absent(),
    this.city = const Value.absent(),
    this.lastValidatedAt = const Value.absent(),
    this.offlineSessionValidUntil = const Value.absent(),
  });
  LocalAuthenticatedUsersCompanion.insert({
    this.userId = const Value.absent(),
    required String nombreVisible,
    required String city,
    required DateTime lastValidatedAt,
    required DateTime offlineSessionValidUntil,
  }) : nombreVisible = Value(nombreVisible),
       city = Value(city),
       lastValidatedAt = Value(lastValidatedAt),
       offlineSessionValidUntil = Value(offlineSessionValidUntil);
  static Insertable<LocalAuthenticatedUser> custom({
    Expression<int>? userId,
    Expression<String>? nombreVisible,
    Expression<String>? city,
    Expression<DateTime>? lastValidatedAt,
    Expression<DateTime>? offlineSessionValidUntil,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (nombreVisible != null) 'nombre_visible': nombreVisible,
      if (city != null) 'city': city,
      if (lastValidatedAt != null) 'last_validated_at': lastValidatedAt,
      if (offlineSessionValidUntil != null)
        'offline_session_valid_until': offlineSessionValidUntil,
    });
  }

  LocalAuthenticatedUsersCompanion copyWith({
    Value<int>? userId,
    Value<String>? nombreVisible,
    Value<String>? city,
    Value<DateTime>? lastValidatedAt,
    Value<DateTime>? offlineSessionValidUntil,
  }) {
    return LocalAuthenticatedUsersCompanion(
      userId: userId ?? this.userId,
      nombreVisible: nombreVisible ?? this.nombreVisible,
      city: city ?? this.city,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
      offlineSessionValidUntil:
          offlineSessionValidUntil ?? this.offlineSessionValidUntil,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (nombreVisible.present) {
      map['nombre_visible'] = Variable<String>(nombreVisible.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (lastValidatedAt.present) {
      map['last_validated_at'] = Variable<DateTime>(lastValidatedAt.value);
    }
    if (offlineSessionValidUntil.present) {
      map['offline_session_valid_until'] = Variable<DateTime>(
        offlineSessionValidUntil.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAuthenticatedUsersCompanion(')
          ..write('userId: $userId, ')
          ..write('nombreVisible: $nombreVisible, ')
          ..write('city: $city, ')
          ..write('lastValidatedAt: $lastValidatedAt, ')
          ..write('offlineSessionValidUntil: $offlineSessionValidUntil')
          ..write(')'))
        .toString();
  }
}

class $LocalCategoriesTable extends LocalCategories
    with TableInfo<$LocalCategoriesTable, LocalCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    remoteId,
    name,
    description,
    lastSyncedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteId};
  @override
  LocalCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCategory(
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $LocalCategoriesTable createAlias(String alias) {
    return $LocalCategoriesTable(attachedDatabase, alias);
  }
}

class LocalCategory extends DataClass implements Insertable<LocalCategory> {
  final int remoteId;
  final String name;
  final String? description;
  final DateTime lastSyncedAt;
  final DateTime expiresAt;
  const LocalCategory({
    required this.remoteId,
    required this.name,
    this.description,
    required this.lastSyncedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_id'] = Variable<int>(remoteId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  LocalCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalCategoriesCompanion(
      remoteId: Value(remoteId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      lastSyncedAt: Value(lastSyncedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory LocalCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCategory(
      remoteId: serializer.fromJson<int>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteId': serializer.toJson<int>(remoteId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  LocalCategory copyWith({
    int? remoteId,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? lastSyncedAt,
    DateTime? expiresAt,
  }) => LocalCategory(
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  LocalCategory copyWithCompanion(LocalCategoriesCompanion data) {
    return LocalCategory(
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategory(')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(remoteId, name, description, lastSyncedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCategory &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.description == this.description &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.expiresAt == this.expiresAt);
}

class LocalCategoriesCompanion extends UpdateCompanion<LocalCategory> {
  final Value<int> remoteId;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> lastSyncedAt;
  final Value<DateTime> expiresAt;
  const LocalCategoriesCompanion({
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  LocalCategoriesCompanion.insert({
    this.remoteId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required DateTime lastSyncedAt,
    required DateTime expiresAt,
  }) : name = Value(name),
       lastSyncedAt = Value(lastSyncedAt),
       expiresAt = Value(expiresAt);
  static Insertable<LocalCategory> custom({
    Expression<int>? remoteId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  LocalCategoriesCompanion copyWith({
    Value<int>? remoteId,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? lastSyncedAt,
    Value<DateTime>? expiresAt,
  }) {
    return LocalCategoriesCompanion(
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategoriesCompanion(')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $LocalDonationsTable extends LocalDonations
    with TableInfo<$LocalDonationsTable, LocalDonation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDonationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cacheUserIdMeta = const VerificationMeta(
    'cacheUserId',
  );
  @override
  late final GeneratedColumn<int> cacheUserId = GeneratedColumn<int>(
    'cache_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailExpiresAtMeta = const VerificationMeta(
    'detailExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> detailExpiresAt =
      GeneratedColumn<DateTime>(
        'detail_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DonationSyncState, String>
  syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DonationSyncState>($LocalDonationsTable.$convertersyncState);
  static const VerificationMeta _locallyDeletedMeta = const VerificationMeta(
    'locallyDeleted',
  );
  @override
  late final GeneratedColumn<bool> locallyDeleted = GeneratedColumn<bool>(
    'locally_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("locally_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mainImageUrlMeta = const VerificationMeta(
    'mainImageUrl',
  );
  @override
  late final GeneratedColumn<String> mainImageUrl = GeneratedColumn<String>(
    'main_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageCountMeta = const VerificationMeta(
    'imageCount',
  );
  @override
  late final GeneratedColumn<int> imageCount = GeneratedColumn<int>(
    'image_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    cacheUserId,
    clientId,
    remoteId,
    lastSyncedAt,
    expiresAt,
    detailExpiresAt,
    syncState,
    locallyDeleted,
    title,
    description,
    city,
    status,
    categoryId,
    categoryName,
    mainImageUrl,
    imageCount,
    createdAt,
    serverUpdatedAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_donations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDonation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('cache_user_id')) {
      context.handle(
        _cacheUserIdMeta,
        cacheUserId.isAcceptableOrUnknown(
          data['cache_user_id']!,
          _cacheUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheUserIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('detail_expires_at')) {
      context.handle(
        _detailExpiresAtMeta,
        detailExpiresAt.isAcceptableOrUnknown(
          data['detail_expires_at']!,
          _detailExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('locally_deleted')) {
      context.handle(
        _locallyDeletedMeta,
        locallyDeleted.isAcceptableOrUnknown(
          data['locally_deleted']!,
          _locallyDeletedMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('main_image_url')) {
      context.handle(
        _mainImageUrlMeta,
        mainImageUrl.isAcceptableOrUnknown(
          data['main_image_url']!,
          _mainImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('image_count')) {
      context.handle(
        _imageCountMeta,
        imageCount.isAcceptableOrUnknown(data['image_count']!, _imageCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cacheUserId, clientId},
    {cacheUserId, remoteId},
  ];
  @override
  LocalDonation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDonation(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_id'],
      )!,
      cacheUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_user_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      detailExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detail_expires_at'],
      ),
      syncState: $LocalDonationsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      locallyDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}locally_deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      mainImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}main_image_url'],
      ),
      imageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}image_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      ),
    );
  }

  @override
  $LocalDonationsTable createAlias(String alias) {
    return $LocalDonationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DonationSyncState, String, String>
  $convertersyncState = const EnumNameConverter<DonationSyncState>(
    DonationSyncState.values,
  );
}

class LocalDonation extends DataClass implements Insertable<LocalDonation> {
  final int localId;
  final int cacheUserId;
  final String clientId;
  final int? remoteId;
  final DateTime? lastSyncedAt;
  final DateTime expiresAt;
  final DateTime? detailExpiresAt;
  final DonationSyncState syncState;
  final bool locallyDeleted;
  final String title;
  final String? description;
  final String city;
  final String? status;
  final int categoryId;
  final String categoryName;
  final String? mainImageUrl;
  final int imageCount;
  final DateTime? createdAt;
  final DateTime? serverUpdatedAt;
  final DateTime? lastAccessedAt;
  const LocalDonation({
    required this.localId,
    required this.cacheUserId,
    required this.clientId,
    this.remoteId,
    this.lastSyncedAt,
    required this.expiresAt,
    this.detailExpiresAt,
    required this.syncState,
    required this.locallyDeleted,
    required this.title,
    this.description,
    required this.city,
    this.status,
    required this.categoryId,
    required this.categoryName,
    this.mainImageUrl,
    required this.imageCount,
    this.createdAt,
    this.serverUpdatedAt,
    this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['cache_user_id'] = Variable<int>(cacheUserId);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || detailExpiresAt != null) {
      map['detail_expires_at'] = Variable<DateTime>(detailExpiresAt);
    }
    {
      map['sync_state'] = Variable<String>(
        $LocalDonationsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['locally_deleted'] = Variable<bool>(locallyDeleted);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['city'] = Variable<String>(city);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['category_id'] = Variable<int>(categoryId);
    map['category_name'] = Variable<String>(categoryName);
    if (!nullToAbsent || mainImageUrl != null) {
      map['main_image_url'] = Variable<String>(mainImageUrl);
    }
    map['image_count'] = Variable<int>(imageCount);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    return map;
  }

  LocalDonationsCompanion toCompanion(bool nullToAbsent) {
    return LocalDonationsCompanion(
      localId: Value(localId),
      cacheUserId: Value(cacheUserId),
      clientId: Value(clientId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      expiresAt: Value(expiresAt),
      detailExpiresAt: detailExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detailExpiresAt),
      syncState: Value(syncState),
      locallyDeleted: Value(locallyDeleted),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      city: Value(city),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      categoryId: Value(categoryId),
      categoryName: Value(categoryName),
      mainImageUrl: mainImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mainImageUrl),
      imageCount: Value(imageCount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
    );
  }

  factory LocalDonation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDonation(
      localId: serializer.fromJson<int>(json['localId']),
      cacheUserId: serializer.fromJson<int>(json['cacheUserId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      detailExpiresAt: serializer.fromJson<DateTime?>(json['detailExpiresAt']),
      syncState: $LocalDonationsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      locallyDeleted: serializer.fromJson<bool>(json['locallyDeleted']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      city: serializer.fromJson<String>(json['city']),
      status: serializer.fromJson<String?>(json['status']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      mainImageUrl: serializer.fromJson<String?>(json['mainImageUrl']),
      imageCount: serializer.fromJson<int>(json['imageCount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'cacheUserId': serializer.toJson<int>(cacheUserId),
      'clientId': serializer.toJson<String>(clientId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'detailExpiresAt': serializer.toJson<DateTime?>(detailExpiresAt),
      'syncState': serializer.toJson<String>(
        $LocalDonationsTable.$convertersyncState.toJson(syncState),
      ),
      'locallyDeleted': serializer.toJson<bool>(locallyDeleted),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'city': serializer.toJson<String>(city),
      'status': serializer.toJson<String?>(status),
      'categoryId': serializer.toJson<int>(categoryId),
      'categoryName': serializer.toJson<String>(categoryName),
      'mainImageUrl': serializer.toJson<String?>(mainImageUrl),
      'imageCount': serializer.toJson<int>(imageCount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
    };
  }

  LocalDonation copyWith({
    int? localId,
    int? cacheUserId,
    String? clientId,
    Value<int?> remoteId = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    DateTime? expiresAt,
    Value<DateTime?> detailExpiresAt = const Value.absent(),
    DonationSyncState? syncState,
    bool? locallyDeleted,
    String? title,
    Value<String?> description = const Value.absent(),
    String? city,
    Value<String?> status = const Value.absent(),
    int? categoryId,
    String? categoryName,
    Value<String?> mainImageUrl = const Value.absent(),
    int? imageCount,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    Value<DateTime?> lastAccessedAt = const Value.absent(),
  }) => LocalDonation(
    localId: localId ?? this.localId,
    cacheUserId: cacheUserId ?? this.cacheUserId,
    clientId: clientId ?? this.clientId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    detailExpiresAt: detailExpiresAt.present
        ? detailExpiresAt.value
        : this.detailExpiresAt,
    syncState: syncState ?? this.syncState,
    locallyDeleted: locallyDeleted ?? this.locallyDeleted,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    city: city ?? this.city,
    status: status.present ? status.value : this.status,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    mainImageUrl: mainImageUrl.present ? mainImageUrl.value : this.mainImageUrl,
    imageCount: imageCount ?? this.imageCount,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    lastAccessedAt: lastAccessedAt.present
        ? lastAccessedAt.value
        : this.lastAccessedAt,
  );
  LocalDonation copyWithCompanion(LocalDonationsCompanion data) {
    return LocalDonation(
      localId: data.localId.present ? data.localId.value : this.localId,
      cacheUserId: data.cacheUserId.present
          ? data.cacheUserId.value
          : this.cacheUserId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      detailExpiresAt: data.detailExpiresAt.present
          ? data.detailExpiresAt.value
          : this.detailExpiresAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      locallyDeleted: data.locallyDeleted.present
          ? data.locallyDeleted.value
          : this.locallyDeleted,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      city: data.city.present ? data.city.value : this.city,
      status: data.status.present ? data.status.value : this.status,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      mainImageUrl: data.mainImageUrl.present
          ? data.mainImageUrl.value
          : this.mainImageUrl,
      imageCount: data.imageCount.present
          ? data.imageCount.value
          : this.imageCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDonation(')
          ..write('localId: $localId, ')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('clientId: $clientId, ')
          ..write('remoteId: $remoteId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('detailExpiresAt: $detailExpiresAt, ')
          ..write('syncState: $syncState, ')
          ..write('locallyDeleted: $locallyDeleted, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('city: $city, ')
          ..write('status: $status, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('mainImageUrl: $mainImageUrl, ')
          ..write('imageCount: $imageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    cacheUserId,
    clientId,
    remoteId,
    lastSyncedAt,
    expiresAt,
    detailExpiresAt,
    syncState,
    locallyDeleted,
    title,
    description,
    city,
    status,
    categoryId,
    categoryName,
    mainImageUrl,
    imageCount,
    createdAt,
    serverUpdatedAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDonation &&
          other.localId == this.localId &&
          other.cacheUserId == this.cacheUserId &&
          other.clientId == this.clientId &&
          other.remoteId == this.remoteId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.expiresAt == this.expiresAt &&
          other.detailExpiresAt == this.detailExpiresAt &&
          other.syncState == this.syncState &&
          other.locallyDeleted == this.locallyDeleted &&
          other.title == this.title &&
          other.description == this.description &&
          other.city == this.city &&
          other.status == this.status &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.mainImageUrl == this.mainImageUrl &&
          other.imageCount == this.imageCount &&
          other.createdAt == this.createdAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class LocalDonationsCompanion extends UpdateCompanion<LocalDonation> {
  final Value<int> localId;
  final Value<int> cacheUserId;
  final Value<String> clientId;
  final Value<int?> remoteId;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> detailExpiresAt;
  final Value<DonationSyncState> syncState;
  final Value<bool> locallyDeleted;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> city;
  final Value<String?> status;
  final Value<int> categoryId;
  final Value<String> categoryName;
  final Value<String?> mainImageUrl;
  final Value<int> imageCount;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime?> lastAccessedAt;
  const LocalDonationsCompanion({
    this.localId = const Value.absent(),
    this.cacheUserId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.detailExpiresAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.locallyDeleted = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.city = const Value.absent(),
    this.status = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.mainImageUrl = const Value.absent(),
    this.imageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
  });
  LocalDonationsCompanion.insert({
    this.localId = const Value.absent(),
    required int cacheUserId,
    required String clientId,
    this.remoteId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required DateTime expiresAt,
    this.detailExpiresAt = const Value.absent(),
    required DonationSyncState syncState,
    this.locallyDeleted = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required String city,
    this.status = const Value.absent(),
    required int categoryId,
    required String categoryName,
    this.mainImageUrl = const Value.absent(),
    this.imageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
  }) : cacheUserId = Value(cacheUserId),
       clientId = Value(clientId),
       expiresAt = Value(expiresAt),
       syncState = Value(syncState),
       title = Value(title),
       city = Value(city),
       categoryId = Value(categoryId),
       categoryName = Value(categoryName);
  static Insertable<LocalDonation> custom({
    Expression<int>? localId,
    Expression<int>? cacheUserId,
    Expression<String>? clientId,
    Expression<int>? remoteId,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? detailExpiresAt,
    Expression<String>? syncState,
    Expression<bool>? locallyDeleted,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? city,
    Expression<String>? status,
    Expression<int>? categoryId,
    Expression<String>? categoryName,
    Expression<String>? mainImageUrl,
    Expression<int>? imageCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? lastAccessedAt,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (cacheUserId != null) 'cache_user_id': cacheUserId,
      if (clientId != null) 'client_id': clientId,
      if (remoteId != null) 'remote_id': remoteId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (detailExpiresAt != null) 'detail_expires_at': detailExpiresAt,
      if (syncState != null) 'sync_state': syncState,
      if (locallyDeleted != null) 'locally_deleted': locallyDeleted,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (city != null) 'city': city,
      if (status != null) 'status': status,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (mainImageUrl != null) 'main_image_url': mainImageUrl,
      if (imageCount != null) 'image_count': imageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
    });
  }

  LocalDonationsCompanion copyWith({
    Value<int>? localId,
    Value<int>? cacheUserId,
    Value<String>? clientId,
    Value<int?>? remoteId,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime>? expiresAt,
    Value<DateTime?>? detailExpiresAt,
    Value<DonationSyncState>? syncState,
    Value<bool>? locallyDeleted,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? city,
    Value<String?>? status,
    Value<int>? categoryId,
    Value<String>? categoryName,
    Value<String?>? mainImageUrl,
    Value<int>? imageCount,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime?>? lastAccessedAt,
  }) {
    return LocalDonationsCompanion(
      localId: localId ?? this.localId,
      cacheUserId: cacheUserId ?? this.cacheUserId,
      clientId: clientId ?? this.clientId,
      remoteId: remoteId ?? this.remoteId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      detailExpiresAt: detailExpiresAt ?? this.detailExpiresAt,
      syncState: syncState ?? this.syncState,
      locallyDeleted: locallyDeleted ?? this.locallyDeleted,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      imageCount: imageCount ?? this.imageCount,
      createdAt: createdAt ?? this.createdAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (cacheUserId.present) {
      map['cache_user_id'] = Variable<int>(cacheUserId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (detailExpiresAt.present) {
      map['detail_expires_at'] = Variable<DateTime>(detailExpiresAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $LocalDonationsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (locallyDeleted.present) {
      map['locally_deleted'] = Variable<bool>(locallyDeleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (mainImageUrl.present) {
      map['main_image_url'] = Variable<String>(mainImageUrl.value);
    }
    if (imageCount.present) {
      map['image_count'] = Variable<int>(imageCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDonationsCompanion(')
          ..write('localId: $localId, ')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('clientId: $clientId, ')
          ..write('remoteId: $remoteId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('detailExpiresAt: $detailExpiresAt, ')
          ..write('syncState: $syncState, ')
          ..write('locallyDeleted: $locallyDeleted, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('city: $city, ')
          ..write('status: $status, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('mainImageUrl: $mainImageUrl, ')
          ..write('imageCount: $imageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalDonationMembershipsTable extends LocalDonationMemberships
    with TableInfo<$LocalDonationMembershipsTable, LocalDonationMembership> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDonationMembershipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheUserIdMeta = const VerificationMeta(
    'cacheUserId',
  );
  @override
  late final GeneratedColumn<int> cacheUserId = GeneratedColumn<int>(
    'cache_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDonationIdMeta = const VerificationMeta(
    'localDonationId',
  );
  @override
  late final GeneratedColumn<int> localDonationId = GeneratedColumn<int>(
    'local_donation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_donations (local_id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DonationCollectionType, String>
  collectionType =
      GeneratedColumn<String>(
        'collection_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DonationCollectionType>(
        $LocalDonationMembershipsTable.$convertercollectionType,
      );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheUserId,
    localDonationId,
    collectionType,
    lastSeenAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_donation_memberships';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDonationMembership> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_user_id')) {
      context.handle(
        _cacheUserIdMeta,
        cacheUserId.isAcceptableOrUnknown(
          data['cache_user_id']!,
          _cacheUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheUserIdMeta);
    }
    if (data.containsKey('local_donation_id')) {
      context.handle(
        _localDonationIdMeta,
        localDonationId.isAcceptableOrUnknown(
          data['local_donation_id']!,
          _localDonationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localDonationIdMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    cacheUserId,
    localDonationId,
    collectionType,
  };
  @override
  LocalDonationMembership map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDonationMembership(
      cacheUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_user_id'],
      )!,
      localDonationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_donation_id'],
      )!,
      collectionType: $LocalDonationMembershipsTable.$convertercollectionType
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}collection_type'],
            )!,
          ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $LocalDonationMembershipsTable createAlias(String alias) {
    return $LocalDonationMembershipsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DonationCollectionType, String, String>
  $convertercollectionType = const EnumNameConverter<DonationCollectionType>(
    DonationCollectionType.values,
  );
}

class LocalDonationMembership extends DataClass
    implements Insertable<LocalDonationMembership> {
  final int cacheUserId;
  final int localDonationId;
  final DonationCollectionType collectionType;
  final DateTime lastSeenAt;
  final DateTime expiresAt;
  const LocalDonationMembership({
    required this.cacheUserId,
    required this.localDonationId,
    required this.collectionType,
    required this.lastSeenAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_user_id'] = Variable<int>(cacheUserId);
    map['local_donation_id'] = Variable<int>(localDonationId);
    {
      map['collection_type'] = Variable<String>(
        $LocalDonationMembershipsTable.$convertercollectionType.toSql(
          collectionType,
        ),
      );
    }
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  LocalDonationMembershipsCompanion toCompanion(bool nullToAbsent) {
    return LocalDonationMembershipsCompanion(
      cacheUserId: Value(cacheUserId),
      localDonationId: Value(localDonationId),
      collectionType: Value(collectionType),
      lastSeenAt: Value(lastSeenAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory LocalDonationMembership.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDonationMembership(
      cacheUserId: serializer.fromJson<int>(json['cacheUserId']),
      localDonationId: serializer.fromJson<int>(json['localDonationId']),
      collectionType: $LocalDonationMembershipsTable.$convertercollectionType
          .fromJson(serializer.fromJson<String>(json['collectionType'])),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheUserId': serializer.toJson<int>(cacheUserId),
      'localDonationId': serializer.toJson<int>(localDonationId),
      'collectionType': serializer.toJson<String>(
        $LocalDonationMembershipsTable.$convertercollectionType.toJson(
          collectionType,
        ),
      ),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  LocalDonationMembership copyWith({
    int? cacheUserId,
    int? localDonationId,
    DonationCollectionType? collectionType,
    DateTime? lastSeenAt,
    DateTime? expiresAt,
  }) => LocalDonationMembership(
    cacheUserId: cacheUserId ?? this.cacheUserId,
    localDonationId: localDonationId ?? this.localDonationId,
    collectionType: collectionType ?? this.collectionType,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  LocalDonationMembership copyWithCompanion(
    LocalDonationMembershipsCompanion data,
  ) {
    return LocalDonationMembership(
      cacheUserId: data.cacheUserId.present
          ? data.cacheUserId.value
          : this.cacheUserId,
      localDonationId: data.localDonationId.present
          ? data.localDonationId.value
          : this.localDonationId,
      collectionType: data.collectionType.present
          ? data.collectionType.value
          : this.collectionType,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDonationMembership(')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('localDonationId: $localDonationId, ')
          ..write('collectionType: $collectionType, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheUserId,
    localDonationId,
    collectionType,
    lastSeenAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDonationMembership &&
          other.cacheUserId == this.cacheUserId &&
          other.localDonationId == this.localDonationId &&
          other.collectionType == this.collectionType &&
          other.lastSeenAt == this.lastSeenAt &&
          other.expiresAt == this.expiresAt);
}

class LocalDonationMembershipsCompanion
    extends UpdateCompanion<LocalDonationMembership> {
  final Value<int> cacheUserId;
  final Value<int> localDonationId;
  final Value<DonationCollectionType> collectionType;
  final Value<DateTime> lastSeenAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const LocalDonationMembershipsCompanion({
    this.cacheUserId = const Value.absent(),
    this.localDonationId = const Value.absent(),
    this.collectionType = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDonationMembershipsCompanion.insert({
    required int cacheUserId,
    required int localDonationId,
    required DonationCollectionType collectionType,
    required DateTime lastSeenAt,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : cacheUserId = Value(cacheUserId),
       localDonationId = Value(localDonationId),
       collectionType = Value(collectionType),
       lastSeenAt = Value(lastSeenAt),
       expiresAt = Value(expiresAt);
  static Insertable<LocalDonationMembership> custom({
    Expression<int>? cacheUserId,
    Expression<int>? localDonationId,
    Expression<String>? collectionType,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheUserId != null) 'cache_user_id': cacheUserId,
      if (localDonationId != null) 'local_donation_id': localDonationId,
      if (collectionType != null) 'collection_type': collectionType,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDonationMembershipsCompanion copyWith({
    Value<int>? cacheUserId,
    Value<int>? localDonationId,
    Value<DonationCollectionType>? collectionType,
    Value<DateTime>? lastSeenAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return LocalDonationMembershipsCompanion(
      cacheUserId: cacheUserId ?? this.cacheUserId,
      localDonationId: localDonationId ?? this.localDonationId,
      collectionType: collectionType ?? this.collectionType,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheUserId.present) {
      map['cache_user_id'] = Variable<int>(cacheUserId.value);
    }
    if (localDonationId.present) {
      map['local_donation_id'] = Variable<int>(localDonationId.value);
    }
    if (collectionType.present) {
      map['collection_type'] = Variable<String>(
        $LocalDonationMembershipsTable.$convertercollectionType.toSql(
          collectionType.value,
        ),
      );
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDonationMembershipsCompanion(')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('localDonationId: $localDonationId, ')
          ..write('collectionType: $collectionType, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDonationImagesTable extends LocalDonationImages
    with TableInfo<$LocalDonationImagesTable, LocalDonationImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDonationImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localDonationIdMeta = const VerificationMeta(
    'localDonationId',
  );
  @override
  late final GeneratedColumn<int> localDonationId = GeneratedColumn<int>(
    'local_donation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_donations (local_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _remoteImageIdMeta = const VerificationMeta(
    'remoteImageId',
  );
  @override
  late final GeneratedColumn<int> remoteImageId = GeneratedColumn<int>(
    'remote_image_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUrlMeta = const VerificationMeta(
    'remoteUrl',
  );
  @override
  late final GeneratedColumn<String> remoteUrl = GeneratedColumn<String>(
    'remote_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managedLocalPathMeta = const VerificationMeta(
    'managedLocalPath',
  );
  @override
  late final GeneratedColumn<String> managedLocalPath = GeneratedColumn<String>(
    'managed_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedLocalPathMeta = const VerificationMeta(
    'cachedLocalPath',
  );
  @override
  late final GeneratedColumn<String> cachedLocalPath = GeneratedColumn<String>(
    'cached_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ImageUploadState, String>
  uploadState =
      GeneratedColumn<String>(
        'upload_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ImageUploadState>(
        $LocalDonationImagesTable.$converteruploadState,
      );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    localDonationId,
    remoteImageId,
    remoteUrl,
    managedLocalPath,
    cachedLocalPath,
    sortOrder,
    mimeType,
    sizeBytes,
    uploadState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_donation_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDonationImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('local_donation_id')) {
      context.handle(
        _localDonationIdMeta,
        localDonationId.isAcceptableOrUnknown(
          data['local_donation_id']!,
          _localDonationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localDonationIdMeta);
    }
    if (data.containsKey('remote_image_id')) {
      context.handle(
        _remoteImageIdMeta,
        remoteImageId.isAcceptableOrUnknown(
          data['remote_image_id']!,
          _remoteImageIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_url')) {
      context.handle(
        _remoteUrlMeta,
        remoteUrl.isAcceptableOrUnknown(data['remote_url']!, _remoteUrlMeta),
      );
    }
    if (data.containsKey('managed_local_path')) {
      context.handle(
        _managedLocalPathMeta,
        managedLocalPath.isAcceptableOrUnknown(
          data['managed_local_path']!,
          _managedLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('cached_local_path')) {
      context.handle(
        _cachedLocalPathMeta,
        cachedLocalPath.isAcceptableOrUnknown(
          data['cached_local_path']!,
          _cachedLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalDonationImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDonationImage(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_id'],
      )!,
      localDonationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_donation_id'],
      )!,
      remoteImageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_image_id'],
      ),
      remoteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_url'],
      ),
      managedLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}managed_local_path'],
      ),
      cachedLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_local_path'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      uploadState: $LocalDonationImagesTable.$converteruploadState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}upload_state'],
        )!,
      ),
    );
  }

  @override
  $LocalDonationImagesTable createAlias(String alias) {
    return $LocalDonationImagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ImageUploadState, String, String>
  $converteruploadState = const EnumNameConverter<ImageUploadState>(
    ImageUploadState.values,
  );
}

class LocalDonationImage extends DataClass
    implements Insertable<LocalDonationImage> {
  final int localId;
  final int localDonationId;
  final int? remoteImageId;
  final String? remoteUrl;
  final String? managedLocalPath;
  final String? cachedLocalPath;
  final int sortOrder;
  final String? mimeType;
  final int? sizeBytes;
  final ImageUploadState uploadState;
  const LocalDonationImage({
    required this.localId,
    required this.localDonationId,
    this.remoteImageId,
    this.remoteUrl,
    this.managedLocalPath,
    this.cachedLocalPath,
    required this.sortOrder,
    this.mimeType,
    this.sizeBytes,
    required this.uploadState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['local_donation_id'] = Variable<int>(localDonationId);
    if (!nullToAbsent || remoteImageId != null) {
      map['remote_image_id'] = Variable<int>(remoteImageId);
    }
    if (!nullToAbsent || remoteUrl != null) {
      map['remote_url'] = Variable<String>(remoteUrl);
    }
    if (!nullToAbsent || managedLocalPath != null) {
      map['managed_local_path'] = Variable<String>(managedLocalPath);
    }
    if (!nullToAbsent || cachedLocalPath != null) {
      map['cached_local_path'] = Variable<String>(cachedLocalPath);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    {
      map['upload_state'] = Variable<String>(
        $LocalDonationImagesTable.$converteruploadState.toSql(uploadState),
      );
    }
    return map;
  }

  LocalDonationImagesCompanion toCompanion(bool nullToAbsent) {
    return LocalDonationImagesCompanion(
      localId: Value(localId),
      localDonationId: Value(localDonationId),
      remoteImageId: remoteImageId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteImageId),
      remoteUrl: remoteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUrl),
      managedLocalPath: managedLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(managedLocalPath),
      cachedLocalPath: cachedLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedLocalPath),
      sortOrder: Value(sortOrder),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      uploadState: Value(uploadState),
    );
  }

  factory LocalDonationImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDonationImage(
      localId: serializer.fromJson<int>(json['localId']),
      localDonationId: serializer.fromJson<int>(json['localDonationId']),
      remoteImageId: serializer.fromJson<int?>(json['remoteImageId']),
      remoteUrl: serializer.fromJson<String?>(json['remoteUrl']),
      managedLocalPath: serializer.fromJson<String?>(json['managedLocalPath']),
      cachedLocalPath: serializer.fromJson<String?>(json['cachedLocalPath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      uploadState: $LocalDonationImagesTable.$converteruploadState.fromJson(
        serializer.fromJson<String>(json['uploadState']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'localDonationId': serializer.toJson<int>(localDonationId),
      'remoteImageId': serializer.toJson<int?>(remoteImageId),
      'remoteUrl': serializer.toJson<String?>(remoteUrl),
      'managedLocalPath': serializer.toJson<String?>(managedLocalPath),
      'cachedLocalPath': serializer.toJson<String?>(cachedLocalPath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'mimeType': serializer.toJson<String?>(mimeType),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'uploadState': serializer.toJson<String>(
        $LocalDonationImagesTable.$converteruploadState.toJson(uploadState),
      ),
    };
  }

  LocalDonationImage copyWith({
    int? localId,
    int? localDonationId,
    Value<int?> remoteImageId = const Value.absent(),
    Value<String?> remoteUrl = const Value.absent(),
    Value<String?> managedLocalPath = const Value.absent(),
    Value<String?> cachedLocalPath = const Value.absent(),
    int? sortOrder,
    Value<String?> mimeType = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    ImageUploadState? uploadState,
  }) => LocalDonationImage(
    localId: localId ?? this.localId,
    localDonationId: localDonationId ?? this.localDonationId,
    remoteImageId: remoteImageId.present
        ? remoteImageId.value
        : this.remoteImageId,
    remoteUrl: remoteUrl.present ? remoteUrl.value : this.remoteUrl,
    managedLocalPath: managedLocalPath.present
        ? managedLocalPath.value
        : this.managedLocalPath,
    cachedLocalPath: cachedLocalPath.present
        ? cachedLocalPath.value
        : this.cachedLocalPath,
    sortOrder: sortOrder ?? this.sortOrder,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    uploadState: uploadState ?? this.uploadState,
  );
  LocalDonationImage copyWithCompanion(LocalDonationImagesCompanion data) {
    return LocalDonationImage(
      localId: data.localId.present ? data.localId.value : this.localId,
      localDonationId: data.localDonationId.present
          ? data.localDonationId.value
          : this.localDonationId,
      remoteImageId: data.remoteImageId.present
          ? data.remoteImageId.value
          : this.remoteImageId,
      remoteUrl: data.remoteUrl.present ? data.remoteUrl.value : this.remoteUrl,
      managedLocalPath: data.managedLocalPath.present
          ? data.managedLocalPath.value
          : this.managedLocalPath,
      cachedLocalPath: data.cachedLocalPath.present
          ? data.cachedLocalPath.value
          : this.cachedLocalPath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      uploadState: data.uploadState.present
          ? data.uploadState.value
          : this.uploadState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDonationImage(')
          ..write('localId: $localId, ')
          ..write('localDonationId: $localDonationId, ')
          ..write('remoteImageId: $remoteImageId, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('managedLocalPath: $managedLocalPath, ')
          ..write('cachedLocalPath: $cachedLocalPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadState: $uploadState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    localDonationId,
    remoteImageId,
    remoteUrl,
    managedLocalPath,
    cachedLocalPath,
    sortOrder,
    mimeType,
    sizeBytes,
    uploadState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDonationImage &&
          other.localId == this.localId &&
          other.localDonationId == this.localDonationId &&
          other.remoteImageId == this.remoteImageId &&
          other.remoteUrl == this.remoteUrl &&
          other.managedLocalPath == this.managedLocalPath &&
          other.cachedLocalPath == this.cachedLocalPath &&
          other.sortOrder == this.sortOrder &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.uploadState == this.uploadState);
}

class LocalDonationImagesCompanion extends UpdateCompanion<LocalDonationImage> {
  final Value<int> localId;
  final Value<int> localDonationId;
  final Value<int?> remoteImageId;
  final Value<String?> remoteUrl;
  final Value<String?> managedLocalPath;
  final Value<String?> cachedLocalPath;
  final Value<int> sortOrder;
  final Value<String?> mimeType;
  final Value<int?> sizeBytes;
  final Value<ImageUploadState> uploadState;
  const LocalDonationImagesCompanion({
    this.localId = const Value.absent(),
    this.localDonationId = const Value.absent(),
    this.remoteImageId = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.managedLocalPath = const Value.absent(),
    this.cachedLocalPath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.uploadState = const Value.absent(),
  });
  LocalDonationImagesCompanion.insert({
    this.localId = const Value.absent(),
    required int localDonationId,
    this.remoteImageId = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.managedLocalPath = const Value.absent(),
    this.cachedLocalPath = const Value.absent(),
    required int sortOrder,
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required ImageUploadState uploadState,
  }) : localDonationId = Value(localDonationId),
       sortOrder = Value(sortOrder),
       uploadState = Value(uploadState);
  static Insertable<LocalDonationImage> custom({
    Expression<int>? localId,
    Expression<int>? localDonationId,
    Expression<int>? remoteImageId,
    Expression<String>? remoteUrl,
    Expression<String>? managedLocalPath,
    Expression<String>? cachedLocalPath,
    Expression<int>? sortOrder,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? uploadState,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (localDonationId != null) 'local_donation_id': localDonationId,
      if (remoteImageId != null) 'remote_image_id': remoteImageId,
      if (remoteUrl != null) 'remote_url': remoteUrl,
      if (managedLocalPath != null) 'managed_local_path': managedLocalPath,
      if (cachedLocalPath != null) 'cached_local_path': cachedLocalPath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (uploadState != null) 'upload_state': uploadState,
    });
  }

  LocalDonationImagesCompanion copyWith({
    Value<int>? localId,
    Value<int>? localDonationId,
    Value<int?>? remoteImageId,
    Value<String?>? remoteUrl,
    Value<String?>? managedLocalPath,
    Value<String?>? cachedLocalPath,
    Value<int>? sortOrder,
    Value<String?>? mimeType,
    Value<int?>? sizeBytes,
    Value<ImageUploadState>? uploadState,
  }) {
    return LocalDonationImagesCompanion(
      localId: localId ?? this.localId,
      localDonationId: localDonationId ?? this.localDonationId,
      remoteImageId: remoteImageId ?? this.remoteImageId,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      managedLocalPath: managedLocalPath ?? this.managedLocalPath,
      cachedLocalPath: cachedLocalPath ?? this.cachedLocalPath,
      sortOrder: sortOrder ?? this.sortOrder,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadState: uploadState ?? this.uploadState,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (localDonationId.present) {
      map['local_donation_id'] = Variable<int>(localDonationId.value);
    }
    if (remoteImageId.present) {
      map['remote_image_id'] = Variable<int>(remoteImageId.value);
    }
    if (remoteUrl.present) {
      map['remote_url'] = Variable<String>(remoteUrl.value);
    }
    if (managedLocalPath.present) {
      map['managed_local_path'] = Variable<String>(managedLocalPath.value);
    }
    if (cachedLocalPath.present) {
      map['cached_local_path'] = Variable<String>(cachedLocalPath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (uploadState.present) {
      map['upload_state'] = Variable<String>(
        $LocalDonationImagesTable.$converteruploadState.toSql(
          uploadState.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDonationImagesCompanion(')
          ..write('localId: $localId, ')
          ..write('localDonationId: $localDonationId, ')
          ..write('remoteImageId: $remoteImageId, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('managedLocalPath: $managedLocalPath, ')
          ..write('cachedLocalPath: $cachedLocalPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadState: $uploadState')
          ..write(')'))
        .toString();
  }
}

class $LocalRequestsTable extends LocalRequests
    with TableInfo<$LocalRequestsTable, LocalRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheUserIdMeta = const VerificationMeta(
    'cacheUserId',
  );
  @override
  late final GeneratedColumn<int> cacheUserId = GeneratedColumn<int>(
    'cache_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RequestCollectionType, String>
  collectionType =
      GeneratedColumn<String>(
        'collection_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RequestCollectionType>(
        $LocalRequestsTable.$convertercollectionType,
      );
  static const VerificationMeta _detailCachedMeta = const VerificationMeta(
    'detailCached',
  );
  @override
  late final GeneratedColumn<bool> detailCached = GeneratedColumn<bool>(
    'detail_cached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("detail_cached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cancellationCauseMeta = const VerificationMeta(
    'cancellationCause',
  );
  @override
  late final GeneratedColumn<String> cancellationCause =
      GeneratedColumn<String>(
        'cancellation_cause',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta(
    'acceptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
    'accepted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectedAtMeta = const VerificationMeta(
    'rejectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> rejectedAt = GeneratedColumn<DateTime>(
    'rejected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta(
    'cancelledAt',
  );
  @override
  late final GeneratedColumn<DateTime> cancelledAt = GeneratedColumn<DateTime>(
    'cancelled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _donationRemoteIdMeta = const VerificationMeta(
    'donationRemoteId',
  );
  @override
  late final GeneratedColumn<int> donationRemoteId = GeneratedColumn<int>(
    'donation_remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _donationTitleMeta = const VerificationMeta(
    'donationTitle',
  );
  @override
  late final GeneratedColumn<String> donationTitle = GeneratedColumn<String>(
    'donation_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _donationStatusMeta = const VerificationMeta(
    'donationStatus',
  );
  @override
  late final GeneratedColumn<String> donationStatus = GeneratedColumn<String>(
    'donation_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _donationMainImageUrlMeta =
      const VerificationMeta('donationMainImageUrl');
  @override
  late final GeneratedColumn<String> donationMainImageUrl =
      GeneratedColumn<String>(
        'donation_main_image_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _participantRemoteIdMeta =
      const VerificationMeta('participantRemoteId');
  @override
  late final GeneratedColumn<int> participantRemoteId = GeneratedColumn<int>(
    'participant_remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantVisibleNameMeta =
      const VerificationMeta('participantVisibleName');
  @override
  late final GeneratedColumn<String> participantVisibleName =
      GeneratedColumn<String>(
        'participant_visible_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _participantCityMeta = const VerificationMeta(
    'participantCity',
  );
  @override
  late final GeneratedColumn<String> participantCity = GeneratedColumn<String>(
    'participant_city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantProfilePhotoUrlMeta =
      const VerificationMeta('participantProfilePhotoUrl');
  @override
  late final GeneratedColumn<String> participantProfilePhotoUrl =
      GeneratedColumn<String>(
        'participant_profile_photo_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheUserId,
    remoteId,
    collectionType,
    detailCached,
    status,
    cancellationCause,
    acceptedAt,
    rejectedAt,
    cancelledAt,
    createdAt,
    serverUpdatedAt,
    donationRemoteId,
    donationTitle,
    donationStatus,
    donationMainImageUrl,
    participantRemoteId,
    participantVisibleName,
    participantCity,
    participantProfilePhotoUrl,
    lastSyncedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_user_id')) {
      context.handle(
        _cacheUserIdMeta,
        cacheUserId.isAcceptableOrUnknown(
          data['cache_user_id']!,
          _cacheUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheUserIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('detail_cached')) {
      context.handle(
        _detailCachedMeta,
        detailCached.isAcceptableOrUnknown(
          data['detail_cached']!,
          _detailCachedMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('cancellation_cause')) {
      context.handle(
        _cancellationCauseMeta,
        cancellationCause.isAcceptableOrUnknown(
          data['cancellation_cause']!,
          _cancellationCauseMeta,
        ),
      );
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
        _acceptedAtMeta,
        acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta),
      );
    }
    if (data.containsKey('rejected_at')) {
      context.handle(
        _rejectedAtMeta,
        rejectedAt.isAcceptableOrUnknown(data['rejected_at']!, _rejectedAtMeta),
      );
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
        _cancelledAtMeta,
        cancelledAt.isAcceptableOrUnknown(
          data['cancelled_at']!,
          _cancelledAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverUpdatedAtMeta);
    }
    if (data.containsKey('donation_remote_id')) {
      context.handle(
        _donationRemoteIdMeta,
        donationRemoteId.isAcceptableOrUnknown(
          data['donation_remote_id']!,
          _donationRemoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_donationRemoteIdMeta);
    }
    if (data.containsKey('donation_title')) {
      context.handle(
        _donationTitleMeta,
        donationTitle.isAcceptableOrUnknown(
          data['donation_title']!,
          _donationTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_donationTitleMeta);
    }
    if (data.containsKey('donation_status')) {
      context.handle(
        _donationStatusMeta,
        donationStatus.isAcceptableOrUnknown(
          data['donation_status']!,
          _donationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_donationStatusMeta);
    }
    if (data.containsKey('donation_main_image_url')) {
      context.handle(
        _donationMainImageUrlMeta,
        donationMainImageUrl.isAcceptableOrUnknown(
          data['donation_main_image_url']!,
          _donationMainImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('participant_remote_id')) {
      context.handle(
        _participantRemoteIdMeta,
        participantRemoteId.isAcceptableOrUnknown(
          data['participant_remote_id']!,
          _participantRemoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantRemoteIdMeta);
    }
    if (data.containsKey('participant_visible_name')) {
      context.handle(
        _participantVisibleNameMeta,
        participantVisibleName.isAcceptableOrUnknown(
          data['participant_visible_name']!,
          _participantVisibleNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantVisibleNameMeta);
    }
    if (data.containsKey('participant_city')) {
      context.handle(
        _participantCityMeta,
        participantCity.isAcceptableOrUnknown(
          data['participant_city']!,
          _participantCityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantCityMeta);
    }
    if (data.containsKey('participant_profile_photo_url')) {
      context.handle(
        _participantProfilePhotoUrlMeta,
        participantProfilePhotoUrl.isAcceptableOrUnknown(
          data['participant_profile_photo_url']!,
          _participantProfilePhotoUrlMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    cacheUserId,
    remoteId,
    collectionType,
  };
  @override
  LocalRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRequest(
      cacheUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_user_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      )!,
      collectionType: $LocalRequestsTable.$convertercollectionType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}collection_type'],
        )!,
      ),
      detailCached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}detail_cached'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      cancellationCause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancellation_cause'],
      ),
      acceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accepted_at'],
      ),
      rejectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rejected_at'],
      ),
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cancelled_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      )!,
      donationRemoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}donation_remote_id'],
      )!,
      donationTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}donation_title'],
      )!,
      donationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}donation_status'],
      )!,
      donationMainImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}donation_main_image_url'],
      ),
      participantRemoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}participant_remote_id'],
      )!,
      participantVisibleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_visible_name'],
      )!,
      participantCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_city'],
      )!,
      participantProfilePhotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_profile_photo_url'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $LocalRequestsTable createAlias(String alias) {
    return $LocalRequestsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RequestCollectionType, String, String>
  $convertercollectionType = const EnumNameConverter<RequestCollectionType>(
    RequestCollectionType.values,
  );
}

class LocalRequest extends DataClass implements Insertable<LocalRequest> {
  final int cacheUserId;
  final int remoteId;
  final RequestCollectionType collectionType;
  final bool detailCached;
  final String status;
  final String? cancellationCause;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime serverUpdatedAt;
  final int donationRemoteId;
  final String donationTitle;
  final String donationStatus;
  final String? donationMainImageUrl;
  final int participantRemoteId;
  final String participantVisibleName;
  final String participantCity;
  final String? participantProfilePhotoUrl;
  final DateTime lastSyncedAt;
  final DateTime expiresAt;
  const LocalRequest({
    required this.cacheUserId,
    required this.remoteId,
    required this.collectionType,
    required this.detailCached,
    required this.status,
    this.cancellationCause,
    this.acceptedAt,
    this.rejectedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.serverUpdatedAt,
    required this.donationRemoteId,
    required this.donationTitle,
    required this.donationStatus,
    this.donationMainImageUrl,
    required this.participantRemoteId,
    required this.participantVisibleName,
    required this.participantCity,
    this.participantProfilePhotoUrl,
    required this.lastSyncedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_user_id'] = Variable<int>(cacheUserId);
    map['remote_id'] = Variable<int>(remoteId);
    {
      map['collection_type'] = Variable<String>(
        $LocalRequestsTable.$convertercollectionType.toSql(collectionType),
      );
    }
    map['detail_cached'] = Variable<bool>(detailCached);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || cancellationCause != null) {
      map['cancellation_cause'] = Variable<String>(cancellationCause);
    }
    if (!nullToAbsent || acceptedAt != null) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt);
    }
    if (!nullToAbsent || rejectedAt != null) {
      map['rejected_at'] = Variable<DateTime>(rejectedAt);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    map['donation_remote_id'] = Variable<int>(donationRemoteId);
    map['donation_title'] = Variable<String>(donationTitle);
    map['donation_status'] = Variable<String>(donationStatus);
    if (!nullToAbsent || donationMainImageUrl != null) {
      map['donation_main_image_url'] = Variable<String>(donationMainImageUrl);
    }
    map['participant_remote_id'] = Variable<int>(participantRemoteId);
    map['participant_visible_name'] = Variable<String>(participantVisibleName);
    map['participant_city'] = Variable<String>(participantCity);
    if (!nullToAbsent || participantProfilePhotoUrl != null) {
      map['participant_profile_photo_url'] = Variable<String>(
        participantProfilePhotoUrl,
      );
    }
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  LocalRequestsCompanion toCompanion(bool nullToAbsent) {
    return LocalRequestsCompanion(
      cacheUserId: Value(cacheUserId),
      remoteId: Value(remoteId),
      collectionType: Value(collectionType),
      detailCached: Value(detailCached),
      status: Value(status),
      cancellationCause: cancellationCause == null && nullToAbsent
          ? const Value.absent()
          : Value(cancellationCause),
      acceptedAt: acceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedAt),
      rejectedAt: rejectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectedAt),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      createdAt: Value(createdAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      donationRemoteId: Value(donationRemoteId),
      donationTitle: Value(donationTitle),
      donationStatus: Value(donationStatus),
      donationMainImageUrl: donationMainImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(donationMainImageUrl),
      participantRemoteId: Value(participantRemoteId),
      participantVisibleName: Value(participantVisibleName),
      participantCity: Value(participantCity),
      participantProfilePhotoUrl:
          participantProfilePhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(participantProfilePhotoUrl),
      lastSyncedAt: Value(lastSyncedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory LocalRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRequest(
      cacheUserId: serializer.fromJson<int>(json['cacheUserId']),
      remoteId: serializer.fromJson<int>(json['remoteId']),
      collectionType: $LocalRequestsTable.$convertercollectionType.fromJson(
        serializer.fromJson<String>(json['collectionType']),
      ),
      detailCached: serializer.fromJson<bool>(json['detailCached']),
      status: serializer.fromJson<String>(json['status']),
      cancellationCause: serializer.fromJson<String?>(
        json['cancellationCause'],
      ),
      acceptedAt: serializer.fromJson<DateTime?>(json['acceptedAt']),
      rejectedAt: serializer.fromJson<DateTime?>(json['rejectedAt']),
      cancelledAt: serializer.fromJson<DateTime?>(json['cancelledAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      serverUpdatedAt: serializer.fromJson<DateTime>(json['serverUpdatedAt']),
      donationRemoteId: serializer.fromJson<int>(json['donationRemoteId']),
      donationTitle: serializer.fromJson<String>(json['donationTitle']),
      donationStatus: serializer.fromJson<String>(json['donationStatus']),
      donationMainImageUrl: serializer.fromJson<String?>(
        json['donationMainImageUrl'],
      ),
      participantRemoteId: serializer.fromJson<int>(
        json['participantRemoteId'],
      ),
      participantVisibleName: serializer.fromJson<String>(
        json['participantVisibleName'],
      ),
      participantCity: serializer.fromJson<String>(json['participantCity']),
      participantProfilePhotoUrl: serializer.fromJson<String?>(
        json['participantProfilePhotoUrl'],
      ),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheUserId': serializer.toJson<int>(cacheUserId),
      'remoteId': serializer.toJson<int>(remoteId),
      'collectionType': serializer.toJson<String>(
        $LocalRequestsTable.$convertercollectionType.toJson(collectionType),
      ),
      'detailCached': serializer.toJson<bool>(detailCached),
      'status': serializer.toJson<String>(status),
      'cancellationCause': serializer.toJson<String?>(cancellationCause),
      'acceptedAt': serializer.toJson<DateTime?>(acceptedAt),
      'rejectedAt': serializer.toJson<DateTime?>(rejectedAt),
      'cancelledAt': serializer.toJson<DateTime?>(cancelledAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'serverUpdatedAt': serializer.toJson<DateTime>(serverUpdatedAt),
      'donationRemoteId': serializer.toJson<int>(donationRemoteId),
      'donationTitle': serializer.toJson<String>(donationTitle),
      'donationStatus': serializer.toJson<String>(donationStatus),
      'donationMainImageUrl': serializer.toJson<String?>(donationMainImageUrl),
      'participantRemoteId': serializer.toJson<int>(participantRemoteId),
      'participantVisibleName': serializer.toJson<String>(
        participantVisibleName,
      ),
      'participantCity': serializer.toJson<String>(participantCity),
      'participantProfilePhotoUrl': serializer.toJson<String?>(
        participantProfilePhotoUrl,
      ),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  LocalRequest copyWith({
    int? cacheUserId,
    int? remoteId,
    RequestCollectionType? collectionType,
    bool? detailCached,
    String? status,
    Value<String?> cancellationCause = const Value.absent(),
    Value<DateTime?> acceptedAt = const Value.absent(),
    Value<DateTime?> rejectedAt = const Value.absent(),
    Value<DateTime?> cancelledAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? serverUpdatedAt,
    int? donationRemoteId,
    String? donationTitle,
    String? donationStatus,
    Value<String?> donationMainImageUrl = const Value.absent(),
    int? participantRemoteId,
    String? participantVisibleName,
    String? participantCity,
    Value<String?> participantProfilePhotoUrl = const Value.absent(),
    DateTime? lastSyncedAt,
    DateTime? expiresAt,
  }) => LocalRequest(
    cacheUserId: cacheUserId ?? this.cacheUserId,
    remoteId: remoteId ?? this.remoteId,
    collectionType: collectionType ?? this.collectionType,
    detailCached: detailCached ?? this.detailCached,
    status: status ?? this.status,
    cancellationCause: cancellationCause.present
        ? cancellationCause.value
        : this.cancellationCause,
    acceptedAt: acceptedAt.present ? acceptedAt.value : this.acceptedAt,
    rejectedAt: rejectedAt.present ? rejectedAt.value : this.rejectedAt,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    createdAt: createdAt ?? this.createdAt,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    donationRemoteId: donationRemoteId ?? this.donationRemoteId,
    donationTitle: donationTitle ?? this.donationTitle,
    donationStatus: donationStatus ?? this.donationStatus,
    donationMainImageUrl: donationMainImageUrl.present
        ? donationMainImageUrl.value
        : this.donationMainImageUrl,
    participantRemoteId: participantRemoteId ?? this.participantRemoteId,
    participantVisibleName:
        participantVisibleName ?? this.participantVisibleName,
    participantCity: participantCity ?? this.participantCity,
    participantProfilePhotoUrl: participantProfilePhotoUrl.present
        ? participantProfilePhotoUrl.value
        : this.participantProfilePhotoUrl,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  LocalRequest copyWithCompanion(LocalRequestsCompanion data) {
    return LocalRequest(
      cacheUserId: data.cacheUserId.present
          ? data.cacheUserId.value
          : this.cacheUserId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      collectionType: data.collectionType.present
          ? data.collectionType.value
          : this.collectionType,
      detailCached: data.detailCached.present
          ? data.detailCached.value
          : this.detailCached,
      status: data.status.present ? data.status.value : this.status,
      cancellationCause: data.cancellationCause.present
          ? data.cancellationCause.value
          : this.cancellationCause,
      acceptedAt: data.acceptedAt.present
          ? data.acceptedAt.value
          : this.acceptedAt,
      rejectedAt: data.rejectedAt.present
          ? data.rejectedAt.value
          : this.rejectedAt,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      donationRemoteId: data.donationRemoteId.present
          ? data.donationRemoteId.value
          : this.donationRemoteId,
      donationTitle: data.donationTitle.present
          ? data.donationTitle.value
          : this.donationTitle,
      donationStatus: data.donationStatus.present
          ? data.donationStatus.value
          : this.donationStatus,
      donationMainImageUrl: data.donationMainImageUrl.present
          ? data.donationMainImageUrl.value
          : this.donationMainImageUrl,
      participantRemoteId: data.participantRemoteId.present
          ? data.participantRemoteId.value
          : this.participantRemoteId,
      participantVisibleName: data.participantVisibleName.present
          ? data.participantVisibleName.value
          : this.participantVisibleName,
      participantCity: data.participantCity.present
          ? data.participantCity.value
          : this.participantCity,
      participantProfilePhotoUrl: data.participantProfilePhotoUrl.present
          ? data.participantProfilePhotoUrl.value
          : this.participantProfilePhotoUrl,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRequest(')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('remoteId: $remoteId, ')
          ..write('collectionType: $collectionType, ')
          ..write('detailCached: $detailCached, ')
          ..write('status: $status, ')
          ..write('cancellationCause: $cancellationCause, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('donationRemoteId: $donationRemoteId, ')
          ..write('donationTitle: $donationTitle, ')
          ..write('donationStatus: $donationStatus, ')
          ..write('donationMainImageUrl: $donationMainImageUrl, ')
          ..write('participantRemoteId: $participantRemoteId, ')
          ..write('participantVisibleName: $participantVisibleName, ')
          ..write('participantCity: $participantCity, ')
          ..write('participantProfilePhotoUrl: $participantProfilePhotoUrl, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    cacheUserId,
    remoteId,
    collectionType,
    detailCached,
    status,
    cancellationCause,
    acceptedAt,
    rejectedAt,
    cancelledAt,
    createdAt,
    serverUpdatedAt,
    donationRemoteId,
    donationTitle,
    donationStatus,
    donationMainImageUrl,
    participantRemoteId,
    participantVisibleName,
    participantCity,
    participantProfilePhotoUrl,
    lastSyncedAt,
    expiresAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRequest &&
          other.cacheUserId == this.cacheUserId &&
          other.remoteId == this.remoteId &&
          other.collectionType == this.collectionType &&
          other.detailCached == this.detailCached &&
          other.status == this.status &&
          other.cancellationCause == this.cancellationCause &&
          other.acceptedAt == this.acceptedAt &&
          other.rejectedAt == this.rejectedAt &&
          other.cancelledAt == this.cancelledAt &&
          other.createdAt == this.createdAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.donationRemoteId == this.donationRemoteId &&
          other.donationTitle == this.donationTitle &&
          other.donationStatus == this.donationStatus &&
          other.donationMainImageUrl == this.donationMainImageUrl &&
          other.participantRemoteId == this.participantRemoteId &&
          other.participantVisibleName == this.participantVisibleName &&
          other.participantCity == this.participantCity &&
          other.participantProfilePhotoUrl == this.participantProfilePhotoUrl &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.expiresAt == this.expiresAt);
}

class LocalRequestsCompanion extends UpdateCompanion<LocalRequest> {
  final Value<int> cacheUserId;
  final Value<int> remoteId;
  final Value<RequestCollectionType> collectionType;
  final Value<bool> detailCached;
  final Value<String> status;
  final Value<String?> cancellationCause;
  final Value<DateTime?> acceptedAt;
  final Value<DateTime?> rejectedAt;
  final Value<DateTime?> cancelledAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> serverUpdatedAt;
  final Value<int> donationRemoteId;
  final Value<String> donationTitle;
  final Value<String> donationStatus;
  final Value<String?> donationMainImageUrl;
  final Value<int> participantRemoteId;
  final Value<String> participantVisibleName;
  final Value<String> participantCity;
  final Value<String?> participantProfilePhotoUrl;
  final Value<DateTime> lastSyncedAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const LocalRequestsCompanion({
    this.cacheUserId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.collectionType = const Value.absent(),
    this.detailCached = const Value.absent(),
    this.status = const Value.absent(),
    this.cancellationCause = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.rejectedAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.donationRemoteId = const Value.absent(),
    this.donationTitle = const Value.absent(),
    this.donationStatus = const Value.absent(),
    this.donationMainImageUrl = const Value.absent(),
    this.participantRemoteId = const Value.absent(),
    this.participantVisibleName = const Value.absent(),
    this.participantCity = const Value.absent(),
    this.participantProfilePhotoUrl = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRequestsCompanion.insert({
    required int cacheUserId,
    required int remoteId,
    required RequestCollectionType collectionType,
    this.detailCached = const Value.absent(),
    required String status,
    this.cancellationCause = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.rejectedAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime serverUpdatedAt,
    required int donationRemoteId,
    required String donationTitle,
    required String donationStatus,
    this.donationMainImageUrl = const Value.absent(),
    required int participantRemoteId,
    required String participantVisibleName,
    required String participantCity,
    this.participantProfilePhotoUrl = const Value.absent(),
    required DateTime lastSyncedAt,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : cacheUserId = Value(cacheUserId),
       remoteId = Value(remoteId),
       collectionType = Value(collectionType),
       status = Value(status),
       createdAt = Value(createdAt),
       serverUpdatedAt = Value(serverUpdatedAt),
       donationRemoteId = Value(donationRemoteId),
       donationTitle = Value(donationTitle),
       donationStatus = Value(donationStatus),
       participantRemoteId = Value(participantRemoteId),
       participantVisibleName = Value(participantVisibleName),
       participantCity = Value(participantCity),
       lastSyncedAt = Value(lastSyncedAt),
       expiresAt = Value(expiresAt);
  static Insertable<LocalRequest> custom({
    Expression<int>? cacheUserId,
    Expression<int>? remoteId,
    Expression<String>? collectionType,
    Expression<bool>? detailCached,
    Expression<String>? status,
    Expression<String>? cancellationCause,
    Expression<DateTime>? acceptedAt,
    Expression<DateTime>? rejectedAt,
    Expression<DateTime>? cancelledAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<int>? donationRemoteId,
    Expression<String>? donationTitle,
    Expression<String>? donationStatus,
    Expression<String>? donationMainImageUrl,
    Expression<int>? participantRemoteId,
    Expression<String>? participantVisibleName,
    Expression<String>? participantCity,
    Expression<String>? participantProfilePhotoUrl,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheUserId != null) 'cache_user_id': cacheUserId,
      if (remoteId != null) 'remote_id': remoteId,
      if (collectionType != null) 'collection_type': collectionType,
      if (detailCached != null) 'detail_cached': detailCached,
      if (status != null) 'status': status,
      if (cancellationCause != null) 'cancellation_cause': cancellationCause,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (rejectedAt != null) 'rejected_at': rejectedAt,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (createdAt != null) 'created_at': createdAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (donationRemoteId != null) 'donation_remote_id': donationRemoteId,
      if (donationTitle != null) 'donation_title': donationTitle,
      if (donationStatus != null) 'donation_status': donationStatus,
      if (donationMainImageUrl != null)
        'donation_main_image_url': donationMainImageUrl,
      if (participantRemoteId != null)
        'participant_remote_id': participantRemoteId,
      if (participantVisibleName != null)
        'participant_visible_name': participantVisibleName,
      if (participantCity != null) 'participant_city': participantCity,
      if (participantProfilePhotoUrl != null)
        'participant_profile_photo_url': participantProfilePhotoUrl,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRequestsCompanion copyWith({
    Value<int>? cacheUserId,
    Value<int>? remoteId,
    Value<RequestCollectionType>? collectionType,
    Value<bool>? detailCached,
    Value<String>? status,
    Value<String?>? cancellationCause,
    Value<DateTime?>? acceptedAt,
    Value<DateTime?>? rejectedAt,
    Value<DateTime?>? cancelledAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? serverUpdatedAt,
    Value<int>? donationRemoteId,
    Value<String>? donationTitle,
    Value<String>? donationStatus,
    Value<String?>? donationMainImageUrl,
    Value<int>? participantRemoteId,
    Value<String>? participantVisibleName,
    Value<String>? participantCity,
    Value<String?>? participantProfilePhotoUrl,
    Value<DateTime>? lastSyncedAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return LocalRequestsCompanion(
      cacheUserId: cacheUserId ?? this.cacheUserId,
      remoteId: remoteId ?? this.remoteId,
      collectionType: collectionType ?? this.collectionType,
      detailCached: detailCached ?? this.detailCached,
      status: status ?? this.status,
      cancellationCause: cancellationCause ?? this.cancellationCause,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      donationRemoteId: donationRemoteId ?? this.donationRemoteId,
      donationTitle: donationTitle ?? this.donationTitle,
      donationStatus: donationStatus ?? this.donationStatus,
      donationMainImageUrl: donationMainImageUrl ?? this.donationMainImageUrl,
      participantRemoteId: participantRemoteId ?? this.participantRemoteId,
      participantVisibleName:
          participantVisibleName ?? this.participantVisibleName,
      participantCity: participantCity ?? this.participantCity,
      participantProfilePhotoUrl:
          participantProfilePhotoUrl ?? this.participantProfilePhotoUrl,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheUserId.present) {
      map['cache_user_id'] = Variable<int>(cacheUserId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (collectionType.present) {
      map['collection_type'] = Variable<String>(
        $LocalRequestsTable.$convertercollectionType.toSql(
          collectionType.value,
        ),
      );
    }
    if (detailCached.present) {
      map['detail_cached'] = Variable<bool>(detailCached.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (cancellationCause.present) {
      map['cancellation_cause'] = Variable<String>(cancellationCause.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (rejectedAt.present) {
      map['rejected_at'] = Variable<DateTime>(rejectedAt.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<DateTime>(cancelledAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (donationRemoteId.present) {
      map['donation_remote_id'] = Variable<int>(donationRemoteId.value);
    }
    if (donationTitle.present) {
      map['donation_title'] = Variable<String>(donationTitle.value);
    }
    if (donationStatus.present) {
      map['donation_status'] = Variable<String>(donationStatus.value);
    }
    if (donationMainImageUrl.present) {
      map['donation_main_image_url'] = Variable<String>(
        donationMainImageUrl.value,
      );
    }
    if (participantRemoteId.present) {
      map['participant_remote_id'] = Variable<int>(participantRemoteId.value);
    }
    if (participantVisibleName.present) {
      map['participant_visible_name'] = Variable<String>(
        participantVisibleName.value,
      );
    }
    if (participantCity.present) {
      map['participant_city'] = Variable<String>(participantCity.value);
    }
    if (participantProfilePhotoUrl.present) {
      map['participant_profile_photo_url'] = Variable<String>(
        participantProfilePhotoUrl.value,
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRequestsCompanion(')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('remoteId: $remoteId, ')
          ..write('collectionType: $collectionType, ')
          ..write('detailCached: $detailCached, ')
          ..write('status: $status, ')
          ..write('cancellationCause: $cancellationCause, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('donationRemoteId: $donationRemoteId, ')
          ..write('donationTitle: $donationTitle, ')
          ..write('donationStatus: $donationStatus, ')
          ..write('donationMainImageUrl: $donationMainImageUrl, ')
          ..write('participantRemoteId: $participantRemoteId, ')
          ..write('participantVisibleName: $participantVisibleName, ')
          ..write('participantCity: $participantCity, ')
          ..write('participantProfilePhotoUrl: $participantProfilePhotoUrl, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCollectionMetadataTable extends LocalCollectionMetadata
    with TableInfo<$LocalCollectionMetadataTable, LocalCollectionMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCollectionMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheUserIdMeta = const VerificationMeta(
    'cacheUserId',
  );
  @override
  late final GeneratedColumn<int> cacheUserId = GeneratedColumn<int>(
    'cache_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionKeyMeta = const VerificationMeta(
    'collectionKey',
  );
  @override
  late final GeneratedColumn<String> collectionKey = GeneratedColumn<String>(
    'collection_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheUserId,
    collectionKey,
    lastSyncedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_collection_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCollectionMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_user_id')) {
      context.handle(
        _cacheUserIdMeta,
        cacheUserId.isAcceptableOrUnknown(
          data['cache_user_id']!,
          _cacheUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheUserIdMeta);
    }
    if (data.containsKey('collection_key')) {
      context.handle(
        _collectionKeyMeta,
        collectionKey.isAcceptableOrUnknown(
          data['collection_key']!,
          _collectionKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionKeyMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheUserId, collectionKey};
  @override
  LocalCollectionMetadataData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCollectionMetadataData(
      cacheUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_user_id'],
      )!,
      collectionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_key'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $LocalCollectionMetadataTable createAlias(String alias) {
    return $LocalCollectionMetadataTable(attachedDatabase, alias);
  }
}

class LocalCollectionMetadataData extends DataClass
    implements Insertable<LocalCollectionMetadataData> {
  final int cacheUserId;
  final String collectionKey;
  final DateTime lastSyncedAt;
  final DateTime expiresAt;
  const LocalCollectionMetadataData({
    required this.cacheUserId,
    required this.collectionKey,
    required this.lastSyncedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_user_id'] = Variable<int>(cacheUserId);
    map['collection_key'] = Variable<String>(collectionKey);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  LocalCollectionMetadataCompanion toCompanion(bool nullToAbsent) {
    return LocalCollectionMetadataCompanion(
      cacheUserId: Value(cacheUserId),
      collectionKey: Value(collectionKey),
      lastSyncedAt: Value(lastSyncedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory LocalCollectionMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCollectionMetadataData(
      cacheUserId: serializer.fromJson<int>(json['cacheUserId']),
      collectionKey: serializer.fromJson<String>(json['collectionKey']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheUserId': serializer.toJson<int>(cacheUserId),
      'collectionKey': serializer.toJson<String>(collectionKey),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  LocalCollectionMetadataData copyWith({
    int? cacheUserId,
    String? collectionKey,
    DateTime? lastSyncedAt,
    DateTime? expiresAt,
  }) => LocalCollectionMetadataData(
    cacheUserId: cacheUserId ?? this.cacheUserId,
    collectionKey: collectionKey ?? this.collectionKey,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  LocalCollectionMetadataData copyWithCompanion(
    LocalCollectionMetadataCompanion data,
  ) {
    return LocalCollectionMetadataData(
      cacheUserId: data.cacheUserId.present
          ? data.cacheUserId.value
          : this.cacheUserId,
      collectionKey: data.collectionKey.present
          ? data.collectionKey.value
          : this.collectionKey,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCollectionMetadataData(')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('collectionKey: $collectionKey, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheUserId, collectionKey, lastSyncedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCollectionMetadataData &&
          other.cacheUserId == this.cacheUserId &&
          other.collectionKey == this.collectionKey &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.expiresAt == this.expiresAt);
}

class LocalCollectionMetadataCompanion
    extends UpdateCompanion<LocalCollectionMetadataData> {
  final Value<int> cacheUserId;
  final Value<String> collectionKey;
  final Value<DateTime> lastSyncedAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const LocalCollectionMetadataCompanion({
    this.cacheUserId = const Value.absent(),
    this.collectionKey = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCollectionMetadataCompanion.insert({
    required int cacheUserId,
    required String collectionKey,
    required DateTime lastSyncedAt,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : cacheUserId = Value(cacheUserId),
       collectionKey = Value(collectionKey),
       lastSyncedAt = Value(lastSyncedAt),
       expiresAt = Value(expiresAt);
  static Insertable<LocalCollectionMetadataData> custom({
    Expression<int>? cacheUserId,
    Expression<String>? collectionKey,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheUserId != null) 'cache_user_id': cacheUserId,
      if (collectionKey != null) 'collection_key': collectionKey,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCollectionMetadataCompanion copyWith({
    Value<int>? cacheUserId,
    Value<String>? collectionKey,
    Value<DateTime>? lastSyncedAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return LocalCollectionMetadataCompanion(
      cacheUserId: cacheUserId ?? this.cacheUserId,
      collectionKey: collectionKey ?? this.collectionKey,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheUserId.present) {
      map['cache_user_id'] = Variable<int>(cacheUserId.value);
    }
    if (collectionKey.present) {
      map['collection_key'] = Variable<String>(collectionKey.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCollectionMetadataCompanion(')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('collectionKey: $collectionKey, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheUserIdMeta = const VerificationMeta(
    'cacheUserId',
  );
  @override
  late final GeneratedColumn<int> cacheUserId = GeneratedColumn<int>(
    'cache_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    PendingOperationEntityType,
    String
  >
  entityType =
      GeneratedColumn<String>(
        'entity_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PendingOperationEntityType>(
        $PendingOperationsTable.$converterentityType,
      );
  static const VerificationMeta _entityClientIdMeta = const VerificationMeta(
    'entityClientId',
  );
  @override
  late final GeneratedColumn<String> entityClientId = GeneratedColumn<String>(
    'entity_client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PendingOperationType, String>
  operationType =
      GeneratedColumn<String>(
        'operation_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PendingOperationType>(
        $PendingOperationsTable.$converteroperationType,
      );
  @override
  late final GeneratedColumnWithTypeConverter<PendingOperationState, String>
  state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(PendingOperationState.pending.name),
      ).withConverter<PendingOperationState>(
        $PendingOperationsTable.$converterstate,
      );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    operationId,
    cacheUserId,
    entityType,
    entityClientId,
    operationType,
    state,
    attemptCount,
    createdAt,
    nextAttemptAt,
    lastAttemptAt,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('cache_user_id')) {
      context.handle(
        _cacheUserIdMeta,
        cacheUserId.isAcceptableOrUnknown(
          data['cache_user_id']!,
          _cacheUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheUserIdMeta);
    }
    if (data.containsKey('entity_client_id')) {
      context.handle(
        _entityClientIdMeta,
        entityClientId.isAcceptableOrUnknown(
          data['entity_client_id']!,
          _entityClientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityClientIdMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {operationId},
  ];
  @override
  PendingOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperation(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      cacheUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_user_id'],
      )!,
      entityType: $PendingOperationsTable.$converterentityType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}entity_type'],
        )!,
      ),
      entityClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_client_id'],
      )!,
      operationType: $PendingOperationsTable.$converteroperationType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}operation_type'],
        )!,
      ),
      state: $PendingOperationsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PendingOperationEntityType, String, String>
  $converterentityType = const EnumNameConverter<PendingOperationEntityType>(
    PendingOperationEntityType.values,
  );
  static JsonTypeConverter2<PendingOperationType, String, String>
  $converteroperationType = const EnumNameConverter<PendingOperationType>(
    PendingOperationType.values,
  );
  static JsonTypeConverter2<PendingOperationState, String, String>
  $converterstate = const EnumNameConverter<PendingOperationState>(
    PendingOperationState.values,
  );
}

class PendingOperation extends DataClass
    implements Insertable<PendingOperation> {
  final int localId;
  final String operationId;
  final int cacheUserId;
  final PendingOperationEntityType entityType;
  final String entityClientId;
  final PendingOperationType operationType;
  final PendingOperationState state;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;
  final DateTime? lastAttemptAt;
  final String? lastErrorCode;
  const PendingOperation({
    required this.localId,
    required this.operationId,
    required this.cacheUserId,
    required this.entityType,
    required this.entityClientId,
    required this.operationType,
    required this.state,
    required this.attemptCount,
    required this.createdAt,
    this.nextAttemptAt,
    this.lastAttemptAt,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['operation_id'] = Variable<String>(operationId);
    map['cache_user_id'] = Variable<int>(cacheUserId);
    {
      map['entity_type'] = Variable<String>(
        $PendingOperationsTable.$converterentityType.toSql(entityType),
      );
    }
    map['entity_client_id'] = Variable<String>(entityClientId);
    {
      map['operation_type'] = Variable<String>(
        $PendingOperationsTable.$converteroperationType.toSql(operationType),
      );
    }
    {
      map['state'] = Variable<String>(
        $PendingOperationsTable.$converterstate.toSql(state),
      );
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      localId: Value(localId),
      operationId: Value(operationId),
      cacheUserId: Value(cacheUserId),
      entityType: Value(entityType),
      entityClientId: Value(entityClientId),
      operationType: Value(operationType),
      state: Value(state),
      attemptCount: Value(attemptCount),
      createdAt: Value(createdAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory PendingOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperation(
      localId: serializer.fromJson<int>(json['localId']),
      operationId: serializer.fromJson<String>(json['operationId']),
      cacheUserId: serializer.fromJson<int>(json['cacheUserId']),
      entityType: $PendingOperationsTable.$converterentityType.fromJson(
        serializer.fromJson<String>(json['entityType']),
      ),
      entityClientId: serializer.fromJson<String>(json['entityClientId']),
      operationType: $PendingOperationsTable.$converteroperationType.fromJson(
        serializer.fromJson<String>(json['operationType']),
      ),
      state: $PendingOperationsTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'operationId': serializer.toJson<String>(operationId),
      'cacheUserId': serializer.toJson<int>(cacheUserId),
      'entityType': serializer.toJson<String>(
        $PendingOperationsTable.$converterentityType.toJson(entityType),
      ),
      'entityClientId': serializer.toJson<String>(entityClientId),
      'operationType': serializer.toJson<String>(
        $PendingOperationsTable.$converteroperationType.toJson(operationType),
      ),
      'state': serializer.toJson<String>(
        $PendingOperationsTable.$converterstate.toJson(state),
      ),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
    };
  }

  PendingOperation copyWith({
    int? localId,
    String? operationId,
    int? cacheUserId,
    PendingOperationEntityType? entityType,
    String? entityClientId,
    PendingOperationType? operationType,
    PendingOperationState? state,
    int? attemptCount,
    DateTime? createdAt,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
  }) => PendingOperation(
    localId: localId ?? this.localId,
    operationId: operationId ?? this.operationId,
    cacheUserId: cacheUserId ?? this.cacheUserId,
    entityType: entityType ?? this.entityType,
    entityClientId: entityClientId ?? this.entityClientId,
    operationType: operationType ?? this.operationType,
    state: state ?? this.state,
    attemptCount: attemptCount ?? this.attemptCount,
    createdAt: createdAt ?? this.createdAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  PendingOperation copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperation(
      localId: data.localId.present ? data.localId.value : this.localId,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      cacheUserId: data.cacheUserId.present
          ? data.cacheUserId.value
          : this.cacheUserId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityClientId: data.entityClientId.present
          ? data.entityClientId.value
          : this.entityClientId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      state: data.state.present ? data.state.value : this.state,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperation(')
          ..write('localId: $localId, ')
          ..write('operationId: $operationId, ')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('entityType: $entityType, ')
          ..write('entityClientId: $entityClientId, ')
          ..write('operationType: $operationType, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    operationId,
    cacheUserId,
    entityType,
    entityClientId,
    operationType,
    state,
    attemptCount,
    createdAt,
    nextAttemptAt,
    lastAttemptAt,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperation &&
          other.localId == this.localId &&
          other.operationId == this.operationId &&
          other.cacheUserId == this.cacheUserId &&
          other.entityType == this.entityType &&
          other.entityClientId == this.entityClientId &&
          other.operationType == this.operationType &&
          other.state == this.state &&
          other.attemptCount == this.attemptCount &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastErrorCode == this.lastErrorCode);
}

class PendingOperationsCompanion extends UpdateCompanion<PendingOperation> {
  final Value<int> localId;
  final Value<String> operationId;
  final Value<int> cacheUserId;
  final Value<PendingOperationEntityType> entityType;
  final Value<String> entityClientId;
  final Value<PendingOperationType> operationType;
  final Value<PendingOperationState> state;
  final Value<int> attemptCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastErrorCode;
  const PendingOperationsCompanion({
    this.localId = const Value.absent(),
    this.operationId = const Value.absent(),
    this.cacheUserId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityClientId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    this.localId = const Value.absent(),
    required String operationId,
    required int cacheUserId,
    required PendingOperationEntityType entityType,
    required String entityClientId,
    required PendingOperationType operationType,
    this.state = const Value.absent(),
    this.attemptCount = const Value.absent(),
    required DateTime createdAt,
    this.nextAttemptAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  }) : operationId = Value(operationId),
       cacheUserId = Value(cacheUserId),
       entityType = Value(entityType),
       entityClientId = Value(entityClientId),
       operationType = Value(operationType),
       createdAt = Value(createdAt);
  static Insertable<PendingOperation> custom({
    Expression<int>? localId,
    Expression<String>? operationId,
    Expression<int>? cacheUserId,
    Expression<String>? entityType,
    Expression<String>? entityClientId,
    Expression<String>? operationType,
    Expression<String>? state,
    Expression<int>? attemptCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastErrorCode,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (operationId != null) 'operation_id': operationId,
      if (cacheUserId != null) 'cache_user_id': cacheUserId,
      if (entityType != null) 'entity_type': entityType,
      if (entityClientId != null) 'entity_client_id': entityClientId,
      if (operationType != null) 'operation_type': operationType,
      if (state != null) 'state': state,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<int>? localId,
    Value<String>? operationId,
    Value<int>? cacheUserId,
    Value<PendingOperationEntityType>? entityType,
    Value<String>? entityClientId,
    Value<PendingOperationType>? operationType,
    Value<PendingOperationState>? state,
    Value<int>? attemptCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastErrorCode,
  }) {
    return PendingOperationsCompanion(
      localId: localId ?? this.localId,
      operationId: operationId ?? this.operationId,
      cacheUserId: cacheUserId ?? this.cacheUserId,
      entityType: entityType ?? this.entityType,
      entityClientId: entityClientId ?? this.entityClientId,
      operationType: operationType ?? this.operationType,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (cacheUserId.present) {
      map['cache_user_id'] = Variable<int>(cacheUserId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(
        $PendingOperationsTable.$converterentityType.toSql(entityType.value),
      );
    }
    if (entityClientId.present) {
      map['entity_client_id'] = Variable<String>(entityClientId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(
        $PendingOperationsTable.$converteroperationType.toSql(
          operationType.value,
        ),
      );
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $PendingOperationsTable.$converterstate.toSql(state.value),
      );
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('localId: $localId, ')
          ..write('operationId: $operationId, ')
          ..write('cacheUserId: $cacheUserId, ')
          ..write('entityType: $entityType, ')
          ..write('entityClientId: $entityClientId, ')
          ..write('operationType: $operationType, ')
          ..write('state: $state, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalAuthenticatedUsersTable localAuthenticatedUsers =
      $LocalAuthenticatedUsersTable(this);
  late final $LocalCategoriesTable localCategories = $LocalCategoriesTable(
    this,
  );
  late final $LocalDonationsTable localDonations = $LocalDonationsTable(this);
  late final $LocalDonationMembershipsTable localDonationMemberships =
      $LocalDonationMembershipsTable(this);
  late final $LocalDonationImagesTable localDonationImages =
      $LocalDonationImagesTable(this);
  late final $LocalRequestsTable localRequests = $LocalRequestsTable(this);
  late final $LocalCollectionMetadataTable localCollectionMetadata =
      $LocalCollectionMetadataTable(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  late final Index pendingOperationsProcessableIdx = Index(
    'pending_operations_processable_idx',
    'CREATE INDEX pending_operations_processable_idx ON pending_operations (cache_user_id, state, next_attempt_at)',
  );
  late final Index pendingOperationsEntityIdx = Index(
    'pending_operations_entity_idx',
    'CREATE INDEX pending_operations_entity_idx ON pending_operations (cache_user_id, entity_client_id)',
  );
  late final LocalCacheDao localCacheDao = LocalCacheDao(this as AppDatabase);
  late final PendingOperationsDao pendingOperationsDao = PendingOperationsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localAuthenticatedUsers,
    localCategories,
    localDonations,
    localDonationMemberships,
    localDonationImages,
    localRequests,
    localCollectionMetadata,
    pendingOperations,
    pendingOperationsProcessableIdx,
    pendingOperationsEntityIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_donations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('local_donation_memberships', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_donations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('local_donation_images', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocalAuthenticatedUsersTableCreateCompanionBuilder =
    LocalAuthenticatedUsersCompanion Function({
      Value<int> userId,
      required String nombreVisible,
      required String city,
      required DateTime lastValidatedAt,
      required DateTime offlineSessionValidUntil,
    });
typedef $$LocalAuthenticatedUsersTableUpdateCompanionBuilder =
    LocalAuthenticatedUsersCompanion Function({
      Value<int> userId,
      Value<String> nombreVisible,
      Value<String> city,
      Value<DateTime> lastValidatedAt,
      Value<DateTime> offlineSessionValidUntil,
    });

class $$LocalAuthenticatedUsersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAuthenticatedUsersTable> {
  $$LocalAuthenticatedUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreVisible => $composableBuilder(
    column: $table.nombreVisible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastValidatedAt => $composableBuilder(
    column: $table.lastValidatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get offlineSessionValidUntil => $composableBuilder(
    column: $table.offlineSessionValidUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAuthenticatedUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAuthenticatedUsersTable> {
  $$LocalAuthenticatedUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreVisible => $composableBuilder(
    column: $table.nombreVisible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastValidatedAt => $composableBuilder(
    column: $table.lastValidatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get offlineSessionValidUntil => $composableBuilder(
    column: $table.offlineSessionValidUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAuthenticatedUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAuthenticatedUsersTable> {
  $$LocalAuthenticatedUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get nombreVisible => $composableBuilder(
    column: $table.nombreVisible,
    builder: (column) => column,
  );

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<DateTime> get lastValidatedAt => $composableBuilder(
    column: $table.lastValidatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get offlineSessionValidUntil => $composableBuilder(
    column: $table.offlineSessionValidUntil,
    builder: (column) => column,
  );
}

class $$LocalAuthenticatedUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAuthenticatedUsersTable,
          LocalAuthenticatedUser,
          $$LocalAuthenticatedUsersTableFilterComposer,
          $$LocalAuthenticatedUsersTableOrderingComposer,
          $$LocalAuthenticatedUsersTableAnnotationComposer,
          $$LocalAuthenticatedUsersTableCreateCompanionBuilder,
          $$LocalAuthenticatedUsersTableUpdateCompanionBuilder,
          (
            LocalAuthenticatedUser,
            BaseReferences<
              _$AppDatabase,
              $LocalAuthenticatedUsersTable,
              LocalAuthenticatedUser
            >,
          ),
          LocalAuthenticatedUser,
          PrefetchHooks Function()
        > {
  $$LocalAuthenticatedUsersTableTableManager(
    _$AppDatabase db,
    $LocalAuthenticatedUsersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAuthenticatedUsersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalAuthenticatedUsersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalAuthenticatedUsersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<String> nombreVisible = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<DateTime> lastValidatedAt = const Value.absent(),
                Value<DateTime> offlineSessionValidUntil = const Value.absent(),
              }) => LocalAuthenticatedUsersCompanion(
                userId: userId,
                nombreVisible: nombreVisible,
                city: city,
                lastValidatedAt: lastValidatedAt,
                offlineSessionValidUntil: offlineSessionValidUntil,
              ),
          createCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                required String nombreVisible,
                required String city,
                required DateTime lastValidatedAt,
                required DateTime offlineSessionValidUntil,
              }) => LocalAuthenticatedUsersCompanion.insert(
                userId: userId,
                nombreVisible: nombreVisible,
                city: city,
                lastValidatedAt: lastValidatedAt,
                offlineSessionValidUntil: offlineSessionValidUntil,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalAuthenticatedUsersTable,
                    LocalAuthenticatedUser
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAuthenticatedUsersTable,
                    LocalAuthenticatedUser
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAuthenticatedUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAuthenticatedUsersTable,
      LocalAuthenticatedUser,
      $$LocalAuthenticatedUsersTableFilterComposer,
      $$LocalAuthenticatedUsersTableOrderingComposer,
      $$LocalAuthenticatedUsersTableAnnotationComposer,
      $$LocalAuthenticatedUsersTableCreateCompanionBuilder,
      $$LocalAuthenticatedUsersTableUpdateCompanionBuilder,
      (
        LocalAuthenticatedUser,
        BaseReferences<
          _$AppDatabase,
          $LocalAuthenticatedUsersTable,
          LocalAuthenticatedUser
        >,
      ),
      LocalAuthenticatedUser,
      PrefetchHooks Function()
    >;
typedef $$LocalCategoriesTableCreateCompanionBuilder =
    LocalCategoriesCompanion Function({
      Value<int> remoteId,
      required String name,
      Value<String?> description,
      required DateTime lastSyncedAt,
      required DateTime expiresAt,
    });
typedef $$LocalCategoriesTableUpdateCompanionBuilder =
    LocalCategoriesCompanion Function({
      Value<int> remoteId,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> lastSyncedAt,
      Value<DateTime> expiresAt,
    });

class $$LocalCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$LocalCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCategoriesTable,
          LocalCategory,
          $$LocalCategoriesTableFilterComposer,
          $$LocalCategoriesTableOrderingComposer,
          $$LocalCategoriesTableAnnotationComposer,
          $$LocalCategoriesTableCreateCompanionBuilder,
          $$LocalCategoriesTableUpdateCompanionBuilder,
          (
            LocalCategory,
            BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
          ),
          LocalCategory,
          PrefetchHooks Function()
        > {
  $$LocalCategoriesTableTableManager(
    _$AppDatabase db,
    $LocalCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
              }) => LocalCategoriesCompanion(
                remoteId: remoteId,
                name: name,
                description: description,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
              ),
          createCompanionCallback:
              ({
                Value<int> remoteId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime lastSyncedAt,
                required DateTime expiresAt,
              }) => LocalCategoriesCompanion.insert(
                remoteId: remoteId,
                name: name,
                description: description,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCategoriesTable, LocalCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCategoriesTable,
                    LocalCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCategoriesTable,
      LocalCategory,
      $$LocalCategoriesTableFilterComposer,
      $$LocalCategoriesTableOrderingComposer,
      $$LocalCategoriesTableAnnotationComposer,
      $$LocalCategoriesTableCreateCompanionBuilder,
      $$LocalCategoriesTableUpdateCompanionBuilder,
      (
        LocalCategory,
        BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
      ),
      LocalCategory,
      PrefetchHooks Function()
    >;
typedef $$LocalDonationsTableCreateCompanionBuilder =
    LocalDonationsCompanion Function({
      Value<int> localId,
      required int cacheUserId,
      required String clientId,
      Value<int?> remoteId,
      Value<DateTime?> lastSyncedAt,
      required DateTime expiresAt,
      Value<DateTime?> detailExpiresAt,
      required DonationSyncState syncState,
      Value<bool> locallyDeleted,
      required String title,
      Value<String?> description,
      required String city,
      Value<String?> status,
      required int categoryId,
      required String categoryName,
      Value<String?> mainImageUrl,
      Value<int> imageCount,
      Value<DateTime?> createdAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> lastAccessedAt,
    });
typedef $$LocalDonationsTableUpdateCompanionBuilder =
    LocalDonationsCompanion Function({
      Value<int> localId,
      Value<int> cacheUserId,
      Value<String> clientId,
      Value<int?> remoteId,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime> expiresAt,
      Value<DateTime?> detailExpiresAt,
      Value<DonationSyncState> syncState,
      Value<bool> locallyDeleted,
      Value<String> title,
      Value<String?> description,
      Value<String> city,
      Value<String?> status,
      Value<int> categoryId,
      Value<String> categoryName,
      Value<String?> mainImageUrl,
      Value<int> imageCount,
      Value<DateTime?> createdAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> lastAccessedAt,
    });

final class $$LocalDonationsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalDonationsTable, LocalDonation> {
  $$LocalDonationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $LocalDonationMembershipsTable,
    List<LocalDonationMembership>
  >
  _localDonationMembershipsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localDonationMemberships,
        aliasName: 'local_donations__local_id__local_donation_memberships__local_donation_id',
      );

  $$LocalDonationMembershipsTableProcessedTableManager
  get localDonationMembershipsRefs {
    final manager =
        $$LocalDonationMembershipsTableTableManager(
          $_db,
          $_db.localDonationMemberships,
        ).filter(
          (f) => f.localDonationId.localId.sqlEquals(
            $_itemColumn<int>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _localDonationMembershipsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LocalDonationImagesTable,
    List<LocalDonationImage>
  >
  _localDonationImagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.localDonationImages,
    aliasName:
        'local_donations__local_id__local_donation_images__local_donation_id',
  );

  $$LocalDonationImagesTableProcessedTableManager get localDonationImagesRefs {
    final manager =
        $$LocalDonationImagesTableTableManager(
          $_db,
          $_db.localDonationImages,
        ).filter(
          (f) => f.localDonationId.localId.sqlEquals(
            $_itemColumn<int>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _localDonationImagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalDonationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDonationsTable> {
  $$LocalDonationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detailExpiresAt => $composableBuilder(
    column: $table.detailExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DonationSyncState, DonationSyncState, String>
  get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get locallyDeleted => $composableBuilder(
    column: $table.locallyDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mainImageUrl => $composableBuilder(
    column: $table.mainImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localDonationMembershipsRefs(
    Expression<bool> Function($$LocalDonationMembershipsTableFilterComposer f)
    f,
  ) {
    final $$LocalDonationMembershipsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.localDonationMemberships,
          getReferencedColumn: (t) => t.localDonationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalDonationMembershipsTableFilterComposer(
                $db: $db,
                $table: $db.localDonationMemberships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> localDonationImagesRefs(
    Expression<bool> Function($$LocalDonationImagesTableFilterComposer f) f,
  ) {
    final $$LocalDonationImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.localDonationImages,
      getReferencedColumn: (t) => t.localDonationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDonationImagesTableFilterComposer(
            $db: $db,
            $table: $db.localDonationImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalDonationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDonationsTable> {
  $$LocalDonationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detailExpiresAt => $composableBuilder(
    column: $table.detailExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get locallyDeleted => $composableBuilder(
    column: $table.locallyDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mainImageUrl => $composableBuilder(
    column: $table.mainImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDonationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDonationsTable> {
  $$LocalDonationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get detailExpiresAt => $composableBuilder(
    column: $table.detailExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DonationSyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<bool> get locallyDeleted => $composableBuilder(
    column: $table.locallyDeleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mainImageUrl => $composableBuilder(
    column: $table.mainImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  Expression<T> localDonationMembershipsRefs<T extends Object>(
    Expression<T> Function($$LocalDonationMembershipsTableAnnotationComposer a)
    f,
  ) {
    final $$LocalDonationMembershipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.localDonationMemberships,
          getReferencedColumn: (t) => t.localDonationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalDonationMembershipsTableAnnotationComposer(
                $db: $db,
                $table: $db.localDonationMemberships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> localDonationImagesRefs<T extends Object>(
    Expression<T> Function($$LocalDonationImagesTableAnnotationComposer a) f,
  ) {
    final $$LocalDonationImagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.localDonationImages,
          getReferencedColumn: (t) => t.localDonationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalDonationImagesTableAnnotationComposer(
                $db: $db,
                $table: $db.localDonationImages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalDonationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDonationsTable,
          LocalDonation,
          $$LocalDonationsTableFilterComposer,
          $$LocalDonationsTableOrderingComposer,
          $$LocalDonationsTableAnnotationComposer,
          $$LocalDonationsTableCreateCompanionBuilder,
          $$LocalDonationsTableUpdateCompanionBuilder,
          (LocalDonation, $$LocalDonationsTableReferences),
          LocalDonation,
          PrefetchHooks Function({
            bool localDonationMembershipsRefs,
            bool localDonationImagesRefs,
          })
        > {
  $$LocalDonationsTableTableManager(
    _$AppDatabase db,
    $LocalDonationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDonationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDonationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDonationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<int> cacheUserId = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime?> detailExpiresAt = const Value.absent(),
                Value<DonationSyncState> syncState = const Value.absent(),
                Value<bool> locallyDeleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String?> mainImageUrl = const Value.absent(),
                Value<int> imageCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
              }) => LocalDonationsCompanion(
                localId: localId,
                cacheUserId: cacheUserId,
                clientId: clientId,
                remoteId: remoteId,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
                detailExpiresAt: detailExpiresAt,
                syncState: syncState,
                locallyDeleted: locallyDeleted,
                title: title,
                description: description,
                city: city,
                status: status,
                categoryId: categoryId,
                categoryName: categoryName,
                mainImageUrl: mainImageUrl,
                imageCount: imageCount,
                createdAt: createdAt,
                serverUpdatedAt: serverUpdatedAt,
                lastAccessedAt: lastAccessedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required int cacheUserId,
                required String clientId,
                Value<int?> remoteId = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                required DateTime expiresAt,
                Value<DateTime?> detailExpiresAt = const Value.absent(),
                required DonationSyncState syncState,
                Value<bool> locallyDeleted = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required String city,
                Value<String?> status = const Value.absent(),
                required int categoryId,
                required String categoryName,
                Value<String?> mainImageUrl = const Value.absent(),
                Value<int> imageCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
              }) => LocalDonationsCompanion.insert(
                localId: localId,
                cacheUserId: cacheUserId,
                clientId: clientId,
                remoteId: remoteId,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
                detailExpiresAt: detailExpiresAt,
                syncState: syncState,
                locallyDeleted: locallyDeleted,
                title: title,
                description: description,
                city: city,
                status: status,
                categoryId: categoryId,
                categoryName: categoryName,
                mainImageUrl: mainImageUrl,
                imageCount: imageCount,
                createdAt: createdAt,
                serverUpdatedAt: serverUpdatedAt,
                lastAccessedAt: lastAccessedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDonationsTable, LocalDonation>(table),
                  $$LocalDonationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                localDonationMembershipsRefs = false,
                localDonationImagesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localDonationMembershipsRefs)
                      db.localDonationMemberships,
                    if (localDonationImagesRefs) db.localDonationImages,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localDonationMembershipsRefs)
                        await $_getPrefetchedData<
                          LocalDonation,
                          $LocalDonationsTable,
                          LocalDonationMembership
                        >(
                          currentTable: table,
                          referencedTable: $$LocalDonationsTableReferences
                              ._localDonationMembershipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalDonationsTableReferences(
                                db,
                                table,
                                p0,
                              ).localDonationMembershipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localDonationId == item.localId,
                              ),
                          typedResults: items,
                        ),
                      if (localDonationImagesRefs)
                        await $_getPrefetchedData<
                          LocalDonation,
                          $LocalDonationsTable,
                          LocalDonationImage
                        >(
                          currentTable: table,
                          referencedTable: $$LocalDonationsTableReferences
                              ._localDonationImagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalDonationsTableReferences(
                                db,
                                table,
                                p0,
                              ).localDonationImagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localDonationId == item.localId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalDonationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDonationsTable,
      LocalDonation,
      $$LocalDonationsTableFilterComposer,
      $$LocalDonationsTableOrderingComposer,
      $$LocalDonationsTableAnnotationComposer,
      $$LocalDonationsTableCreateCompanionBuilder,
      $$LocalDonationsTableUpdateCompanionBuilder,
      (LocalDonation, $$LocalDonationsTableReferences),
      LocalDonation,
      PrefetchHooks Function({
        bool localDonationMembershipsRefs,
        bool localDonationImagesRefs,
      })
    >;
typedef $$LocalDonationMembershipsTableCreateCompanionBuilder =
    LocalDonationMembershipsCompanion Function({
      required int cacheUserId,
      required int localDonationId,
      required DonationCollectionType collectionType,
      required DateTime lastSeenAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$LocalDonationMembershipsTableUpdateCompanionBuilder =
    LocalDonationMembershipsCompanion Function({
      Value<int> cacheUserId,
      Value<int> localDonationId,
      Value<DonationCollectionType> collectionType,
      Value<DateTime> lastSeenAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

final class $$LocalDonationMembershipsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalDonationMembershipsTable,
          LocalDonationMembership
        > {
  $$LocalDonationMembershipsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalDonationsTable _localDonationIdTable(
    _$AppDatabase db,
  ) => db.localDonations.createAlias(
    'local_donation_memberships__local_donation_id__local_donations__local_id',
  );

  $$LocalDonationsTableProcessedTableManager get localDonationId {
    final $_column = $_itemColumn<int>('local_donation_id')!;

    final manager = $$LocalDonationsTableTableManager(
      $_db,
      $_db.localDonations,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localDonationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalDonationMembershipsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDonationMembershipsTable> {
  $$LocalDonationMembershipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    DonationCollectionType,
    DonationCollectionType,
    String
  >
  get collectionType => $composableBuilder(
    column: $table.collectionType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalDonationsTableFilterComposer get localDonationId {
    final $$LocalDonationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDonationId,
      referencedTable: $db.localDonations,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDonationsTableFilterComposer(
            $db: $db,
            $table: $db.localDonations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDonationMembershipsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDonationMembershipsTable> {
  $$LocalDonationMembershipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionType => $composableBuilder(
    column: $table.collectionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalDonationsTableOrderingComposer get localDonationId {
    final $$LocalDonationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDonationId,
      referencedTable: $db.localDonations,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDonationsTableOrderingComposer(
            $db: $db,
            $table: $db.localDonations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDonationMembershipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDonationMembershipsTable> {
  $$LocalDonationMembershipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DonationCollectionType, String>
  get collectionType => $composableBuilder(
    column: $table.collectionType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  $$LocalDonationsTableAnnotationComposer get localDonationId {
    final $$LocalDonationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDonationId,
      referencedTable: $db.localDonations,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDonationsTableAnnotationComposer(
            $db: $db,
            $table: $db.localDonations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDonationMembershipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDonationMembershipsTable,
          LocalDonationMembership,
          $$LocalDonationMembershipsTableFilterComposer,
          $$LocalDonationMembershipsTableOrderingComposer,
          $$LocalDonationMembershipsTableAnnotationComposer,
          $$LocalDonationMembershipsTableCreateCompanionBuilder,
          $$LocalDonationMembershipsTableUpdateCompanionBuilder,
          (LocalDonationMembership, $$LocalDonationMembershipsTableReferences),
          LocalDonationMembership,
          PrefetchHooks Function({bool localDonationId})
        > {
  $$LocalDonationMembershipsTableTableManager(
    _$AppDatabase db,
    $LocalDonationMembershipsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDonationMembershipsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalDonationMembershipsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalDonationMembershipsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> cacheUserId = const Value.absent(),
                Value<int> localDonationId = const Value.absent(),
                Value<DonationCollectionType> collectionType =
                    const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDonationMembershipsCompanion(
                cacheUserId: cacheUserId,
                localDonationId: localDonationId,
                collectionType: collectionType,
                lastSeenAt: lastSeenAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int cacheUserId,
                required int localDonationId,
                required DonationCollectionType collectionType,
                required DateTime lastSeenAt,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalDonationMembershipsCompanion.insert(
                cacheUserId: cacheUserId,
                localDonationId: localDonationId,
                collectionType: collectionType,
                lastSeenAt: lastSeenAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalDonationMembershipsTable,
                    LocalDonationMembership
                  >(table),
                  $$LocalDonationMembershipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localDonationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localDonationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localDonationId,
                        referencedTable:
                            $$LocalDonationMembershipsTableReferences
                                ._localDonationIdTable(db),
                        referencedColumn:
                            $$LocalDonationMembershipsTableReferences
                                ._localDonationIdTable(db)
                                .localId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalDonationMembershipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDonationMembershipsTable,
      LocalDonationMembership,
      $$LocalDonationMembershipsTableFilterComposer,
      $$LocalDonationMembershipsTableOrderingComposer,
      $$LocalDonationMembershipsTableAnnotationComposer,
      $$LocalDonationMembershipsTableCreateCompanionBuilder,
      $$LocalDonationMembershipsTableUpdateCompanionBuilder,
      (LocalDonationMembership, $$LocalDonationMembershipsTableReferences),
      LocalDonationMembership,
      PrefetchHooks Function({bool localDonationId})
    >;
typedef $$LocalDonationImagesTableCreateCompanionBuilder =
    LocalDonationImagesCompanion Function({
      Value<int> localId,
      required int localDonationId,
      Value<int?> remoteImageId,
      Value<String?> remoteUrl,
      Value<String?> managedLocalPath,
      Value<String?> cachedLocalPath,
      required int sortOrder,
      Value<String?> mimeType,
      Value<int?> sizeBytes,
      required ImageUploadState uploadState,
    });
typedef $$LocalDonationImagesTableUpdateCompanionBuilder =
    LocalDonationImagesCompanion Function({
      Value<int> localId,
      Value<int> localDonationId,
      Value<int?> remoteImageId,
      Value<String?> remoteUrl,
      Value<String?> managedLocalPath,
      Value<String?> cachedLocalPath,
      Value<int> sortOrder,
      Value<String?> mimeType,
      Value<int?> sizeBytes,
      Value<ImageUploadState> uploadState,
    });

final class $$LocalDonationImagesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalDonationImagesTable,
          LocalDonationImage
        > {
  $$LocalDonationImagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalDonationsTable _localDonationIdTable(_$AppDatabase db) =>
      db.localDonations.createAlias(
        'local_donation_images__local_donation_id__local_donations__local_id',
      );

  $$LocalDonationsTableProcessedTableManager get localDonationId {
    final $_column = $_itemColumn<int>('local_donation_id')!;

    final manager = $$LocalDonationsTableTableManager(
      $_db,
      $_db.localDonations,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localDonationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalDonationImagesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDonationImagesTable> {
  $$LocalDonationImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteImageId => $composableBuilder(
    column: $table.remoteImageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managedLocalPath => $composableBuilder(
    column: $table.managedLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedLocalPath => $composableBuilder(
    column: $table.cachedLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ImageUploadState, ImageUploadState, String>
  get uploadState => $composableBuilder(
    column: $table.uploadState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$LocalDonationsTableFilterComposer get localDonationId {
    final $$LocalDonationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDonationId,
      referencedTable: $db.localDonations,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDonationsTableFilterComposer(
            $db: $db,
            $table: $db.localDonations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDonationImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDonationImagesTable> {
  $$LocalDonationImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteImageId => $composableBuilder(
    column: $table.remoteImageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managedLocalPath => $composableBuilder(
    column: $table.managedLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedLocalPath => $composableBuilder(
    column: $table.cachedLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadState => $composableBuilder(
    column: $table.uploadState,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalDonationsTableOrderingComposer get localDonationId {
    final $$LocalDonationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDonationId,
      referencedTable: $db.localDonations,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDonationsTableOrderingComposer(
            $db: $db,
            $table: $db.localDonations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDonationImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDonationImagesTable> {
  $$LocalDonationImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get remoteImageId => $composableBuilder(
    column: $table.remoteImageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteUrl =>
      $composableBuilder(column: $table.remoteUrl, builder: (column) => column);

  GeneratedColumn<String> get managedLocalPath => $composableBuilder(
    column: $table.managedLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cachedLocalPath => $composableBuilder(
    column: $table.cachedLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ImageUploadState, String> get uploadState =>
      $composableBuilder(
        column: $table.uploadState,
        builder: (column) => column,
      );

  $$LocalDonationsTableAnnotationComposer get localDonationId {
    final $$LocalDonationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDonationId,
      referencedTable: $db.localDonations,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDonationsTableAnnotationComposer(
            $db: $db,
            $table: $db.localDonations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDonationImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDonationImagesTable,
          LocalDonationImage,
          $$LocalDonationImagesTableFilterComposer,
          $$LocalDonationImagesTableOrderingComposer,
          $$LocalDonationImagesTableAnnotationComposer,
          $$LocalDonationImagesTableCreateCompanionBuilder,
          $$LocalDonationImagesTableUpdateCompanionBuilder,
          (LocalDonationImage, $$LocalDonationImagesTableReferences),
          LocalDonationImage,
          PrefetchHooks Function({bool localDonationId})
        > {
  $$LocalDonationImagesTableTableManager(
    _$AppDatabase db,
    $LocalDonationImagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDonationImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDonationImagesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalDonationImagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<int> localDonationId = const Value.absent(),
                Value<int?> remoteImageId = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> managedLocalPath = const Value.absent(),
                Value<String?> cachedLocalPath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<ImageUploadState> uploadState = const Value.absent(),
              }) => LocalDonationImagesCompanion(
                localId: localId,
                localDonationId: localDonationId,
                remoteImageId: remoteImageId,
                remoteUrl: remoteUrl,
                managedLocalPath: managedLocalPath,
                cachedLocalPath: cachedLocalPath,
                sortOrder: sortOrder,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                uploadState: uploadState,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required int localDonationId,
                Value<int?> remoteImageId = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> managedLocalPath = const Value.absent(),
                Value<String?> cachedLocalPath = const Value.absent(),
                required int sortOrder,
                Value<String?> mimeType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                required ImageUploadState uploadState,
              }) => LocalDonationImagesCompanion.insert(
                localId: localId,
                localDonationId: localDonationId,
                remoteImageId: remoteImageId,
                remoteUrl: remoteUrl,
                managedLocalPath: managedLocalPath,
                cachedLocalPath: cachedLocalPath,
                sortOrder: sortOrder,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                uploadState: uploadState,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDonationImagesTable, LocalDonationImage>(
                    table,
                  ),
                  $$LocalDonationImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localDonationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localDonationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localDonationId,
                        referencedTable: $$LocalDonationImagesTableReferences
                            ._localDonationIdTable(db),
                        referencedColumn: $$LocalDonationImagesTableReferences
                            ._localDonationIdTable(db)
                            .localId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalDonationImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDonationImagesTable,
      LocalDonationImage,
      $$LocalDonationImagesTableFilterComposer,
      $$LocalDonationImagesTableOrderingComposer,
      $$LocalDonationImagesTableAnnotationComposer,
      $$LocalDonationImagesTableCreateCompanionBuilder,
      $$LocalDonationImagesTableUpdateCompanionBuilder,
      (LocalDonationImage, $$LocalDonationImagesTableReferences),
      LocalDonationImage,
      PrefetchHooks Function({bool localDonationId})
    >;
typedef $$LocalRequestsTableCreateCompanionBuilder =
    LocalRequestsCompanion Function({
      required int cacheUserId,
      required int remoteId,
      required RequestCollectionType collectionType,
      Value<bool> detailCached,
      required String status,
      Value<String?> cancellationCause,
      Value<DateTime?> acceptedAt,
      Value<DateTime?> rejectedAt,
      Value<DateTime?> cancelledAt,
      required DateTime createdAt,
      required DateTime serverUpdatedAt,
      required int donationRemoteId,
      required String donationTitle,
      required String donationStatus,
      Value<String?> donationMainImageUrl,
      required int participantRemoteId,
      required String participantVisibleName,
      required String participantCity,
      Value<String?> participantProfilePhotoUrl,
      required DateTime lastSyncedAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$LocalRequestsTableUpdateCompanionBuilder =
    LocalRequestsCompanion Function({
      Value<int> cacheUserId,
      Value<int> remoteId,
      Value<RequestCollectionType> collectionType,
      Value<bool> detailCached,
      Value<String> status,
      Value<String?> cancellationCause,
      Value<DateTime?> acceptedAt,
      Value<DateTime?> rejectedAt,
      Value<DateTime?> cancelledAt,
      Value<DateTime> createdAt,
      Value<DateTime> serverUpdatedAt,
      Value<int> donationRemoteId,
      Value<String> donationTitle,
      Value<String> donationStatus,
      Value<String?> donationMainImageUrl,
      Value<int> participantRemoteId,
      Value<String> participantVisibleName,
      Value<String> participantCity,
      Value<String?> participantProfilePhotoUrl,
      Value<DateTime> lastSyncedAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$LocalRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRequestsTable> {
  $$LocalRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    RequestCollectionType,
    RequestCollectionType,
    String
  >
  get collectionType => $composableBuilder(
    column: $table.collectionType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get detailCached => $composableBuilder(
    column: $table.detailCached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancellationCause => $composableBuilder(
    column: $table.cancellationCause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get donationRemoteId => $composableBuilder(
    column: $table.donationRemoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get donationTitle => $composableBuilder(
    column: $table.donationTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get donationStatus => $composableBuilder(
    column: $table.donationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get donationMainImageUrl => $composableBuilder(
    column: $table.donationMainImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get participantRemoteId => $composableBuilder(
    column: $table.participantRemoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantVisibleName => $composableBuilder(
    column: $table.participantVisibleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantCity => $composableBuilder(
    column: $table.participantCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantProfilePhotoUrl => $composableBuilder(
    column: $table.participantProfilePhotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRequestsTable> {
  $$LocalRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionType => $composableBuilder(
    column: $table.collectionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get detailCached => $composableBuilder(
    column: $table.detailCached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancellationCause => $composableBuilder(
    column: $table.cancellationCause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get donationRemoteId => $composableBuilder(
    column: $table.donationRemoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get donationTitle => $composableBuilder(
    column: $table.donationTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get donationStatus => $composableBuilder(
    column: $table.donationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get donationMainImageUrl => $composableBuilder(
    column: $table.donationMainImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get participantRemoteId => $composableBuilder(
    column: $table.participantRemoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantVisibleName => $composableBuilder(
    column: $table.participantVisibleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantCity => $composableBuilder(
    column: $table.participantCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantProfilePhotoUrl => $composableBuilder(
    column: $table.participantProfilePhotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRequestsTable> {
  $$LocalRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RequestCollectionType, String>
  get collectionType => $composableBuilder(
    column: $table.collectionType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get detailCached => $composableBuilder(
    column: $table.detailCached,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get cancellationCause => $composableBuilder(
    column: $table.cancellationCause,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get donationRemoteId => $composableBuilder(
    column: $table.donationRemoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get donationTitle => $composableBuilder(
    column: $table.donationTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get donationStatus => $composableBuilder(
    column: $table.donationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get donationMainImageUrl => $composableBuilder(
    column: $table.donationMainImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get participantRemoteId => $composableBuilder(
    column: $table.participantRemoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participantVisibleName => $composableBuilder(
    column: $table.participantVisibleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participantCity => $composableBuilder(
    column: $table.participantCity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participantProfilePhotoUrl => $composableBuilder(
    column: $table.participantProfilePhotoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$LocalRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalRequestsTable,
          LocalRequest,
          $$LocalRequestsTableFilterComposer,
          $$LocalRequestsTableOrderingComposer,
          $$LocalRequestsTableAnnotationComposer,
          $$LocalRequestsTableCreateCompanionBuilder,
          $$LocalRequestsTableUpdateCompanionBuilder,
          (
            LocalRequest,
            BaseReferences<_$AppDatabase, $LocalRequestsTable, LocalRequest>,
          ),
          LocalRequest,
          PrefetchHooks Function()
        > {
  $$LocalRequestsTableTableManager(_$AppDatabase db, $LocalRequestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> cacheUserId = const Value.absent(),
                Value<int> remoteId = const Value.absent(),
                Value<RequestCollectionType> collectionType =
                    const Value.absent(),
                Value<bool> detailCached = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> cancellationCause = const Value.absent(),
                Value<DateTime?> acceptedAt = const Value.absent(),
                Value<DateTime?> rejectedAt = const Value.absent(),
                Value<DateTime?> cancelledAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> serverUpdatedAt = const Value.absent(),
                Value<int> donationRemoteId = const Value.absent(),
                Value<String> donationTitle = const Value.absent(),
                Value<String> donationStatus = const Value.absent(),
                Value<String?> donationMainImageUrl = const Value.absent(),
                Value<int> participantRemoteId = const Value.absent(),
                Value<String> participantVisibleName = const Value.absent(),
                Value<String> participantCity = const Value.absent(),
                Value<String?> participantProfilePhotoUrl =
                    const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRequestsCompanion(
                cacheUserId: cacheUserId,
                remoteId: remoteId,
                collectionType: collectionType,
                detailCached: detailCached,
                status: status,
                cancellationCause: cancellationCause,
                acceptedAt: acceptedAt,
                rejectedAt: rejectedAt,
                cancelledAt: cancelledAt,
                createdAt: createdAt,
                serverUpdatedAt: serverUpdatedAt,
                donationRemoteId: donationRemoteId,
                donationTitle: donationTitle,
                donationStatus: donationStatus,
                donationMainImageUrl: donationMainImageUrl,
                participantRemoteId: participantRemoteId,
                participantVisibleName: participantVisibleName,
                participantCity: participantCity,
                participantProfilePhotoUrl: participantProfilePhotoUrl,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int cacheUserId,
                required int remoteId,
                required RequestCollectionType collectionType,
                Value<bool> detailCached = const Value.absent(),
                required String status,
                Value<String?> cancellationCause = const Value.absent(),
                Value<DateTime?> acceptedAt = const Value.absent(),
                Value<DateTime?> rejectedAt = const Value.absent(),
                Value<DateTime?> cancelledAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime serverUpdatedAt,
                required int donationRemoteId,
                required String donationTitle,
                required String donationStatus,
                Value<String?> donationMainImageUrl = const Value.absent(),
                required int participantRemoteId,
                required String participantVisibleName,
                required String participantCity,
                Value<String?> participantProfilePhotoUrl =
                    const Value.absent(),
                required DateTime lastSyncedAt,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalRequestsCompanion.insert(
                cacheUserId: cacheUserId,
                remoteId: remoteId,
                collectionType: collectionType,
                detailCached: detailCached,
                status: status,
                cancellationCause: cancellationCause,
                acceptedAt: acceptedAt,
                rejectedAt: rejectedAt,
                cancelledAt: cancelledAt,
                createdAt: createdAt,
                serverUpdatedAt: serverUpdatedAt,
                donationRemoteId: donationRemoteId,
                donationTitle: donationTitle,
                donationStatus: donationStatus,
                donationMainImageUrl: donationMainImageUrl,
                participantRemoteId: participantRemoteId,
                participantVisibleName: participantVisibleName,
                participantCity: participantCity,
                participantProfilePhotoUrl: participantProfilePhotoUrl,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalRequestsTable, LocalRequest>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalRequestsTable,
                    LocalRequest
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalRequestsTable,
      LocalRequest,
      $$LocalRequestsTableFilterComposer,
      $$LocalRequestsTableOrderingComposer,
      $$LocalRequestsTableAnnotationComposer,
      $$LocalRequestsTableCreateCompanionBuilder,
      $$LocalRequestsTableUpdateCompanionBuilder,
      (
        LocalRequest,
        BaseReferences<_$AppDatabase, $LocalRequestsTable, LocalRequest>,
      ),
      LocalRequest,
      PrefetchHooks Function()
    >;
typedef $$LocalCollectionMetadataTableCreateCompanionBuilder =
    LocalCollectionMetadataCompanion Function({
      required int cacheUserId,
      required String collectionKey,
      required DateTime lastSyncedAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$LocalCollectionMetadataTableUpdateCompanionBuilder =
    LocalCollectionMetadataCompanion Function({
      Value<int> cacheUserId,
      Value<String> collectionKey,
      Value<DateTime> lastSyncedAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$LocalCollectionMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCollectionMetadataTable> {
  $$LocalCollectionMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectionKey => $composableBuilder(
    column: $table.collectionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCollectionMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCollectionMetadataTable> {
  $$LocalCollectionMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionKey => $composableBuilder(
    column: $table.collectionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCollectionMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCollectionMetadataTable> {
  $$LocalCollectionMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collectionKey => $composableBuilder(
    column: $table.collectionKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$LocalCollectionMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCollectionMetadataTable,
          LocalCollectionMetadataData,
          $$LocalCollectionMetadataTableFilterComposer,
          $$LocalCollectionMetadataTableOrderingComposer,
          $$LocalCollectionMetadataTableAnnotationComposer,
          $$LocalCollectionMetadataTableCreateCompanionBuilder,
          $$LocalCollectionMetadataTableUpdateCompanionBuilder,
          (
            LocalCollectionMetadataData,
            BaseReferences<
              _$AppDatabase,
              $LocalCollectionMetadataTable,
              LocalCollectionMetadataData
            >,
          ),
          LocalCollectionMetadataData,
          PrefetchHooks Function()
        > {
  $$LocalCollectionMetadataTableTableManager(
    _$AppDatabase db,
    $LocalCollectionMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCollectionMetadataTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalCollectionMetadataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCollectionMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> cacheUserId = const Value.absent(),
                Value<String> collectionKey = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCollectionMetadataCompanion(
                cacheUserId: cacheUserId,
                collectionKey: collectionKey,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int cacheUserId,
                required String collectionKey,
                required DateTime lastSyncedAt,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCollectionMetadataCompanion.insert(
                cacheUserId: cacheUserId,
                collectionKey: collectionKey,
                lastSyncedAt: lastSyncedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalCollectionMetadataTable,
                    LocalCollectionMetadataData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalCollectionMetadataTable,
                    LocalCollectionMetadataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCollectionMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCollectionMetadataTable,
      LocalCollectionMetadataData,
      $$LocalCollectionMetadataTableFilterComposer,
      $$LocalCollectionMetadataTableOrderingComposer,
      $$LocalCollectionMetadataTableAnnotationComposer,
      $$LocalCollectionMetadataTableCreateCompanionBuilder,
      $$LocalCollectionMetadataTableUpdateCompanionBuilder,
      (
        LocalCollectionMetadataData,
        BaseReferences<
          _$AppDatabase,
          $LocalCollectionMetadataTable,
          LocalCollectionMetadataData
        >,
      ),
      LocalCollectionMetadataData,
      PrefetchHooks Function()
    >;
typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> localId,
      required String operationId,
      required int cacheUserId,
      required PendingOperationEntityType entityType,
      required String entityClientId,
      required PendingOperationType operationType,
      Value<PendingOperationState> state,
      Value<int> attemptCount,
      required DateTime createdAt,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastErrorCode,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> localId,
      Value<String> operationId,
      Value<int> cacheUserId,
      Value<PendingOperationEntityType> entityType,
      Value<String> entityClientId,
      Value<PendingOperationType> operationType,
      Value<PendingOperationState> state,
      Value<int> attemptCount,
      Value<DateTime> createdAt,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> lastErrorCode,
    });

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PendingOperationEntityType,
    PendingOperationEntityType,
    String
  >
  get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entityClientId => $composableBuilder(
    column: $table.entityClientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PendingOperationType,
    PendingOperationType,
    String
  >
  get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PendingOperationState,
    PendingOperationState,
    String
  >
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityClientId => $composableBuilder(
    column: $table.entityClientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheUserId => $composableBuilder(
    column: $table.cacheUserId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PendingOperationEntityType, String>
  get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityClientId => $composableBuilder(
    column: $table.entityClientId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PendingOperationType, String>
  get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PendingOperationState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (
            PendingOperation,
            BaseReferences<
              _$AppDatabase,
              $PendingOperationsTable,
              PendingOperation
            >,
          ),
          PendingOperation,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<int> cacheUserId = const Value.absent(),
                Value<PendingOperationEntityType> entityType =
                    const Value.absent(),
                Value<String> entityClientId = const Value.absent(),
                Value<PendingOperationType> operationType =
                    const Value.absent(),
                Value<PendingOperationState> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => PendingOperationsCompanion(
                localId: localId,
                operationId: operationId,
                cacheUserId: cacheUserId,
                entityType: entityType,
                entityClientId: entityClientId,
                operationType: operationType,
                state: state,
                attemptCount: attemptCount,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                lastAttemptAt: lastAttemptAt,
                lastErrorCode: lastErrorCode,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required String operationId,
                required int cacheUserId,
                required PendingOperationEntityType entityType,
                required String entityClientId,
                required PendingOperationType operationType,
                Value<PendingOperationState> state = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => PendingOperationsCompanion.insert(
                localId: localId,
                operationId: operationId,
                cacheUserId: cacheUserId,
                entityType: entityType,
                entityClientId: entityClientId,
                operationType: operationType,
                state: state,
                attemptCount: attemptCount,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                lastAttemptAt: lastAttemptAt,
                lastErrorCode: lastErrorCode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingOperationsTable, PendingOperation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingOperationsTable,
                    PendingOperation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTable,
      PendingOperation,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (
        PendingOperation,
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation
        >,
      ),
      PendingOperation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalAuthenticatedUsersTableTableManager get localAuthenticatedUsers =>
      $$LocalAuthenticatedUsersTableTableManager(
        _db,
        _db.localAuthenticatedUsers,
      );
  $$LocalCategoriesTableTableManager get localCategories =>
      $$LocalCategoriesTableTableManager(_db, _db.localCategories);
  $$LocalDonationsTableTableManager get localDonations =>
      $$LocalDonationsTableTableManager(_db, _db.localDonations);
  $$LocalDonationMembershipsTableTableManager get localDonationMemberships =>
      $$LocalDonationMembershipsTableTableManager(
        _db,
        _db.localDonationMemberships,
      );
  $$LocalDonationImagesTableTableManager get localDonationImages =>
      $$LocalDonationImagesTableTableManager(_db, _db.localDonationImages);
  $$LocalRequestsTableTableManager get localRequests =>
      $$LocalRequestsTableTableManager(_db, _db.localRequests);
  $$LocalCollectionMetadataTableTableManager get localCollectionMetadata =>
      $$LocalCollectionMetadataTableTableManager(
        _db,
        _db.localCollectionMetadata,
      );
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
}
