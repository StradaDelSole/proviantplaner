// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _daysCountMeta =
      const VerificationMeta('daysCount');
  @override
  late final GeneratedColumn<int> daysCount = GeneratedColumn<int>(
      'days_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(7));
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
      'region', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mediterranean'));
  static const VerificationMeta _climateMeta =
      const VerificationMeta('climate');
  @override
  late final GeneratedColumn<String> climate = GeneratedColumn<String>(
      'climate', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('warm'));
  static const VerificationMeta _isCharterMeta =
      const VerificationMeta('isCharter');
  @override
  late final GeneratedColumn<bool> isCharter = GeneratedColumn<bool>(
      'is_charter', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_charter" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _boatTypeMeta =
      const VerificationMeta('boatType');
  @override
  late final GeneratedColumn<String> boatType = GeneratedColumn<String>(
      'boat_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mono'));
  static const VerificationMeta _fridgeCapacityMeta =
      const VerificationMeta('fridgeCapacity');
  @override
  late final GeneratedColumn<int> fridgeCapacity = GeneratedColumn<int>(
      'fridge_capacity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _appetiteMeta =
      const VerificationMeta('appetite');
  @override
  late final GeneratedColumnWithTypeConverter<CrewAppetite, String> appetite =
      GeneratedColumn<String>('appetite', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('normal'))
          .withConverter<CrewAppetite>($TripsTable.$converterappetite);
  static const VerificationMeta _reserveDaysMeta =
      const VerificationMeta('reserveDays');
  @override
  late final GeneratedColumn<String> reserveDays = GeneratedColumn<String>(
      'reserve_days', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('few_days'));
  static const VerificationMeta _drinkingHabitMeta =
      const VerificationMeta('drinkingHabit');
  @override
  late final GeneratedColumnWithTypeConverter<CrewDrinking, String>
      drinkingHabit = GeneratedColumn<String>(
              'drinking_habit', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('normal'))
          .withConverter<CrewDrinking>($TripsTable.$converterdrinkingHabit);
  static const VerificationMeta _hasStorageChecklistMeta =
      const VerificationMeta('hasStorageChecklist');
  @override
  late final GeneratedColumn<bool> hasStorageChecklist = GeneratedColumn<bool>(
      'has_storage_checklist', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_storage_checklist" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumnWithTypeConverter<TripPhase, String> phase =
      GeneratedColumn<String>('phase', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('plan'))
          .withConverter<TripPhase>($TripsTable.$converterphase);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('EUR'));
  static const VerificationMeta _kittyModelMeta =
      const VerificationMeta('kittyModel');
  @override
  late final GeneratedColumnWithTypeConverter<KittyModel, String> kittyModel =
      GeneratedColumn<String>('kitty_model', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('shared_kitty'))
          .withConverter<KittyModel>($TripsTable.$converterkittyModel);
  static const VerificationMeta _treasurerMemberIdMeta =
      const VerificationMeta('treasurerMemberId');
  @override
  late final GeneratedColumn<int> treasurerMemberId = GeneratedColumn<int>(
      'treasurer_member_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        startDate,
        daysCount,
        region,
        climate,
        isCharter,
        boatType,
        fridgeCapacity,
        appetite,
        reserveDays,
        drinkingHabit,
        hasStorageChecklist,
        phase,
        isArchived,
        currency,
        kittyModel,
        treasurerMemberId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(Insertable<Trip> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('days_count')) {
      context.handle(_daysCountMeta,
          daysCount.isAcceptableOrUnknown(data['days_count']!, _daysCountMeta));
    }
    if (data.containsKey('region')) {
      context.handle(_regionMeta,
          region.isAcceptableOrUnknown(data['region']!, _regionMeta));
    }
    if (data.containsKey('climate')) {
      context.handle(_climateMeta,
          climate.isAcceptableOrUnknown(data['climate']!, _climateMeta));
    }
    if (data.containsKey('is_charter')) {
      context.handle(_isCharterMeta,
          isCharter.isAcceptableOrUnknown(data['is_charter']!, _isCharterMeta));
    }
    if (data.containsKey('boat_type')) {
      context.handle(_boatTypeMeta,
          boatType.isAcceptableOrUnknown(data['boat_type']!, _boatTypeMeta));
    }
    if (data.containsKey('fridge_capacity')) {
      context.handle(
          _fridgeCapacityMeta,
          fridgeCapacity.isAcceptableOrUnknown(
              data['fridge_capacity']!, _fridgeCapacityMeta));
    }
    context.handle(_appetiteMeta, const VerificationResult.success());
    if (data.containsKey('reserve_days')) {
      context.handle(
          _reserveDaysMeta,
          reserveDays.isAcceptableOrUnknown(
              data['reserve_days']!, _reserveDaysMeta));
    }
    context.handle(_drinkingHabitMeta, const VerificationResult.success());
    if (data.containsKey('has_storage_checklist')) {
      context.handle(
          _hasStorageChecklistMeta,
          hasStorageChecklist.isAcceptableOrUnknown(
              data['has_storage_checklist']!, _hasStorageChecklistMeta));
    }
    context.handle(_phaseMeta, const VerificationResult.success());
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    context.handle(_kittyModelMeta, const VerificationResult.success());
    if (data.containsKey('treasurer_member_id')) {
      context.handle(
          _treasurerMemberIdMeta,
          treasurerMemberId.isAcceptableOrUnknown(
              data['treasurer_member_id']!, _treasurerMemberIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      daysCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}days_count'])!,
      region: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region'])!,
      climate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}climate'])!,
      isCharter: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_charter'])!,
      boatType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}boat_type'])!,
      fridgeCapacity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fridge_capacity'])!,
      appetite: $TripsTable.$converterappetite.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}appetite'])!),
      reserveDays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reserve_days'])!,
      drinkingHabit: $TripsTable.$converterdrinkingHabit.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}drinking_habit'])!),
      hasStorageChecklist: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}has_storage_checklist'])!,
      phase: $TripsTable.$converterphase.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phase'])!),
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      kittyModel: $TripsTable.$converterkittyModel.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kitty_model'])!),
      treasurerMemberId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}treasurer_member_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }

  static TypeConverter<CrewAppetite, String> $converterappetite =
      const CrewAppetiteConverter();
  static TypeConverter<CrewDrinking, String> $converterdrinkingHabit =
      const CrewDrinkingConverter();
  static TypeConverter<TripPhase, String> $converterphase =
      const TripPhaseConverter();
  static TypeConverter<KittyModel, String> $converterkittyModel =
      const KittyModelConverter();
}

class Trip extends DataClass implements Insertable<Trip> {
  final int id;
  final String name;
  final DateTime startDate;
  final int daysCount;
  final String region;
  final String climate;
  final bool isCharter;
  final String boatType;
  final int fridgeCapacity;
  final CrewAppetite appetite;
  final String reserveDays;
  final CrewDrinking drinkingHabit;
  final bool hasStorageChecklist;
  final TripPhase phase;
  final bool isArchived;
  final String currency;
  final KittyModel kittyModel;
  final int? treasurerMemberId;
  final DateTime createdAt;
  const Trip(
      {required this.id,
      required this.name,
      required this.startDate,
      required this.daysCount,
      required this.region,
      required this.climate,
      required this.isCharter,
      required this.boatType,
      required this.fridgeCapacity,
      required this.appetite,
      required this.reserveDays,
      required this.drinkingHabit,
      required this.hasStorageChecklist,
      required this.phase,
      required this.isArchived,
      required this.currency,
      required this.kittyModel,
      this.treasurerMemberId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<DateTime>(startDate);
    map['days_count'] = Variable<int>(daysCount);
    map['region'] = Variable<String>(region);
    map['climate'] = Variable<String>(climate);
    map['is_charter'] = Variable<bool>(isCharter);
    map['boat_type'] = Variable<String>(boatType);
    map['fridge_capacity'] = Variable<int>(fridgeCapacity);
    {
      map['appetite'] =
          Variable<String>($TripsTable.$converterappetite.toSql(appetite));
    }
    map['reserve_days'] = Variable<String>(reserveDays);
    {
      map['drinking_habit'] = Variable<String>(
          $TripsTable.$converterdrinkingHabit.toSql(drinkingHabit));
    }
    map['has_storage_checklist'] = Variable<bool>(hasStorageChecklist);
    {
      map['phase'] = Variable<String>($TripsTable.$converterphase.toSql(phase));
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['currency'] = Variable<String>(currency);
    {
      map['kitty_model'] =
          Variable<String>($TripsTable.$converterkittyModel.toSql(kittyModel));
    }
    if (!nullToAbsent || treasurerMemberId != null) {
      map['treasurer_member_id'] = Variable<int>(treasurerMemberId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      daysCount: Value(daysCount),
      region: Value(region),
      climate: Value(climate),
      isCharter: Value(isCharter),
      boatType: Value(boatType),
      fridgeCapacity: Value(fridgeCapacity),
      appetite: Value(appetite),
      reserveDays: Value(reserveDays),
      drinkingHabit: Value(drinkingHabit),
      hasStorageChecklist: Value(hasStorageChecklist),
      phase: Value(phase),
      isArchived: Value(isArchived),
      currency: Value(currency),
      kittyModel: Value(kittyModel),
      treasurerMemberId: treasurerMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(treasurerMemberId),
      createdAt: Value(createdAt),
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      daysCount: serializer.fromJson<int>(json['daysCount']),
      region: serializer.fromJson<String>(json['region']),
      climate: serializer.fromJson<String>(json['climate']),
      isCharter: serializer.fromJson<bool>(json['isCharter']),
      boatType: serializer.fromJson<String>(json['boatType']),
      fridgeCapacity: serializer.fromJson<int>(json['fridgeCapacity']),
      appetite: serializer.fromJson<CrewAppetite>(json['appetite']),
      reserveDays: serializer.fromJson<String>(json['reserveDays']),
      drinkingHabit: serializer.fromJson<CrewDrinking>(json['drinkingHabit']),
      hasStorageChecklist:
          serializer.fromJson<bool>(json['hasStorageChecklist']),
      phase: serializer.fromJson<TripPhase>(json['phase']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      currency: serializer.fromJson<String>(json['currency']),
      kittyModel: serializer.fromJson<KittyModel>(json['kittyModel']),
      treasurerMemberId: serializer.fromJson<int?>(json['treasurerMemberId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<DateTime>(startDate),
      'daysCount': serializer.toJson<int>(daysCount),
      'region': serializer.toJson<String>(region),
      'climate': serializer.toJson<String>(climate),
      'isCharter': serializer.toJson<bool>(isCharter),
      'boatType': serializer.toJson<String>(boatType),
      'fridgeCapacity': serializer.toJson<int>(fridgeCapacity),
      'appetite': serializer.toJson<CrewAppetite>(appetite),
      'reserveDays': serializer.toJson<String>(reserveDays),
      'drinkingHabit': serializer.toJson<CrewDrinking>(drinkingHabit),
      'hasStorageChecklist': serializer.toJson<bool>(hasStorageChecklist),
      'phase': serializer.toJson<TripPhase>(phase),
      'isArchived': serializer.toJson<bool>(isArchived),
      'currency': serializer.toJson<String>(currency),
      'kittyModel': serializer.toJson<KittyModel>(kittyModel),
      'treasurerMemberId': serializer.toJson<int?>(treasurerMemberId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Trip copyWith(
          {int? id,
          String? name,
          DateTime? startDate,
          int? daysCount,
          String? region,
          String? climate,
          bool? isCharter,
          String? boatType,
          int? fridgeCapacity,
          CrewAppetite? appetite,
          String? reserveDays,
          CrewDrinking? drinkingHabit,
          bool? hasStorageChecklist,
          TripPhase? phase,
          bool? isArchived,
          String? currency,
          KittyModel? kittyModel,
          Value<int?> treasurerMemberId = const Value.absent(),
          DateTime? createdAt}) =>
      Trip(
        id: id ?? this.id,
        name: name ?? this.name,
        startDate: startDate ?? this.startDate,
        daysCount: daysCount ?? this.daysCount,
        region: region ?? this.region,
        climate: climate ?? this.climate,
        isCharter: isCharter ?? this.isCharter,
        boatType: boatType ?? this.boatType,
        fridgeCapacity: fridgeCapacity ?? this.fridgeCapacity,
        appetite: appetite ?? this.appetite,
        reserveDays: reserveDays ?? this.reserveDays,
        drinkingHabit: drinkingHabit ?? this.drinkingHabit,
        hasStorageChecklist: hasStorageChecklist ?? this.hasStorageChecklist,
        phase: phase ?? this.phase,
        isArchived: isArchived ?? this.isArchived,
        currency: currency ?? this.currency,
        kittyModel: kittyModel ?? this.kittyModel,
        treasurerMemberId: treasurerMemberId.present
            ? treasurerMemberId.value
            : this.treasurerMemberId,
        createdAt: createdAt ?? this.createdAt,
      );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      daysCount: data.daysCount.present ? data.daysCount.value : this.daysCount,
      region: data.region.present ? data.region.value : this.region,
      climate: data.climate.present ? data.climate.value : this.climate,
      isCharter: data.isCharter.present ? data.isCharter.value : this.isCharter,
      boatType: data.boatType.present ? data.boatType.value : this.boatType,
      fridgeCapacity: data.fridgeCapacity.present
          ? data.fridgeCapacity.value
          : this.fridgeCapacity,
      appetite: data.appetite.present ? data.appetite.value : this.appetite,
      reserveDays:
          data.reserveDays.present ? data.reserveDays.value : this.reserveDays,
      drinkingHabit: data.drinkingHabit.present
          ? data.drinkingHabit.value
          : this.drinkingHabit,
      hasStorageChecklist: data.hasStorageChecklist.present
          ? data.hasStorageChecklist.value
          : this.hasStorageChecklist,
      phase: data.phase.present ? data.phase.value : this.phase,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      currency: data.currency.present ? data.currency.value : this.currency,
      kittyModel:
          data.kittyModel.present ? data.kittyModel.value : this.kittyModel,
      treasurerMemberId: data.treasurerMemberId.present
          ? data.treasurerMemberId.value
          : this.treasurerMemberId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('daysCount: $daysCount, ')
          ..write('region: $region, ')
          ..write('climate: $climate, ')
          ..write('isCharter: $isCharter, ')
          ..write('boatType: $boatType, ')
          ..write('fridgeCapacity: $fridgeCapacity, ')
          ..write('appetite: $appetite, ')
          ..write('reserveDays: $reserveDays, ')
          ..write('drinkingHabit: $drinkingHabit, ')
          ..write('hasStorageChecklist: $hasStorageChecklist, ')
          ..write('phase: $phase, ')
          ..write('isArchived: $isArchived, ')
          ..write('currency: $currency, ')
          ..write('kittyModel: $kittyModel, ')
          ..write('treasurerMemberId: $treasurerMemberId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      startDate,
      daysCount,
      region,
      climate,
      isCharter,
      boatType,
      fridgeCapacity,
      appetite,
      reserveDays,
      drinkingHabit,
      hasStorageChecklist,
      phase,
      isArchived,
      currency,
      kittyModel,
      treasurerMemberId,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.daysCount == this.daysCount &&
          other.region == this.region &&
          other.climate == this.climate &&
          other.isCharter == this.isCharter &&
          other.boatType == this.boatType &&
          other.fridgeCapacity == this.fridgeCapacity &&
          other.appetite == this.appetite &&
          other.reserveDays == this.reserveDays &&
          other.drinkingHabit == this.drinkingHabit &&
          other.hasStorageChecklist == this.hasStorageChecklist &&
          other.phase == this.phase &&
          other.isArchived == this.isArchived &&
          other.currency == this.currency &&
          other.kittyModel == this.kittyModel &&
          other.treasurerMemberId == this.treasurerMemberId &&
          other.createdAt == this.createdAt);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> startDate;
  final Value<int> daysCount;
  final Value<String> region;
  final Value<String> climate;
  final Value<bool> isCharter;
  final Value<String> boatType;
  final Value<int> fridgeCapacity;
  final Value<CrewAppetite> appetite;
  final Value<String> reserveDays;
  final Value<CrewDrinking> drinkingHabit;
  final Value<bool> hasStorageChecklist;
  final Value<TripPhase> phase;
  final Value<bool> isArchived;
  final Value<String> currency;
  final Value<KittyModel> kittyModel;
  final Value<int?> treasurerMemberId;
  final Value<DateTime> createdAt;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.daysCount = const Value.absent(),
    this.region = const Value.absent(),
    this.climate = const Value.absent(),
    this.isCharter = const Value.absent(),
    this.boatType = const Value.absent(),
    this.fridgeCapacity = const Value.absent(),
    this.appetite = const Value.absent(),
    this.reserveDays = const Value.absent(),
    this.drinkingHabit = const Value.absent(),
    this.hasStorageChecklist = const Value.absent(),
    this.phase = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.currency = const Value.absent(),
    this.kittyModel = const Value.absent(),
    this.treasurerMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime startDate,
    this.daysCount = const Value.absent(),
    this.region = const Value.absent(),
    this.climate = const Value.absent(),
    this.isCharter = const Value.absent(),
    this.boatType = const Value.absent(),
    this.fridgeCapacity = const Value.absent(),
    this.appetite = const Value.absent(),
    this.reserveDays = const Value.absent(),
    this.drinkingHabit = const Value.absent(),
    this.hasStorageChecklist = const Value.absent(),
    this.phase = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.currency = const Value.absent(),
    this.kittyModel = const Value.absent(),
    this.treasurerMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        startDate = Value(startDate);
  static Insertable<Trip> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? startDate,
    Expression<int>? daysCount,
    Expression<String>? region,
    Expression<String>? climate,
    Expression<bool>? isCharter,
    Expression<String>? boatType,
    Expression<int>? fridgeCapacity,
    Expression<String>? appetite,
    Expression<String>? reserveDays,
    Expression<String>? drinkingHabit,
    Expression<bool>? hasStorageChecklist,
    Expression<String>? phase,
    Expression<bool>? isArchived,
    Expression<String>? currency,
    Expression<String>? kittyModel,
    Expression<int>? treasurerMemberId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (daysCount != null) 'days_count': daysCount,
      if (region != null) 'region': region,
      if (climate != null) 'climate': climate,
      if (isCharter != null) 'is_charter': isCharter,
      if (boatType != null) 'boat_type': boatType,
      if (fridgeCapacity != null) 'fridge_capacity': fridgeCapacity,
      if (appetite != null) 'appetite': appetite,
      if (reserveDays != null) 'reserve_days': reserveDays,
      if (drinkingHabit != null) 'drinking_habit': drinkingHabit,
      if (hasStorageChecklist != null)
        'has_storage_checklist': hasStorageChecklist,
      if (phase != null) 'phase': phase,
      if (isArchived != null) 'is_archived': isArchived,
      if (currency != null) 'currency': currency,
      if (kittyModel != null) 'kitty_model': kittyModel,
      if (treasurerMemberId != null) 'treasurer_member_id': treasurerMemberId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TripsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<DateTime>? startDate,
      Value<int>? daysCount,
      Value<String>? region,
      Value<String>? climate,
      Value<bool>? isCharter,
      Value<String>? boatType,
      Value<int>? fridgeCapacity,
      Value<CrewAppetite>? appetite,
      Value<String>? reserveDays,
      Value<CrewDrinking>? drinkingHabit,
      Value<bool>? hasStorageChecklist,
      Value<TripPhase>? phase,
      Value<bool>? isArchived,
      Value<String>? currency,
      Value<KittyModel>? kittyModel,
      Value<int?>? treasurerMemberId,
      Value<DateTime>? createdAt}) {
    return TripsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      daysCount: daysCount ?? this.daysCount,
      region: region ?? this.region,
      climate: climate ?? this.climate,
      isCharter: isCharter ?? this.isCharter,
      boatType: boatType ?? this.boatType,
      fridgeCapacity: fridgeCapacity ?? this.fridgeCapacity,
      appetite: appetite ?? this.appetite,
      reserveDays: reserveDays ?? this.reserveDays,
      drinkingHabit: drinkingHabit ?? this.drinkingHabit,
      hasStorageChecklist: hasStorageChecklist ?? this.hasStorageChecklist,
      phase: phase ?? this.phase,
      isArchived: isArchived ?? this.isArchived,
      currency: currency ?? this.currency,
      kittyModel: kittyModel ?? this.kittyModel,
      treasurerMemberId: treasurerMemberId ?? this.treasurerMemberId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (daysCount.present) {
      map['days_count'] = Variable<int>(daysCount.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (climate.present) {
      map['climate'] = Variable<String>(climate.value);
    }
    if (isCharter.present) {
      map['is_charter'] = Variable<bool>(isCharter.value);
    }
    if (boatType.present) {
      map['boat_type'] = Variable<String>(boatType.value);
    }
    if (fridgeCapacity.present) {
      map['fridge_capacity'] = Variable<int>(fridgeCapacity.value);
    }
    if (appetite.present) {
      map['appetite'] = Variable<String>(
          $TripsTable.$converterappetite.toSql(appetite.value));
    }
    if (reserveDays.present) {
      map['reserve_days'] = Variable<String>(reserveDays.value);
    }
    if (drinkingHabit.present) {
      map['drinking_habit'] = Variable<String>(
          $TripsTable.$converterdrinkingHabit.toSql(drinkingHabit.value));
    }
    if (hasStorageChecklist.present) {
      map['has_storage_checklist'] = Variable<bool>(hasStorageChecklist.value);
    }
    if (phase.present) {
      map['phase'] =
          Variable<String>($TripsTable.$converterphase.toSql(phase.value));
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (kittyModel.present) {
      map['kitty_model'] = Variable<String>(
          $TripsTable.$converterkittyModel.toSql(kittyModel.value));
    }
    if (treasurerMemberId.present) {
      map['treasurer_member_id'] = Variable<int>(treasurerMemberId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('daysCount: $daysCount, ')
          ..write('region: $region, ')
          ..write('climate: $climate, ')
          ..write('isCharter: $isCharter, ')
          ..write('boatType: $boatType, ')
          ..write('fridgeCapacity: $fridgeCapacity, ')
          ..write('appetite: $appetite, ')
          ..write('reserveDays: $reserveDays, ')
          ..write('drinkingHabit: $drinkingHabit, ')
          ..write('hasStorageChecklist: $hasStorageChecklist, ')
          ..write('phase: $phase, ')
          ..write('isArchived: $isArchived, ')
          ..write('currency: $currency, ')
          ..write('kittyModel: $kittyModel, ')
          ..write('treasurerMemberId: $treasurerMemberId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TripDaysTable extends TripDays with TableInfo<$TripDaysTable, TripDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES trips (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayNumberMeta =
      const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
      'day_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lunchRestaurantMeta =
      const VerificationMeta('lunchRestaurant');
  @override
  late final GeneratedColumn<bool> lunchRestaurant = GeneratedColumn<bool>(
      'lunch_restaurant', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("lunch_restaurant" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dinnerRestaurantMeta =
      const VerificationMeta('dinnerRestaurant');
  @override
  late final GeneratedColumn<bool> dinnerRestaurant = GeneratedColumn<bool>(
      'dinner_restaurant', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("dinner_restaurant" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dayTypeMeta =
      const VerificationMeta('dayType');
  @override
  late final GeneratedColumn<String> dayType = GeneratedColumn<String>(
      'day_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _portNameMeta =
      const VerificationMeta('portName');
  @override
  late final GeneratedColumn<String> portName = GeneratedColumn<String>(
      'port_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tripId,
        dayNumber,
        lunchRestaurant,
        dinnerRestaurant,
        dayType,
        portName
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_days';
  @override
  VerificationContext validateIntegrity(Insertable<TripDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta,
          dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('lunch_restaurant')) {
      context.handle(
          _lunchRestaurantMeta,
          lunchRestaurant.isAcceptableOrUnknown(
              data['lunch_restaurant']!, _lunchRestaurantMeta));
    }
    if (data.containsKey('dinner_restaurant')) {
      context.handle(
          _dinnerRestaurantMeta,
          dinnerRestaurant.isAcceptableOrUnknown(
              data['dinner_restaurant']!, _dinnerRestaurantMeta));
    }
    if (data.containsKey('day_type')) {
      context.handle(_dayTypeMeta,
          dayType.isAcceptableOrUnknown(data['day_type']!, _dayTypeMeta));
    }
    if (data.containsKey('port_name')) {
      context.handle(_portNameMeta,
          portName.isAcceptableOrUnknown(data['port_name']!, _portNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripDay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id'])!,
      dayNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      lunchRestaurant: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}lunch_restaurant'])!,
      dinnerRestaurant: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}dinner_restaurant'])!,
      dayType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_type']),
      portName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}port_name']),
    );
  }

  @override
  $TripDaysTable createAlias(String alias) {
    return $TripDaysTable(attachedDatabase, alias);
  }
}

class TripDay extends DataClass implements Insertable<TripDay> {
  final int id;
  final int tripId;
  final int dayNumber;
  final bool lunchRestaurant;
  final bool dinnerRestaurant;
  final String? dayType;
  final String? portName;
  const TripDay(
      {required this.id,
      required this.tripId,
      required this.dayNumber,
      required this.lunchRestaurant,
      required this.dinnerRestaurant,
      this.dayType,
      this.portName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['day_number'] = Variable<int>(dayNumber);
    map['lunch_restaurant'] = Variable<bool>(lunchRestaurant);
    map['dinner_restaurant'] = Variable<bool>(dinnerRestaurant);
    if (!nullToAbsent || dayType != null) {
      map['day_type'] = Variable<String>(dayType);
    }
    if (!nullToAbsent || portName != null) {
      map['port_name'] = Variable<String>(portName);
    }
    return map;
  }

  TripDaysCompanion toCompanion(bool nullToAbsent) {
    return TripDaysCompanion(
      id: Value(id),
      tripId: Value(tripId),
      dayNumber: Value(dayNumber),
      lunchRestaurant: Value(lunchRestaurant),
      dinnerRestaurant: Value(dinnerRestaurant),
      dayType: dayType == null && nullToAbsent
          ? const Value.absent()
          : Value(dayType),
      portName: portName == null && nullToAbsent
          ? const Value.absent()
          : Value(portName),
    );
  }

  factory TripDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripDay(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      lunchRestaurant: serializer.fromJson<bool>(json['lunchRestaurant']),
      dinnerRestaurant: serializer.fromJson<bool>(json['dinnerRestaurant']),
      dayType: serializer.fromJson<String?>(json['dayType']),
      portName: serializer.fromJson<String?>(json['portName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'lunchRestaurant': serializer.toJson<bool>(lunchRestaurant),
      'dinnerRestaurant': serializer.toJson<bool>(dinnerRestaurant),
      'dayType': serializer.toJson<String?>(dayType),
      'portName': serializer.toJson<String?>(portName),
    };
  }

  TripDay copyWith(
          {int? id,
          int? tripId,
          int? dayNumber,
          bool? lunchRestaurant,
          bool? dinnerRestaurant,
          Value<String?> dayType = const Value.absent(),
          Value<String?> portName = const Value.absent()}) =>
      TripDay(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        dayNumber: dayNumber ?? this.dayNumber,
        lunchRestaurant: lunchRestaurant ?? this.lunchRestaurant,
        dinnerRestaurant: dinnerRestaurant ?? this.dinnerRestaurant,
        dayType: dayType.present ? dayType.value : this.dayType,
        portName: portName.present ? portName.value : this.portName,
      );
  TripDay copyWithCompanion(TripDaysCompanion data) {
    return TripDay(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      lunchRestaurant: data.lunchRestaurant.present
          ? data.lunchRestaurant.value
          : this.lunchRestaurant,
      dinnerRestaurant: data.dinnerRestaurant.present
          ? data.dinnerRestaurant.value
          : this.dinnerRestaurant,
      dayType: data.dayType.present ? data.dayType.value : this.dayType,
      portName: data.portName.present ? data.portName.value : this.portName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripDay(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('lunchRestaurant: $lunchRestaurant, ')
          ..write('dinnerRestaurant: $dinnerRestaurant, ')
          ..write('dayType: $dayType, ')
          ..write('portName: $portName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tripId, dayNumber, lunchRestaurant,
      dinnerRestaurant, dayType, portName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripDay &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.dayNumber == this.dayNumber &&
          other.lunchRestaurant == this.lunchRestaurant &&
          other.dinnerRestaurant == this.dinnerRestaurant &&
          other.dayType == this.dayType &&
          other.portName == this.portName);
}

class TripDaysCompanion extends UpdateCompanion<TripDay> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<int> dayNumber;
  final Value<bool> lunchRestaurant;
  final Value<bool> dinnerRestaurant;
  final Value<String?> dayType;
  final Value<String?> portName;
  const TripDaysCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.lunchRestaurant = const Value.absent(),
    this.dinnerRestaurant = const Value.absent(),
    this.dayType = const Value.absent(),
    this.portName = const Value.absent(),
  });
  TripDaysCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required int dayNumber,
    this.lunchRestaurant = const Value.absent(),
    this.dinnerRestaurant = const Value.absent(),
    this.dayType = const Value.absent(),
    this.portName = const Value.absent(),
  })  : tripId = Value(tripId),
        dayNumber = Value(dayNumber);
  static Insertable<TripDay> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<int>? dayNumber,
    Expression<bool>? lunchRestaurant,
    Expression<bool>? dinnerRestaurant,
    Expression<String>? dayType,
    Expression<String>? portName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (lunchRestaurant != null) 'lunch_restaurant': lunchRestaurant,
      if (dinnerRestaurant != null) 'dinner_restaurant': dinnerRestaurant,
      if (dayType != null) 'day_type': dayType,
      if (portName != null) 'port_name': portName,
    });
  }

  TripDaysCompanion copyWith(
      {Value<int>? id,
      Value<int>? tripId,
      Value<int>? dayNumber,
      Value<bool>? lunchRestaurant,
      Value<bool>? dinnerRestaurant,
      Value<String?>? dayType,
      Value<String?>? portName}) {
    return TripDaysCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      lunchRestaurant: lunchRestaurant ?? this.lunchRestaurant,
      dinnerRestaurant: dinnerRestaurant ?? this.dinnerRestaurant,
      dayType: dayType ?? this.dayType,
      portName: portName ?? this.portName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (lunchRestaurant.present) {
      map['lunch_restaurant'] = Variable<bool>(lunchRestaurant.value);
    }
    if (dinnerRestaurant.present) {
      map['dinner_restaurant'] = Variable<bool>(dinnerRestaurant.value);
    }
    if (dayType.present) {
      map['day_type'] = Variable<String>(dayType.value);
    }
    if (portName.present) {
      map['port_name'] = Variable<String>(portName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripDaysCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('lunchRestaurant: $lunchRestaurant, ')
          ..write('dinnerRestaurant: $dinnerRestaurant, ')
          ..write('dayType: $dayType, ')
          ..write('portName: $portName')
          ..write(')'))
        .toString();
  }
}

class $CrewMembersTable extends CrewMembers
    with TableInfo<$CrewMembersTable, CrewMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CrewMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES trips (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isChildMeta =
      const VerificationMeta('isChild');
  @override
  late final GeneratedColumn<bool> isChild = GeneratedColumn<bool>(
      'is_child', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_child" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isVegetarianMeta =
      const VerificationMeta('isVegetarian');
  @override
  late final GeneratedColumn<bool> isVegetarian = GeneratedColumn<bool>(
      'is_vegetarian', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_vegetarian" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isNonDrinkerMeta =
      const VerificationMeta('isNonDrinker');
  @override
  late final GeneratedColumn<bool> isNonDrinker = GeneratedColumn<bool>(
      'is_non_drinker', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_non_drinker" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customEatLevelMeta =
      const VerificationMeta('customEatLevel');
  @override
  late final GeneratedColumn<String> customEatLevel = GeneratedColumn<String>(
      'custom_eat_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customDrinkLevelMeta =
      const VerificationMeta('customDrinkLevel');
  @override
  late final GeneratedColumn<String> customDrinkLevel = GeneratedColumn<String>(
      'custom_drink_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryParticipationMeta =
      const VerificationMeta('categoryParticipation');
  @override
  late final GeneratedColumn<String> categoryParticipation =
      GeneratedColumn<String>('category_participation', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{"all": true}'));
  static const VerificationMeta _isSkipperFreeMeta =
      const VerificationMeta('isSkipperFree');
  @override
  late final GeneratedColumn<bool> isSkipperFree = GeneratedColumn<bool>(
      'is_skipper_free', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_skipper_free" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _skipperFreeScopeMeta =
      const VerificationMeta('skipperFreeScope');
  @override
  late final GeneratedColumn<String> skipperFreeScope = GeneratedColumn<String>(
      'skipper_free_scope', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ibanMeta = const VerificationMeta('iban');
  @override
  late final GeneratedColumn<String> iban = GeneratedColumn<String>(
      'iban', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paypalLinkMeta =
      const VerificationMeta('paypalLink');
  @override
  late final GeneratedColumn<String> paypalLink = GeneratedColumn<String>(
      'paypal_link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _revolutLinkMeta =
      const VerificationMeta('revolutLink');
  @override
  late final GeneratedColumn<String> revolutLink = GeneratedColumn<String>(
      'revolut_link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tripId,
        name,
        isChild,
        isVegetarian,
        isNonDrinker,
        customEatLevel,
        customDrinkLevel,
        categoryParticipation,
        isSkipperFree,
        skipperFreeScope,
        iban,
        paypalLink,
        revolutLink
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crew_members';
  @override
  VerificationContext validateIntegrity(Insertable<CrewMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_child')) {
      context.handle(_isChildMeta,
          isChild.isAcceptableOrUnknown(data['is_child']!, _isChildMeta));
    }
    if (data.containsKey('is_vegetarian')) {
      context.handle(
          _isVegetarianMeta,
          isVegetarian.isAcceptableOrUnknown(
              data['is_vegetarian']!, _isVegetarianMeta));
    }
    if (data.containsKey('is_non_drinker')) {
      context.handle(
          _isNonDrinkerMeta,
          isNonDrinker.isAcceptableOrUnknown(
              data['is_non_drinker']!, _isNonDrinkerMeta));
    }
    if (data.containsKey('custom_eat_level')) {
      context.handle(
          _customEatLevelMeta,
          customEatLevel.isAcceptableOrUnknown(
              data['custom_eat_level']!, _customEatLevelMeta));
    }
    if (data.containsKey('custom_drink_level')) {
      context.handle(
          _customDrinkLevelMeta,
          customDrinkLevel.isAcceptableOrUnknown(
              data['custom_drink_level']!, _customDrinkLevelMeta));
    }
    if (data.containsKey('category_participation')) {
      context.handle(
          _categoryParticipationMeta,
          categoryParticipation.isAcceptableOrUnknown(
              data['category_participation']!, _categoryParticipationMeta));
    }
    if (data.containsKey('is_skipper_free')) {
      context.handle(
          _isSkipperFreeMeta,
          isSkipperFree.isAcceptableOrUnknown(
              data['is_skipper_free']!, _isSkipperFreeMeta));
    }
    if (data.containsKey('skipper_free_scope')) {
      context.handle(
          _skipperFreeScopeMeta,
          skipperFreeScope.isAcceptableOrUnknown(
              data['skipper_free_scope']!, _skipperFreeScopeMeta));
    }
    if (data.containsKey('iban')) {
      context.handle(
          _ibanMeta, iban.isAcceptableOrUnknown(data['iban']!, _ibanMeta));
    }
    if (data.containsKey('paypal_link')) {
      context.handle(
          _paypalLinkMeta,
          paypalLink.isAcceptableOrUnknown(
              data['paypal_link']!, _paypalLinkMeta));
    }
    if (data.containsKey('revolut_link')) {
      context.handle(
          _revolutLinkMeta,
          revolutLink.isAcceptableOrUnknown(
              data['revolut_link']!, _revolutLinkMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CrewMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CrewMember(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isChild: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_child'])!,
      isVegetarian: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_vegetarian'])!,
      isNonDrinker: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_non_drinker'])!,
      customEatLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_eat_level']),
      customDrinkLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_drink_level']),
      categoryParticipation: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category_participation'])!,
      isSkipperFree: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_skipper_free'])!,
      skipperFreeScope: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}skipper_free_scope']),
      iban: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}iban']),
      paypalLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paypal_link']),
      revolutLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}revolut_link']),
    );
  }

  @override
  $CrewMembersTable createAlias(String alias) {
    return $CrewMembersTable(attachedDatabase, alias);
  }
}

class CrewMember extends DataClass implements Insertable<CrewMember> {
  final int id;
  final int tripId;
  final String name;
  final bool isChild;
  final bool isVegetarian;
  final bool isNonDrinker;
  final String? customEatLevel;
  final String? customDrinkLevel;
  final String categoryParticipation;
  final bool isSkipperFree;
  final String? skipperFreeScope;
  final String? iban;
  final String? paypalLink;
  final String? revolutLink;
  const CrewMember(
      {required this.id,
      required this.tripId,
      required this.name,
      required this.isChild,
      required this.isVegetarian,
      required this.isNonDrinker,
      this.customEatLevel,
      this.customDrinkLevel,
      required this.categoryParticipation,
      required this.isSkipperFree,
      this.skipperFreeScope,
      this.iban,
      this.paypalLink,
      this.revolutLink});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['name'] = Variable<String>(name);
    map['is_child'] = Variable<bool>(isChild);
    map['is_vegetarian'] = Variable<bool>(isVegetarian);
    map['is_non_drinker'] = Variable<bool>(isNonDrinker);
    if (!nullToAbsent || customEatLevel != null) {
      map['custom_eat_level'] = Variable<String>(customEatLevel);
    }
    if (!nullToAbsent || customDrinkLevel != null) {
      map['custom_drink_level'] = Variable<String>(customDrinkLevel);
    }
    map['category_participation'] = Variable<String>(categoryParticipation);
    map['is_skipper_free'] = Variable<bool>(isSkipperFree);
    if (!nullToAbsent || skipperFreeScope != null) {
      map['skipper_free_scope'] = Variable<String>(skipperFreeScope);
    }
    if (!nullToAbsent || iban != null) {
      map['iban'] = Variable<String>(iban);
    }
    if (!nullToAbsent || paypalLink != null) {
      map['paypal_link'] = Variable<String>(paypalLink);
    }
    if (!nullToAbsent || revolutLink != null) {
      map['revolut_link'] = Variable<String>(revolutLink);
    }
    return map;
  }

  CrewMembersCompanion toCompanion(bool nullToAbsent) {
    return CrewMembersCompanion(
      id: Value(id),
      tripId: Value(tripId),
      name: Value(name),
      isChild: Value(isChild),
      isVegetarian: Value(isVegetarian),
      isNonDrinker: Value(isNonDrinker),
      customEatLevel: customEatLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(customEatLevel),
      customDrinkLevel: customDrinkLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(customDrinkLevel),
      categoryParticipation: Value(categoryParticipation),
      isSkipperFree: Value(isSkipperFree),
      skipperFreeScope: skipperFreeScope == null && nullToAbsent
          ? const Value.absent()
          : Value(skipperFreeScope),
      iban: iban == null && nullToAbsent ? const Value.absent() : Value(iban),
      paypalLink: paypalLink == null && nullToAbsent
          ? const Value.absent()
          : Value(paypalLink),
      revolutLink: revolutLink == null && nullToAbsent
          ? const Value.absent()
          : Value(revolutLink),
    );
  }

  factory CrewMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CrewMember(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      name: serializer.fromJson<String>(json['name']),
      isChild: serializer.fromJson<bool>(json['isChild']),
      isVegetarian: serializer.fromJson<bool>(json['isVegetarian']),
      isNonDrinker: serializer.fromJson<bool>(json['isNonDrinker']),
      customEatLevel: serializer.fromJson<String?>(json['customEatLevel']),
      customDrinkLevel: serializer.fromJson<String?>(json['customDrinkLevel']),
      categoryParticipation:
          serializer.fromJson<String>(json['categoryParticipation']),
      isSkipperFree: serializer.fromJson<bool>(json['isSkipperFree']),
      skipperFreeScope: serializer.fromJson<String?>(json['skipperFreeScope']),
      iban: serializer.fromJson<String?>(json['iban']),
      paypalLink: serializer.fromJson<String?>(json['paypalLink']),
      revolutLink: serializer.fromJson<String?>(json['revolutLink']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'name': serializer.toJson<String>(name),
      'isChild': serializer.toJson<bool>(isChild),
      'isVegetarian': serializer.toJson<bool>(isVegetarian),
      'isNonDrinker': serializer.toJson<bool>(isNonDrinker),
      'customEatLevel': serializer.toJson<String?>(customEatLevel),
      'customDrinkLevel': serializer.toJson<String?>(customDrinkLevel),
      'categoryParticipation': serializer.toJson<String>(categoryParticipation),
      'isSkipperFree': serializer.toJson<bool>(isSkipperFree),
      'skipperFreeScope': serializer.toJson<String?>(skipperFreeScope),
      'iban': serializer.toJson<String?>(iban),
      'paypalLink': serializer.toJson<String?>(paypalLink),
      'revolutLink': serializer.toJson<String?>(revolutLink),
    };
  }

  CrewMember copyWith(
          {int? id,
          int? tripId,
          String? name,
          bool? isChild,
          bool? isVegetarian,
          bool? isNonDrinker,
          Value<String?> customEatLevel = const Value.absent(),
          Value<String?> customDrinkLevel = const Value.absent(),
          String? categoryParticipation,
          bool? isSkipperFree,
          Value<String?> skipperFreeScope = const Value.absent(),
          Value<String?> iban = const Value.absent(),
          Value<String?> paypalLink = const Value.absent(),
          Value<String?> revolutLink = const Value.absent()}) =>
      CrewMember(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        name: name ?? this.name,
        isChild: isChild ?? this.isChild,
        isVegetarian: isVegetarian ?? this.isVegetarian,
        isNonDrinker: isNonDrinker ?? this.isNonDrinker,
        customEatLevel:
            customEatLevel.present ? customEatLevel.value : this.customEatLevel,
        customDrinkLevel: customDrinkLevel.present
            ? customDrinkLevel.value
            : this.customDrinkLevel,
        categoryParticipation:
            categoryParticipation ?? this.categoryParticipation,
        isSkipperFree: isSkipperFree ?? this.isSkipperFree,
        skipperFreeScope: skipperFreeScope.present
            ? skipperFreeScope.value
            : this.skipperFreeScope,
        iban: iban.present ? iban.value : this.iban,
        paypalLink: paypalLink.present ? paypalLink.value : this.paypalLink,
        revolutLink: revolutLink.present ? revolutLink.value : this.revolutLink,
      );
  CrewMember copyWithCompanion(CrewMembersCompanion data) {
    return CrewMember(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      name: data.name.present ? data.name.value : this.name,
      isChild: data.isChild.present ? data.isChild.value : this.isChild,
      isVegetarian: data.isVegetarian.present
          ? data.isVegetarian.value
          : this.isVegetarian,
      isNonDrinker: data.isNonDrinker.present
          ? data.isNonDrinker.value
          : this.isNonDrinker,
      customEatLevel: data.customEatLevel.present
          ? data.customEatLevel.value
          : this.customEatLevel,
      customDrinkLevel: data.customDrinkLevel.present
          ? data.customDrinkLevel.value
          : this.customDrinkLevel,
      categoryParticipation: data.categoryParticipation.present
          ? data.categoryParticipation.value
          : this.categoryParticipation,
      isSkipperFree: data.isSkipperFree.present
          ? data.isSkipperFree.value
          : this.isSkipperFree,
      skipperFreeScope: data.skipperFreeScope.present
          ? data.skipperFreeScope.value
          : this.skipperFreeScope,
      iban: data.iban.present ? data.iban.value : this.iban,
      paypalLink:
          data.paypalLink.present ? data.paypalLink.value : this.paypalLink,
      revolutLink:
          data.revolutLink.present ? data.revolutLink.value : this.revolutLink,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CrewMember(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('name: $name, ')
          ..write('isChild: $isChild, ')
          ..write('isVegetarian: $isVegetarian, ')
          ..write('isNonDrinker: $isNonDrinker, ')
          ..write('customEatLevel: $customEatLevel, ')
          ..write('customDrinkLevel: $customDrinkLevel, ')
          ..write('categoryParticipation: $categoryParticipation, ')
          ..write('isSkipperFree: $isSkipperFree, ')
          ..write('skipperFreeScope: $skipperFreeScope, ')
          ..write('iban: $iban, ')
          ..write('paypalLink: $paypalLink, ')
          ..write('revolutLink: $revolutLink')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tripId,
      name,
      isChild,
      isVegetarian,
      isNonDrinker,
      customEatLevel,
      customDrinkLevel,
      categoryParticipation,
      isSkipperFree,
      skipperFreeScope,
      iban,
      paypalLink,
      revolutLink);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrewMember &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.name == this.name &&
          other.isChild == this.isChild &&
          other.isVegetarian == this.isVegetarian &&
          other.isNonDrinker == this.isNonDrinker &&
          other.customEatLevel == this.customEatLevel &&
          other.customDrinkLevel == this.customDrinkLevel &&
          other.categoryParticipation == this.categoryParticipation &&
          other.isSkipperFree == this.isSkipperFree &&
          other.skipperFreeScope == this.skipperFreeScope &&
          other.iban == this.iban &&
          other.paypalLink == this.paypalLink &&
          other.revolutLink == this.revolutLink);
}

class CrewMembersCompanion extends UpdateCompanion<CrewMember> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<String> name;
  final Value<bool> isChild;
  final Value<bool> isVegetarian;
  final Value<bool> isNonDrinker;
  final Value<String?> customEatLevel;
  final Value<String?> customDrinkLevel;
  final Value<String> categoryParticipation;
  final Value<bool> isSkipperFree;
  final Value<String?> skipperFreeScope;
  final Value<String?> iban;
  final Value<String?> paypalLink;
  final Value<String?> revolutLink;
  const CrewMembersCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.name = const Value.absent(),
    this.isChild = const Value.absent(),
    this.isVegetarian = const Value.absent(),
    this.isNonDrinker = const Value.absent(),
    this.customEatLevel = const Value.absent(),
    this.customDrinkLevel = const Value.absent(),
    this.categoryParticipation = const Value.absent(),
    this.isSkipperFree = const Value.absent(),
    this.skipperFreeScope = const Value.absent(),
    this.iban = const Value.absent(),
    this.paypalLink = const Value.absent(),
    this.revolutLink = const Value.absent(),
  });
  CrewMembersCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required String name,
    this.isChild = const Value.absent(),
    this.isVegetarian = const Value.absent(),
    this.isNonDrinker = const Value.absent(),
    this.customEatLevel = const Value.absent(),
    this.customDrinkLevel = const Value.absent(),
    this.categoryParticipation = const Value.absent(),
    this.isSkipperFree = const Value.absent(),
    this.skipperFreeScope = const Value.absent(),
    this.iban = const Value.absent(),
    this.paypalLink = const Value.absent(),
    this.revolutLink = const Value.absent(),
  })  : tripId = Value(tripId),
        name = Value(name);
  static Insertable<CrewMember> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<String>? name,
    Expression<bool>? isChild,
    Expression<bool>? isVegetarian,
    Expression<bool>? isNonDrinker,
    Expression<String>? customEatLevel,
    Expression<String>? customDrinkLevel,
    Expression<String>? categoryParticipation,
    Expression<bool>? isSkipperFree,
    Expression<String>? skipperFreeScope,
    Expression<String>? iban,
    Expression<String>? paypalLink,
    Expression<String>? revolutLink,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (name != null) 'name': name,
      if (isChild != null) 'is_child': isChild,
      if (isVegetarian != null) 'is_vegetarian': isVegetarian,
      if (isNonDrinker != null) 'is_non_drinker': isNonDrinker,
      if (customEatLevel != null) 'custom_eat_level': customEatLevel,
      if (customDrinkLevel != null) 'custom_drink_level': customDrinkLevel,
      if (categoryParticipation != null)
        'category_participation': categoryParticipation,
      if (isSkipperFree != null) 'is_skipper_free': isSkipperFree,
      if (skipperFreeScope != null) 'skipper_free_scope': skipperFreeScope,
      if (iban != null) 'iban': iban,
      if (paypalLink != null) 'paypal_link': paypalLink,
      if (revolutLink != null) 'revolut_link': revolutLink,
    });
  }

  CrewMembersCompanion copyWith(
      {Value<int>? id,
      Value<int>? tripId,
      Value<String>? name,
      Value<bool>? isChild,
      Value<bool>? isVegetarian,
      Value<bool>? isNonDrinker,
      Value<String?>? customEatLevel,
      Value<String?>? customDrinkLevel,
      Value<String>? categoryParticipation,
      Value<bool>? isSkipperFree,
      Value<String?>? skipperFreeScope,
      Value<String?>? iban,
      Value<String?>? paypalLink,
      Value<String?>? revolutLink}) {
    return CrewMembersCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      isChild: isChild ?? this.isChild,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isNonDrinker: isNonDrinker ?? this.isNonDrinker,
      customEatLevel: customEatLevel ?? this.customEatLevel,
      customDrinkLevel: customDrinkLevel ?? this.customDrinkLevel,
      categoryParticipation:
          categoryParticipation ?? this.categoryParticipation,
      isSkipperFree: isSkipperFree ?? this.isSkipperFree,
      skipperFreeScope: skipperFreeScope ?? this.skipperFreeScope,
      iban: iban ?? this.iban,
      paypalLink: paypalLink ?? this.paypalLink,
      revolutLink: revolutLink ?? this.revolutLink,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isChild.present) {
      map['is_child'] = Variable<bool>(isChild.value);
    }
    if (isVegetarian.present) {
      map['is_vegetarian'] = Variable<bool>(isVegetarian.value);
    }
    if (isNonDrinker.present) {
      map['is_non_drinker'] = Variable<bool>(isNonDrinker.value);
    }
    if (customEatLevel.present) {
      map['custom_eat_level'] = Variable<String>(customEatLevel.value);
    }
    if (customDrinkLevel.present) {
      map['custom_drink_level'] = Variable<String>(customDrinkLevel.value);
    }
    if (categoryParticipation.present) {
      map['category_participation'] =
          Variable<String>(categoryParticipation.value);
    }
    if (isSkipperFree.present) {
      map['is_skipper_free'] = Variable<bool>(isSkipperFree.value);
    }
    if (skipperFreeScope.present) {
      map['skipper_free_scope'] = Variable<String>(skipperFreeScope.value);
    }
    if (iban.present) {
      map['iban'] = Variable<String>(iban.value);
    }
    if (paypalLink.present) {
      map['paypal_link'] = Variable<String>(paypalLink.value);
    }
    if (revolutLink.present) {
      map['revolut_link'] = Variable<String>(revolutLink.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CrewMembersCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('name: $name, ')
          ..write('isChild: $isChild, ')
          ..write('isVegetarian: $isVegetarian, ')
          ..write('isNonDrinker: $isNonDrinker, ')
          ..write('customEatLevel: $customEatLevel, ')
          ..write('customDrinkLevel: $customDrinkLevel, ')
          ..write('categoryParticipation: $categoryParticipation, ')
          ..write('isSkipperFree: $isSkipperFree, ')
          ..write('skipperFreeScope: $skipperFreeScope, ')
          ..write('iban: $iban, ')
          ..write('paypalLink: $paypalLink, ')
          ..write('revolutLink: $revolutLink')
          ..write(')'))
        .toString();
  }
}

class $ShoppingStopsTable extends ShoppingStops
    with TableInfo<$ShoppingStopsTable, ShoppingStop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingStopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES trips (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayNumberMeta =
      const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
      'day_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isInitialMeta =
      const VerificationMeta('isInitial');
  @override
  late final GeneratedColumn<bool> isInitial = GeneratedColumn<bool>(
      'is_initial', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_initial" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, tripId, dayNumber, name, isInitial];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_stops';
  @override
  VerificationContext validateIntegrity(Insertable<ShoppingStop> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta,
          dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_initial')) {
      context.handle(_isInitialMeta,
          isInitial.isAcceptableOrUnknown(data['is_initial']!, _isInitialMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingStop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingStop(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id'])!,
      dayNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isInitial: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_initial'])!,
    );
  }

  @override
  $ShoppingStopsTable createAlias(String alias) {
    return $ShoppingStopsTable(attachedDatabase, alias);
  }
}

class ShoppingStop extends DataClass implements Insertable<ShoppingStop> {
  final int id;
  final int tripId;
  final int dayNumber;
  final String name;
  final bool isInitial;
  const ShoppingStop(
      {required this.id,
      required this.tripId,
      required this.dayNumber,
      required this.name,
      required this.isInitial});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['day_number'] = Variable<int>(dayNumber);
    map['name'] = Variable<String>(name);
    map['is_initial'] = Variable<bool>(isInitial);
    return map;
  }

  ShoppingStopsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingStopsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      dayNumber: Value(dayNumber),
      name: Value(name),
      isInitial: Value(isInitial),
    );
  }

  factory ShoppingStop.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingStop(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      name: serializer.fromJson<String>(json['name']),
      isInitial: serializer.fromJson<bool>(json['isInitial']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'name': serializer.toJson<String>(name),
      'isInitial': serializer.toJson<bool>(isInitial),
    };
  }

  ShoppingStop copyWith(
          {int? id,
          int? tripId,
          int? dayNumber,
          String? name,
          bool? isInitial}) =>
      ShoppingStop(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        dayNumber: dayNumber ?? this.dayNumber,
        name: name ?? this.name,
        isInitial: isInitial ?? this.isInitial,
      );
  ShoppingStop copyWithCompanion(ShoppingStopsCompanion data) {
    return ShoppingStop(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      name: data.name.present ? data.name.value : this.name,
      isInitial: data.isInitial.present ? data.isInitial.value : this.isInitial,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingStop(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('name: $name, ')
          ..write('isInitial: $isInitial')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tripId, dayNumber, name, isInitial);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingStop &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.dayNumber == this.dayNumber &&
          other.name == this.name &&
          other.isInitial == this.isInitial);
}

class ShoppingStopsCompanion extends UpdateCompanion<ShoppingStop> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<int> dayNumber;
  final Value<String> name;
  final Value<bool> isInitial;
  const ShoppingStopsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.isInitial = const Value.absent(),
  });
  ShoppingStopsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    this.dayNumber = const Value.absent(),
    required String name,
    this.isInitial = const Value.absent(),
  })  : tripId = Value(tripId),
        name = Value(name);
  static Insertable<ShoppingStop> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<int>? dayNumber,
    Expression<String>? name,
    Expression<bool>? isInitial,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (name != null) 'name': name,
      if (isInitial != null) 'is_initial': isInitial,
    });
  }

  ShoppingStopsCompanion copyWith(
      {Value<int>? id,
      Value<int>? tripId,
      Value<int>? dayNumber,
      Value<String>? name,
      Value<bool>? isInitial}) {
    return ShoppingStopsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      name: name ?? this.name,
      isInitial: isInitial ?? this.isInitial,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isInitial.present) {
      map['is_initial'] = Variable<bool>(isInitial.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingStopsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('name: $name, ')
          ..write('isInitial: $isInitial')
          ..write(')'))
        .toString();
  }
}

class $ListItemsTable extends ListItems
    with TableInfo<$ListItemsTable, ListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES trips (id) ON DELETE CASCADE'));
  static const VerificationMeta _catalogIdMeta =
      const VerificationMeta('catalogId');
  @override
  late final GeneratedColumn<String> catalogId = GeneratedColumn<String>(
      'catalog_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customNameMeta =
      const VerificationMeta('customName');
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
      'custom_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customUnitMeta =
      const VerificationMeta('customUnit');
  @override
  late final GeneratedColumn<String> customUnit = GeneratedColumn<String>(
      'custom_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customDepartmentMeta =
      const VerificationMeta('customDepartment');
  @override
  late final GeneratedColumn<String> customDepartment = GeneratedColumn<String>(
      'custom_department', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _selectedMeta =
      const VerificationMeta('selected');
  @override
  late final GeneratedColumn<bool> selected = GeneratedColumn<bool>(
      'selected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("selected" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _shareMeta = const VerificationMeta('share');
  @override
  late final GeneratedColumn<double> share = GeneratedColumn<double>(
      'share', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _calculatedQuantityMeta =
      const VerificationMeta('calculatedQuantity');
  @override
  late final GeneratedColumn<double> calculatedQuantity =
      GeneratedColumn<double>('calculated_quantity', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _calculatedPackagesMeta =
      const VerificationMeta('calculatedPackages');
  @override
  late final GeneratedColumn<int> calculatedPackages = GeneratedColumn<int>(
      'calculated_packages', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _overriddenPackagesMeta =
      const VerificationMeta('overriddenPackages');
  @override
  late final GeneratedColumn<int> overriddenPackages = GeneratedColumn<int>(
      'overridden_packages', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _customPackageSizeMeta =
      const VerificationMeta('customPackageSize');
  @override
  late final GeneratedColumn<double> customPackageSize =
      GeneratedColumn<double>('custom_package_size', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _checkStateMeta =
      const VerificationMeta('checkState');
  @override
  late final GeneratedColumnWithTypeConverter<CheckItemState, String>
      checkState = GeneratedColumn<String>('check_state', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('vorhanden'))
          .withConverter<CheckItemState>($ListItemsTable.$convertercheckState);
  static const VerificationMeta _isAdoptedMeta =
      const VerificationMeta('isAdopted');
  @override
  late final GeneratedColumn<bool> isAdopted = GeneratedColumn<bool>(
      'is_adopted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_adopted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tripId,
        catalogId,
        isCustom,
        customName,
        customUnit,
        customDepartment,
        selected,
        share,
        calculatedQuantity,
        calculatedPackages,
        overriddenPackages,
        customPackageSize,
        checkState,
        isAdopted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_items';
  @override
  VerificationContext validateIntegrity(Insertable<ListItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('catalog_id')) {
      context.handle(_catalogIdMeta,
          catalogId.isAcceptableOrUnknown(data['catalog_id']!, _catalogIdMeta));
    } else if (isInserting) {
      context.missing(_catalogIdMeta);
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('custom_name')) {
      context.handle(
          _customNameMeta,
          customName.isAcceptableOrUnknown(
              data['custom_name']!, _customNameMeta));
    }
    if (data.containsKey('custom_unit')) {
      context.handle(
          _customUnitMeta,
          customUnit.isAcceptableOrUnknown(
              data['custom_unit']!, _customUnitMeta));
    }
    if (data.containsKey('custom_department')) {
      context.handle(
          _customDepartmentMeta,
          customDepartment.isAcceptableOrUnknown(
              data['custom_department']!, _customDepartmentMeta));
    }
    if (data.containsKey('selected')) {
      context.handle(_selectedMeta,
          selected.isAcceptableOrUnknown(data['selected']!, _selectedMeta));
    }
    if (data.containsKey('share')) {
      context.handle(
          _shareMeta, share.isAcceptableOrUnknown(data['share']!, _shareMeta));
    }
    if (data.containsKey('calculated_quantity')) {
      context.handle(
          _calculatedQuantityMeta,
          calculatedQuantity.isAcceptableOrUnknown(
              data['calculated_quantity']!, _calculatedQuantityMeta));
    }
    if (data.containsKey('calculated_packages')) {
      context.handle(
          _calculatedPackagesMeta,
          calculatedPackages.isAcceptableOrUnknown(
              data['calculated_packages']!, _calculatedPackagesMeta));
    }
    if (data.containsKey('overridden_packages')) {
      context.handle(
          _overriddenPackagesMeta,
          overriddenPackages.isAcceptableOrUnknown(
              data['overridden_packages']!, _overriddenPackagesMeta));
    }
    if (data.containsKey('custom_package_size')) {
      context.handle(
          _customPackageSizeMeta,
          customPackageSize.isAcceptableOrUnknown(
              data['custom_package_size']!, _customPackageSizeMeta));
    }
    context.handle(_checkStateMeta, const VerificationResult.success());
    if (data.containsKey('is_adopted')) {
      context.handle(_isAdoptedMeta,
          isAdopted.isAcceptableOrUnknown(data['is_adopted']!, _isAdoptedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id'])!,
      catalogId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}catalog_id'])!,
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      customName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_name']),
      customUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_unit']),
      customDepartment: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_department']),
      selected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}selected'])!,
      share: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}share'])!,
      calculatedQuantity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}calculated_quantity'])!,
      calculatedPackages: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}calculated_packages'])!,
      overriddenPackages: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}overridden_packages']),
      customPackageSize: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}custom_package_size']),
      checkState: $ListItemsTable.$convertercheckState.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_state'])!),
      isAdopted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_adopted'])!,
    );
  }

  @override
  $ListItemsTable createAlias(String alias) {
    return $ListItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<CheckItemState, String> $convertercheckState =
      const CheckItemStateConverter();
}

class ListItem extends DataClass implements Insertable<ListItem> {
  final int id;
  final int tripId;
  final String catalogId;
  final bool isCustom;
  final String? customName;
  final String? customUnit;
  final String? customDepartment;
  final bool selected;
  final double share;
  final double calculatedQuantity;
  final int calculatedPackages;
  final int? overriddenPackages;
  final double? customPackageSize;
  final CheckItemState checkState;
  final bool isAdopted;
  const ListItem(
      {required this.id,
      required this.tripId,
      required this.catalogId,
      required this.isCustom,
      this.customName,
      this.customUnit,
      this.customDepartment,
      required this.selected,
      required this.share,
      required this.calculatedQuantity,
      required this.calculatedPackages,
      this.overriddenPackages,
      this.customPackageSize,
      required this.checkState,
      required this.isAdopted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['catalog_id'] = Variable<String>(catalogId);
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    if (!nullToAbsent || customUnit != null) {
      map['custom_unit'] = Variable<String>(customUnit);
    }
    if (!nullToAbsent || customDepartment != null) {
      map['custom_department'] = Variable<String>(customDepartment);
    }
    map['selected'] = Variable<bool>(selected);
    map['share'] = Variable<double>(share);
    map['calculated_quantity'] = Variable<double>(calculatedQuantity);
    map['calculated_packages'] = Variable<int>(calculatedPackages);
    if (!nullToAbsent || overriddenPackages != null) {
      map['overridden_packages'] = Variable<int>(overriddenPackages);
    }
    if (!nullToAbsent || customPackageSize != null) {
      map['custom_package_size'] = Variable<double>(customPackageSize);
    }
    {
      map['check_state'] = Variable<String>(
          $ListItemsTable.$convertercheckState.toSql(checkState));
    }
    map['is_adopted'] = Variable<bool>(isAdopted);
    return map;
  }

  ListItemsCompanion toCompanion(bool nullToAbsent) {
    return ListItemsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      catalogId: Value(catalogId),
      isCustom: Value(isCustom),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      customUnit: customUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(customUnit),
      customDepartment: customDepartment == null && nullToAbsent
          ? const Value.absent()
          : Value(customDepartment),
      selected: Value(selected),
      share: Value(share),
      calculatedQuantity: Value(calculatedQuantity),
      calculatedPackages: Value(calculatedPackages),
      overriddenPackages: overriddenPackages == null && nullToAbsent
          ? const Value.absent()
          : Value(overriddenPackages),
      customPackageSize: customPackageSize == null && nullToAbsent
          ? const Value.absent()
          : Value(customPackageSize),
      checkState: Value(checkState),
      isAdopted: Value(isAdopted),
    );
  }

  factory ListItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListItem(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      catalogId: serializer.fromJson<String>(json['catalogId']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      customName: serializer.fromJson<String?>(json['customName']),
      customUnit: serializer.fromJson<String?>(json['customUnit']),
      customDepartment: serializer.fromJson<String?>(json['customDepartment']),
      selected: serializer.fromJson<bool>(json['selected']),
      share: serializer.fromJson<double>(json['share']),
      calculatedQuantity:
          serializer.fromJson<double>(json['calculatedQuantity']),
      calculatedPackages: serializer.fromJson<int>(json['calculatedPackages']),
      overriddenPackages: serializer.fromJson<int?>(json['overriddenPackages']),
      customPackageSize:
          serializer.fromJson<double?>(json['customPackageSize']),
      checkState: serializer.fromJson<CheckItemState>(json['checkState']),
      isAdopted: serializer.fromJson<bool>(json['isAdopted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'catalogId': serializer.toJson<String>(catalogId),
      'isCustom': serializer.toJson<bool>(isCustom),
      'customName': serializer.toJson<String?>(customName),
      'customUnit': serializer.toJson<String?>(customUnit),
      'customDepartment': serializer.toJson<String?>(customDepartment),
      'selected': serializer.toJson<bool>(selected),
      'share': serializer.toJson<double>(share),
      'calculatedQuantity': serializer.toJson<double>(calculatedQuantity),
      'calculatedPackages': serializer.toJson<int>(calculatedPackages),
      'overriddenPackages': serializer.toJson<int?>(overriddenPackages),
      'customPackageSize': serializer.toJson<double?>(customPackageSize),
      'checkState': serializer.toJson<CheckItemState>(checkState),
      'isAdopted': serializer.toJson<bool>(isAdopted),
    };
  }

  ListItem copyWith(
          {int? id,
          int? tripId,
          String? catalogId,
          bool? isCustom,
          Value<String?> customName = const Value.absent(),
          Value<String?> customUnit = const Value.absent(),
          Value<String?> customDepartment = const Value.absent(),
          bool? selected,
          double? share,
          double? calculatedQuantity,
          int? calculatedPackages,
          Value<int?> overriddenPackages = const Value.absent(),
          Value<double?> customPackageSize = const Value.absent(),
          CheckItemState? checkState,
          bool? isAdopted}) =>
      ListItem(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        catalogId: catalogId ?? this.catalogId,
        isCustom: isCustom ?? this.isCustom,
        customName: customName.present ? customName.value : this.customName,
        customUnit: customUnit.present ? customUnit.value : this.customUnit,
        customDepartment: customDepartment.present
            ? customDepartment.value
            : this.customDepartment,
        selected: selected ?? this.selected,
        share: share ?? this.share,
        calculatedQuantity: calculatedQuantity ?? this.calculatedQuantity,
        calculatedPackages: calculatedPackages ?? this.calculatedPackages,
        overriddenPackages: overriddenPackages.present
            ? overriddenPackages.value
            : this.overriddenPackages,
        customPackageSize: customPackageSize.present
            ? customPackageSize.value
            : this.customPackageSize,
        checkState: checkState ?? this.checkState,
        isAdopted: isAdopted ?? this.isAdopted,
      );
  ListItem copyWithCompanion(ListItemsCompanion data) {
    return ListItem(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      catalogId: data.catalogId.present ? data.catalogId.value : this.catalogId,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      customName:
          data.customName.present ? data.customName.value : this.customName,
      customUnit:
          data.customUnit.present ? data.customUnit.value : this.customUnit,
      customDepartment: data.customDepartment.present
          ? data.customDepartment.value
          : this.customDepartment,
      selected: data.selected.present ? data.selected.value : this.selected,
      share: data.share.present ? data.share.value : this.share,
      calculatedQuantity: data.calculatedQuantity.present
          ? data.calculatedQuantity.value
          : this.calculatedQuantity,
      calculatedPackages: data.calculatedPackages.present
          ? data.calculatedPackages.value
          : this.calculatedPackages,
      overriddenPackages: data.overriddenPackages.present
          ? data.overriddenPackages.value
          : this.overriddenPackages,
      customPackageSize: data.customPackageSize.present
          ? data.customPackageSize.value
          : this.customPackageSize,
      checkState:
          data.checkState.present ? data.checkState.value : this.checkState,
      isAdopted: data.isAdopted.present ? data.isAdopted.value : this.isAdopted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListItem(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('catalogId: $catalogId, ')
          ..write('isCustom: $isCustom, ')
          ..write('customName: $customName, ')
          ..write('customUnit: $customUnit, ')
          ..write('customDepartment: $customDepartment, ')
          ..write('selected: $selected, ')
          ..write('share: $share, ')
          ..write('calculatedQuantity: $calculatedQuantity, ')
          ..write('calculatedPackages: $calculatedPackages, ')
          ..write('overriddenPackages: $overriddenPackages, ')
          ..write('customPackageSize: $customPackageSize, ')
          ..write('checkState: $checkState, ')
          ..write('isAdopted: $isAdopted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tripId,
      catalogId,
      isCustom,
      customName,
      customUnit,
      customDepartment,
      selected,
      share,
      calculatedQuantity,
      calculatedPackages,
      overriddenPackages,
      customPackageSize,
      checkState,
      isAdopted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListItem &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.catalogId == this.catalogId &&
          other.isCustom == this.isCustom &&
          other.customName == this.customName &&
          other.customUnit == this.customUnit &&
          other.customDepartment == this.customDepartment &&
          other.selected == this.selected &&
          other.share == this.share &&
          other.calculatedQuantity == this.calculatedQuantity &&
          other.calculatedPackages == this.calculatedPackages &&
          other.overriddenPackages == this.overriddenPackages &&
          other.customPackageSize == this.customPackageSize &&
          other.checkState == this.checkState &&
          other.isAdopted == this.isAdopted);
}

class ListItemsCompanion extends UpdateCompanion<ListItem> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<String> catalogId;
  final Value<bool> isCustom;
  final Value<String?> customName;
  final Value<String?> customUnit;
  final Value<String?> customDepartment;
  final Value<bool> selected;
  final Value<double> share;
  final Value<double> calculatedQuantity;
  final Value<int> calculatedPackages;
  final Value<int?> overriddenPackages;
  final Value<double?> customPackageSize;
  final Value<CheckItemState> checkState;
  final Value<bool> isAdopted;
  const ListItemsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.catalogId = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.customName = const Value.absent(),
    this.customUnit = const Value.absent(),
    this.customDepartment = const Value.absent(),
    this.selected = const Value.absent(),
    this.share = const Value.absent(),
    this.calculatedQuantity = const Value.absent(),
    this.calculatedPackages = const Value.absent(),
    this.overriddenPackages = const Value.absent(),
    this.customPackageSize = const Value.absent(),
    this.checkState = const Value.absent(),
    this.isAdopted = const Value.absent(),
  });
  ListItemsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required String catalogId,
    this.isCustom = const Value.absent(),
    this.customName = const Value.absent(),
    this.customUnit = const Value.absent(),
    this.customDepartment = const Value.absent(),
    this.selected = const Value.absent(),
    this.share = const Value.absent(),
    this.calculatedQuantity = const Value.absent(),
    this.calculatedPackages = const Value.absent(),
    this.overriddenPackages = const Value.absent(),
    this.customPackageSize = const Value.absent(),
    this.checkState = const Value.absent(),
    this.isAdopted = const Value.absent(),
  })  : tripId = Value(tripId),
        catalogId = Value(catalogId);
  static Insertable<ListItem> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<String>? catalogId,
    Expression<bool>? isCustom,
    Expression<String>? customName,
    Expression<String>? customUnit,
    Expression<String>? customDepartment,
    Expression<bool>? selected,
    Expression<double>? share,
    Expression<double>? calculatedQuantity,
    Expression<int>? calculatedPackages,
    Expression<int>? overriddenPackages,
    Expression<double>? customPackageSize,
    Expression<String>? checkState,
    Expression<bool>? isAdopted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (catalogId != null) 'catalog_id': catalogId,
      if (isCustom != null) 'is_custom': isCustom,
      if (customName != null) 'custom_name': customName,
      if (customUnit != null) 'custom_unit': customUnit,
      if (customDepartment != null) 'custom_department': customDepartment,
      if (selected != null) 'selected': selected,
      if (share != null) 'share': share,
      if (calculatedQuantity != null) 'calculated_quantity': calculatedQuantity,
      if (calculatedPackages != null) 'calculated_packages': calculatedPackages,
      if (overriddenPackages != null) 'overridden_packages': overriddenPackages,
      if (customPackageSize != null) 'custom_package_size': customPackageSize,
      if (checkState != null) 'check_state': checkState,
      if (isAdopted != null) 'is_adopted': isAdopted,
    });
  }

  ListItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? tripId,
      Value<String>? catalogId,
      Value<bool>? isCustom,
      Value<String?>? customName,
      Value<String?>? customUnit,
      Value<String?>? customDepartment,
      Value<bool>? selected,
      Value<double>? share,
      Value<double>? calculatedQuantity,
      Value<int>? calculatedPackages,
      Value<int?>? overriddenPackages,
      Value<double?>? customPackageSize,
      Value<CheckItemState>? checkState,
      Value<bool>? isAdopted}) {
    return ListItemsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      catalogId: catalogId ?? this.catalogId,
      isCustom: isCustom ?? this.isCustom,
      customName: customName ?? this.customName,
      customUnit: customUnit ?? this.customUnit,
      customDepartment: customDepartment ?? this.customDepartment,
      selected: selected ?? this.selected,
      share: share ?? this.share,
      calculatedQuantity: calculatedQuantity ?? this.calculatedQuantity,
      calculatedPackages: calculatedPackages ?? this.calculatedPackages,
      overriddenPackages: overriddenPackages ?? this.overriddenPackages,
      customPackageSize: customPackageSize ?? this.customPackageSize,
      checkState: checkState ?? this.checkState,
      isAdopted: isAdopted ?? this.isAdopted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (catalogId.present) {
      map['catalog_id'] = Variable<String>(catalogId.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (customUnit.present) {
      map['custom_unit'] = Variable<String>(customUnit.value);
    }
    if (customDepartment.present) {
      map['custom_department'] = Variable<String>(customDepartment.value);
    }
    if (selected.present) {
      map['selected'] = Variable<bool>(selected.value);
    }
    if (share.present) {
      map['share'] = Variable<double>(share.value);
    }
    if (calculatedQuantity.present) {
      map['calculated_quantity'] = Variable<double>(calculatedQuantity.value);
    }
    if (calculatedPackages.present) {
      map['calculated_packages'] = Variable<int>(calculatedPackages.value);
    }
    if (overriddenPackages.present) {
      map['overridden_packages'] = Variable<int>(overriddenPackages.value);
    }
    if (customPackageSize.present) {
      map['custom_package_size'] = Variable<double>(customPackageSize.value);
    }
    if (checkState.present) {
      map['check_state'] = Variable<String>(
          $ListItemsTable.$convertercheckState.toSql(checkState.value));
    }
    if (isAdopted.present) {
      map['is_adopted'] = Variable<bool>(isAdopted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListItemsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('catalogId: $catalogId, ')
          ..write('isCustom: $isCustom, ')
          ..write('customName: $customName, ')
          ..write('customUnit: $customUnit, ')
          ..write('customDepartment: $customDepartment, ')
          ..write('selected: $selected, ')
          ..write('share: $share, ')
          ..write('calculatedQuantity: $calculatedQuantity, ')
          ..write('calculatedPackages: $calculatedPackages, ')
          ..write('overriddenPackages: $overriddenPackages, ')
          ..write('customPackageSize: $customPackageSize, ')
          ..write('checkState: $checkState, ')
          ..write('isAdopted: $isAdopted')
          ..write(')'))
        .toString();
  }
}

class $ListItemAllocationsTable extends ListItemAllocations
    with TableInfo<$ListItemAllocationsTable, ListItemAllocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListItemAllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES trips (id) ON DELETE CASCADE'));
  static const VerificationMeta _listItemIdMeta =
      const VerificationMeta('listItemId');
  @override
  late final GeneratedColumn<int> listItemId = GeneratedColumn<int>(
      'list_item_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES list_items (id) ON DELETE CASCADE'));
  static const VerificationMeta _shoppingStopIdMeta =
      const VerificationMeta('shoppingStopId');
  @override
  late final GeneratedColumn<int> shoppingStopId = GeneratedColumn<int>(
      'shopping_stop_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES shopping_stops (id) ON DELETE CASCADE'));
  static const VerificationMeta _allocatedPackagesMeta =
      const VerificationMeta('allocatedPackages');
  @override
  late final GeneratedColumn<int> allocatedPackages = GeneratedColumn<int>(
      'allocated_packages', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isBoughtMeta =
      const VerificationMeta('isBought');
  @override
  late final GeneratedColumn<bool> isBought = GeneratedColumn<bool>(
      'is_bought', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_bought" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isStoredMeta =
      const VerificationMeta('isStored');
  @override
  late final GeneratedColumn<bool> isStored = GeneratedColumn<bool>(
      'is_stored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_stored" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tripId,
        listItemId,
        shoppingStopId,
        allocatedPackages,
        isBought,
        isStored
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_item_allocations';
  @override
  VerificationContext validateIntegrity(Insertable<ListItemAllocation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('list_item_id')) {
      context.handle(
          _listItemIdMeta,
          listItemId.isAcceptableOrUnknown(
              data['list_item_id']!, _listItemIdMeta));
    } else if (isInserting) {
      context.missing(_listItemIdMeta);
    }
    if (data.containsKey('shopping_stop_id')) {
      context.handle(
          _shoppingStopIdMeta,
          shoppingStopId.isAcceptableOrUnknown(
              data['shopping_stop_id']!, _shoppingStopIdMeta));
    } else if (isInserting) {
      context.missing(_shoppingStopIdMeta);
    }
    if (data.containsKey('allocated_packages')) {
      context.handle(
          _allocatedPackagesMeta,
          allocatedPackages.isAcceptableOrUnknown(
              data['allocated_packages']!, _allocatedPackagesMeta));
    } else if (isInserting) {
      context.missing(_allocatedPackagesMeta);
    }
    if (data.containsKey('is_bought')) {
      context.handle(_isBoughtMeta,
          isBought.isAcceptableOrUnknown(data['is_bought']!, _isBoughtMeta));
    }
    if (data.containsKey('is_stored')) {
      context.handle(_isStoredMeta,
          isStored.isAcceptableOrUnknown(data['is_stored']!, _isStoredMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListItemAllocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListItemAllocation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id'])!,
      listItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}list_item_id'])!,
      shoppingStopId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shopping_stop_id'])!,
      allocatedPackages: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}allocated_packages'])!,
      isBought: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_bought'])!,
      isStored: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_stored'])!,
    );
  }

  @override
  $ListItemAllocationsTable createAlias(String alias) {
    return $ListItemAllocationsTable(attachedDatabase, alias);
  }
}

class ListItemAllocation extends DataClass
    implements Insertable<ListItemAllocation> {
  final int id;
  final int tripId;
  final int listItemId;
  final int shoppingStopId;
  final int allocatedPackages;
  final bool isBought;
  final bool isStored;
  const ListItemAllocation(
      {required this.id,
      required this.tripId,
      required this.listItemId,
      required this.shoppingStopId,
      required this.allocatedPackages,
      required this.isBought,
      required this.isStored});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['list_item_id'] = Variable<int>(listItemId);
    map['shopping_stop_id'] = Variable<int>(shoppingStopId);
    map['allocated_packages'] = Variable<int>(allocatedPackages);
    map['is_bought'] = Variable<bool>(isBought);
    map['is_stored'] = Variable<bool>(isStored);
    return map;
  }

  ListItemAllocationsCompanion toCompanion(bool nullToAbsent) {
    return ListItemAllocationsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      listItemId: Value(listItemId),
      shoppingStopId: Value(shoppingStopId),
      allocatedPackages: Value(allocatedPackages),
      isBought: Value(isBought),
      isStored: Value(isStored),
    );
  }

  factory ListItemAllocation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListItemAllocation(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      listItemId: serializer.fromJson<int>(json['listItemId']),
      shoppingStopId: serializer.fromJson<int>(json['shoppingStopId']),
      allocatedPackages: serializer.fromJson<int>(json['allocatedPackages']),
      isBought: serializer.fromJson<bool>(json['isBought']),
      isStored: serializer.fromJson<bool>(json['isStored']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'listItemId': serializer.toJson<int>(listItemId),
      'shoppingStopId': serializer.toJson<int>(shoppingStopId),
      'allocatedPackages': serializer.toJson<int>(allocatedPackages),
      'isBought': serializer.toJson<bool>(isBought),
      'isStored': serializer.toJson<bool>(isStored),
    };
  }

  ListItemAllocation copyWith(
          {int? id,
          int? tripId,
          int? listItemId,
          int? shoppingStopId,
          int? allocatedPackages,
          bool? isBought,
          bool? isStored}) =>
      ListItemAllocation(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        listItemId: listItemId ?? this.listItemId,
        shoppingStopId: shoppingStopId ?? this.shoppingStopId,
        allocatedPackages: allocatedPackages ?? this.allocatedPackages,
        isBought: isBought ?? this.isBought,
        isStored: isStored ?? this.isStored,
      );
  ListItemAllocation copyWithCompanion(ListItemAllocationsCompanion data) {
    return ListItemAllocation(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      listItemId:
          data.listItemId.present ? data.listItemId.value : this.listItemId,
      shoppingStopId: data.shoppingStopId.present
          ? data.shoppingStopId.value
          : this.shoppingStopId,
      allocatedPackages: data.allocatedPackages.present
          ? data.allocatedPackages.value
          : this.allocatedPackages,
      isBought: data.isBought.present ? data.isBought.value : this.isBought,
      isStored: data.isStored.present ? data.isStored.value : this.isStored,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListItemAllocation(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('listItemId: $listItemId, ')
          ..write('shoppingStopId: $shoppingStopId, ')
          ..write('allocatedPackages: $allocatedPackages, ')
          ..write('isBought: $isBought, ')
          ..write('isStored: $isStored')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tripId, listItemId, shoppingStopId,
      allocatedPackages, isBought, isStored);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListItemAllocation &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.listItemId == this.listItemId &&
          other.shoppingStopId == this.shoppingStopId &&
          other.allocatedPackages == this.allocatedPackages &&
          other.isBought == this.isBought &&
          other.isStored == this.isStored);
}

class ListItemAllocationsCompanion extends UpdateCompanion<ListItemAllocation> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<int> listItemId;
  final Value<int> shoppingStopId;
  final Value<int> allocatedPackages;
  final Value<bool> isBought;
  final Value<bool> isStored;
  const ListItemAllocationsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.listItemId = const Value.absent(),
    this.shoppingStopId = const Value.absent(),
    this.allocatedPackages = const Value.absent(),
    this.isBought = const Value.absent(),
    this.isStored = const Value.absent(),
  });
  ListItemAllocationsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required int listItemId,
    required int shoppingStopId,
    required int allocatedPackages,
    this.isBought = const Value.absent(),
    this.isStored = const Value.absent(),
  })  : tripId = Value(tripId),
        listItemId = Value(listItemId),
        shoppingStopId = Value(shoppingStopId),
        allocatedPackages = Value(allocatedPackages);
  static Insertable<ListItemAllocation> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<int>? listItemId,
    Expression<int>? shoppingStopId,
    Expression<int>? allocatedPackages,
    Expression<bool>? isBought,
    Expression<bool>? isStored,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (listItemId != null) 'list_item_id': listItemId,
      if (shoppingStopId != null) 'shopping_stop_id': shoppingStopId,
      if (allocatedPackages != null) 'allocated_packages': allocatedPackages,
      if (isBought != null) 'is_bought': isBought,
      if (isStored != null) 'is_stored': isStored,
    });
  }

  ListItemAllocationsCompanion copyWith(
      {Value<int>? id,
      Value<int>? tripId,
      Value<int>? listItemId,
      Value<int>? shoppingStopId,
      Value<int>? allocatedPackages,
      Value<bool>? isBought,
      Value<bool>? isStored}) {
    return ListItemAllocationsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      listItemId: listItemId ?? this.listItemId,
      shoppingStopId: shoppingStopId ?? this.shoppingStopId,
      allocatedPackages: allocatedPackages ?? this.allocatedPackages,
      isBought: isBought ?? this.isBought,
      isStored: isStored ?? this.isStored,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (listItemId.present) {
      map['list_item_id'] = Variable<int>(listItemId.value);
    }
    if (shoppingStopId.present) {
      map['shopping_stop_id'] = Variable<int>(shoppingStopId.value);
    }
    if (allocatedPackages.present) {
      map['allocated_packages'] = Variable<int>(allocatedPackages.value);
    }
    if (isBought.present) {
      map['is_bought'] = Variable<bool>(isBought.value);
    }
    if (isStored.present) {
      map['is_stored'] = Variable<bool>(isStored.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListItemAllocationsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('listItemId: $listItemId, ')
          ..write('shoppingStopId: $shoppingStopId, ')
          ..write('allocatedPackages: $allocatedPackages, ')
          ..write('isBought: $isBought, ')
          ..write('isStored: $isStored')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES trips (id) ON DELETE CASCADE'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('EUR'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumnWithTypeConverter<ExpenseCategory, String>
      category = GeneratedColumn<String>('category', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ExpenseCategory>($ExpensesTable.$convertercategory);
  static const VerificationMeta _paidByCrewMemberIdMeta =
      const VerificationMeta('paidByCrewMemberId');
  @override
  late final GeneratedColumn<int> paidByCrewMemberId = GeneratedColumn<int>(
      'paid_by_crew_member_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES crew_members (id) ON DELETE SET NULL'));
  static const VerificationMeta _isPaidFromKittyMeta =
      const VerificationMeta('isPaidFromKitty');
  @override
  late final GeneratedColumn<bool> isPaidFromKitty = GeneratedColumn<bool>(
      'is_paid_from_kitty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_paid_from_kitty" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customSplitMeta =
      const VerificationMeta('customSplit');
  @override
  late final GeneratedColumn<String> customSplit = GeneratedColumn<String>(
      'custom_split', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tripId,
        amount,
        currency,
        category,
        paidByCrewMemberId,
        isPaidFromKitty,
        customSplit,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    context.handle(_categoryMeta, const VerificationResult.success());
    if (data.containsKey('paid_by_crew_member_id')) {
      context.handle(
          _paidByCrewMemberIdMeta,
          paidByCrewMemberId.isAcceptableOrUnknown(
              data['paid_by_crew_member_id']!, _paidByCrewMemberIdMeta));
    }
    if (data.containsKey('is_paid_from_kitty')) {
      context.handle(
          _isPaidFromKittyMeta,
          isPaidFromKitty.isAcceptableOrUnknown(
              data['is_paid_from_kitty']!, _isPaidFromKittyMeta));
    }
    if (data.containsKey('custom_split')) {
      context.handle(
          _customSplitMeta,
          customSplit.isAcceptableOrUnknown(
              data['custom_split']!, _customSplitMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      category: $ExpensesTable.$convertercategory.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!),
      paidByCrewMemberId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}paid_by_crew_member_id']),
      isPaidFromKitty: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_paid_from_kitty'])!,
      customSplit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_split']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }

  static TypeConverter<ExpenseCategory, String> $convertercategory =
      const ExpenseCategoryConverter();
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final int tripId;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final int? paidByCrewMemberId;
  final bool isPaidFromKitty;
  final String? customSplit;
  final String? note;
  final DateTime createdAt;
  const Expense(
      {required this.id,
      required this.tripId,
      required this.amount,
      required this.currency,
      required this.category,
      this.paidByCrewMemberId,
      required this.isPaidFromKitty,
      this.customSplit,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    {
      map['category'] =
          Variable<String>($ExpensesTable.$convertercategory.toSql(category));
    }
    if (!nullToAbsent || paidByCrewMemberId != null) {
      map['paid_by_crew_member_id'] = Variable<int>(paidByCrewMemberId);
    }
    map['is_paid_from_kitty'] = Variable<bool>(isPaidFromKitty);
    if (!nullToAbsent || customSplit != null) {
      map['custom_split'] = Variable<String>(customSplit);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      tripId: Value(tripId),
      amount: Value(amount),
      currency: Value(currency),
      category: Value(category),
      paidByCrewMemberId: paidByCrewMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(paidByCrewMemberId),
      isPaidFromKitty: Value(isPaidFromKitty),
      customSplit: customSplit == null && nullToAbsent
          ? const Value.absent()
          : Value(customSplit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<ExpenseCategory>(json['category']),
      paidByCrewMemberId: serializer.fromJson<int?>(json['paidByCrewMemberId']),
      isPaidFromKitty: serializer.fromJson<bool>(json['isPaidFromKitty']),
      customSplit: serializer.fromJson<String?>(json['customSplit']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<ExpenseCategory>(category),
      'paidByCrewMemberId': serializer.toJson<int?>(paidByCrewMemberId),
      'isPaidFromKitty': serializer.toJson<bool>(isPaidFromKitty),
      'customSplit': serializer.toJson<String?>(customSplit),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Expense copyWith(
          {int? id,
          int? tripId,
          double? amount,
          String? currency,
          ExpenseCategory? category,
          Value<int?> paidByCrewMemberId = const Value.absent(),
          bool? isPaidFromKitty,
          Value<String?> customSplit = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      Expense(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        category: category ?? this.category,
        paidByCrewMemberId: paidByCrewMemberId.present
            ? paidByCrewMemberId.value
            : this.paidByCrewMemberId,
        isPaidFromKitty: isPaidFromKitty ?? this.isPaidFromKitty,
        customSplit: customSplit.present ? customSplit.value : this.customSplit,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      paidByCrewMemberId: data.paidByCrewMemberId.present
          ? data.paidByCrewMemberId.value
          : this.paidByCrewMemberId,
      isPaidFromKitty: data.isPaidFromKitty.present
          ? data.isPaidFromKitty.value
          : this.isPaidFromKitty,
      customSplit:
          data.customSplit.present ? data.customSplit.value : this.customSplit,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('paidByCrewMemberId: $paidByCrewMemberId, ')
          ..write('isPaidFromKitty: $isPaidFromKitty, ')
          ..write('customSplit: $customSplit, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tripId, amount, currency, category,
      paidByCrewMemberId, isPaidFromKitty, customSplit, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.paidByCrewMemberId == this.paidByCrewMemberId &&
          other.isPaidFromKitty == this.isPaidFromKitty &&
          other.customSplit == this.customSplit &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<ExpenseCategory> category;
  final Value<int?> paidByCrewMemberId;
  final Value<bool> isPaidFromKitty;
  final Value<String?> customSplit;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.paidByCrewMemberId = const Value.absent(),
    this.isPaidFromKitty = const Value.absent(),
    this.customSplit = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required double amount,
    this.currency = const Value.absent(),
    required ExpenseCategory category,
    this.paidByCrewMemberId = const Value.absent(),
    this.isPaidFromKitty = const Value.absent(),
    this.customSplit = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : tripId = Value(tripId),
        amount = Value(amount),
        category = Value(category);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<int>? paidByCrewMemberId,
    Expression<bool>? isPaidFromKitty,
    Expression<String>? customSplit,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (paidByCrewMemberId != null)
        'paid_by_crew_member_id': paidByCrewMemberId,
      if (isPaidFromKitty != null) 'is_paid_from_kitty': isPaidFromKitty,
      if (customSplit != null) 'custom_split': customSplit,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExpensesCompanion copyWith(
      {Value<int>? id,
      Value<int>? tripId,
      Value<double>? amount,
      Value<String>? currency,
      Value<ExpenseCategory>? category,
      Value<int?>? paidByCrewMemberId,
      Value<bool>? isPaidFromKitty,
      Value<String?>? customSplit,
      Value<String?>? note,
      Value<DateTime>? createdAt}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paidByCrewMemberId: paidByCrewMemberId ?? this.paidByCrewMemberId,
      isPaidFromKitty: isPaidFromKitty ?? this.isPaidFromKitty,
      customSplit: customSplit ?? this.customSplit,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
          $ExpensesTable.$convertercategory.toSql(category.value));
    }
    if (paidByCrewMemberId.present) {
      map['paid_by_crew_member_id'] = Variable<int>(paidByCrewMemberId.value);
    }
    if (isPaidFromKitty.present) {
      map['is_paid_from_kitty'] = Variable<bool>(isPaidFromKitty.value);
    }
    if (customSplit.present) {
      map['custom_split'] = Variable<String>(customSplit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('paidByCrewMemberId: $paidByCrewMemberId, ')
          ..write('isPaidFromKitty: $isPaidFromKitty, ')
          ..write('customSplit: $customSplit, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KittyPaymentsTable extends KittyPayments
    with TableInfo<$KittyPaymentsTable, KittyPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KittyPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES trips (id) ON DELETE CASCADE'));
  static const VerificationMeta _crewMemberIdMeta =
      const VerificationMeta('crewMemberId');
  @override
  late final GeneratedColumn<int> crewMemberId = GeneratedColumn<int>(
      'crew_member_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES crew_members (id) ON DELETE CASCADE'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, tripId, crewMemberId, amount, paidAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kitty_payments';
  @override
  VerificationContext validateIntegrity(Insertable<KittyPayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('crew_member_id')) {
      context.handle(
          _crewMemberIdMeta,
          crewMemberId.isAcceptableOrUnknown(
              data['crew_member_id']!, _crewMemberIdMeta));
    } else if (isInserting) {
      context.missing(_crewMemberIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KittyPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KittyPayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id'])!,
      crewMemberId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}crew_member_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at'])!,
    );
  }

  @override
  $KittyPaymentsTable createAlias(String alias) {
    return $KittyPaymentsTable(attachedDatabase, alias);
  }
}

class KittyPayment extends DataClass implements Insertable<KittyPayment> {
  final int id;
  final int tripId;
  final int crewMemberId;
  final double amount;
  final DateTime paidAt;
  const KittyPayment(
      {required this.id,
      required this.tripId,
      required this.crewMemberId,
      required this.amount,
      required this.paidAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['crew_member_id'] = Variable<int>(crewMemberId);
    map['amount'] = Variable<double>(amount);
    map['paid_at'] = Variable<DateTime>(paidAt);
    return map;
  }

  KittyPaymentsCompanion toCompanion(bool nullToAbsent) {
    return KittyPaymentsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      crewMemberId: Value(crewMemberId),
      amount: Value(amount),
      paidAt: Value(paidAt),
    );
  }

  factory KittyPayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KittyPayment(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      crewMemberId: serializer.fromJson<int>(json['crewMemberId']),
      amount: serializer.fromJson<double>(json['amount']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'crewMemberId': serializer.toJson<int>(crewMemberId),
      'amount': serializer.toJson<double>(amount),
      'paidAt': serializer.toJson<DateTime>(paidAt),
    };
  }

  KittyPayment copyWith(
          {int? id,
          int? tripId,
          int? crewMemberId,
          double? amount,
          DateTime? paidAt}) =>
      KittyPayment(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        crewMemberId: crewMemberId ?? this.crewMemberId,
        amount: amount ?? this.amount,
        paidAt: paidAt ?? this.paidAt,
      );
  KittyPayment copyWithCompanion(KittyPaymentsCompanion data) {
    return KittyPayment(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      crewMemberId: data.crewMemberId.present
          ? data.crewMemberId.value
          : this.crewMemberId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KittyPayment(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('crewMemberId: $crewMemberId, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tripId, crewMemberId, amount, paidAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KittyPayment &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.crewMemberId == this.crewMemberId &&
          other.amount == this.amount &&
          other.paidAt == this.paidAt);
}

class KittyPaymentsCompanion extends UpdateCompanion<KittyPayment> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<int> crewMemberId;
  final Value<double> amount;
  final Value<DateTime> paidAt;
  const KittyPaymentsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.crewMemberId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidAt = const Value.absent(),
  });
  KittyPaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required int crewMemberId,
    required double amount,
    this.paidAt = const Value.absent(),
  })  : tripId = Value(tripId),
        crewMemberId = Value(crewMemberId),
        amount = Value(amount);
  static Insertable<KittyPayment> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<int>? crewMemberId,
    Expression<double>? amount,
    Expression<DateTime>? paidAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (crewMemberId != null) 'crew_member_id': crewMemberId,
      if (amount != null) 'amount': amount,
      if (paidAt != null) 'paid_at': paidAt,
    });
  }

  KittyPaymentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? tripId,
      Value<int>? crewMemberId,
      Value<double>? amount,
      Value<DateTime>? paidAt}) {
    return KittyPaymentsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      crewMemberId: crewMemberId ?? this.crewMemberId,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (crewMemberId.present) {
      map['crew_member_id'] = Variable<int>(crewMemberId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KittyPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('crewMemberId: $crewMemberId, ')
          ..write('amount: $amount, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $TripDaysTable tripDays = $TripDaysTable(this);
  late final $CrewMembersTable crewMembers = $CrewMembersTable(this);
  late final $ShoppingStopsTable shoppingStops = $ShoppingStopsTable(this);
  late final $ListItemsTable listItems = $ListItemsTable(this);
  late final $ListItemAllocationsTable listItemAllocations =
      $ListItemAllocationsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $KittyPaymentsTable kittyPayments = $KittyPaymentsTable(this);
  late final TripDao tripDao = TripDao(this as AppDatabase);
  late final ListItemDao listItemDao = ListItemDao(this as AppDatabase);
  late final ExpenseDao expenseDao = ExpenseDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        trips,
        tripDays,
        crewMembers,
        shoppingStops,
        listItems,
        listItemAllocations,
        expenses,
        kittyPayments
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('trips',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('trip_days', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('trips',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('crew_members', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('trips',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shopping_stops', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('trips',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('list_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('trips',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('list_item_allocations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('list_items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('list_item_allocations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('shopping_stops',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('list_item_allocations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('trips',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('expenses', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('crew_members',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('expenses', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('trips',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('kitty_payments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('crew_members',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('kitty_payments', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$TripsTableCreateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  required String name,
  required DateTime startDate,
  Value<int> daysCount,
  Value<String> region,
  Value<String> climate,
  Value<bool> isCharter,
  Value<String> boatType,
  Value<int> fridgeCapacity,
  Value<CrewAppetite> appetite,
  Value<String> reserveDays,
  Value<CrewDrinking> drinkingHabit,
  Value<bool> hasStorageChecklist,
  Value<TripPhase> phase,
  Value<bool> isArchived,
  Value<String> currency,
  Value<KittyModel> kittyModel,
  Value<int?> treasurerMemberId,
  Value<DateTime> createdAt,
});
typedef $$TripsTableUpdateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> startDate,
  Value<int> daysCount,
  Value<String> region,
  Value<String> climate,
  Value<bool> isCharter,
  Value<String> boatType,
  Value<int> fridgeCapacity,
  Value<CrewAppetite> appetite,
  Value<String> reserveDays,
  Value<CrewDrinking> drinkingHabit,
  Value<bool> hasStorageChecklist,
  Value<TripPhase> phase,
  Value<bool> isArchived,
  Value<String> currency,
  Value<KittyModel> kittyModel,
  Value<int?> treasurerMemberId,
  Value<DateTime> createdAt,
});

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, Trip> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TripDaysTable, List<TripDay>> _tripDaysRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tripDays,
          aliasName: $_aliasNameGenerator(db.trips.id, db.tripDays.tripId));

  $$TripDaysTableProcessedTableManager get tripDaysRefs {
    final manager = $$TripDaysTableTableManager($_db, $_db.tripDays)
        .filter((f) => f.tripId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_tripDaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CrewMembersTable, List<CrewMember>>
      _crewMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.crewMembers,
          aliasName: $_aliasNameGenerator(db.trips.id, db.crewMembers.tripId));

  $$CrewMembersTableProcessedTableManager get crewMembersRefs {
    final manager = $$CrewMembersTableTableManager($_db, $_db.crewMembers)
        .filter((f) => f.tripId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_crewMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ShoppingStopsTable, List<ShoppingStop>>
      _shoppingStopsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.shoppingStops,
              aliasName:
                  $_aliasNameGenerator(db.trips.id, db.shoppingStops.tripId));

  $$ShoppingStopsTableProcessedTableManager get shoppingStopsRefs {
    final manager = $$ShoppingStopsTableTableManager($_db, $_db.shoppingStops)
        .filter((f) => f.tripId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_shoppingStopsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ListItemsTable, List<ListItem>>
      _listItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.listItems,
          aliasName: $_aliasNameGenerator(db.trips.id, db.listItems.tripId));

  $$ListItemsTableProcessedTableManager get listItemsRefs {
    final manager = $$ListItemsTableTableManager($_db, $_db.listItems)
        .filter((f) => f.tripId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_listItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ListItemAllocationsTable,
      List<ListItemAllocation>> _listItemAllocationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.listItemAllocations,
          aliasName:
              $_aliasNameGenerator(db.trips.id, db.listItemAllocations.tripId));

  $$ListItemAllocationsTableProcessedTableManager get listItemAllocationsRefs {
    final manager =
        $$ListItemAllocationsTableTableManager($_db, $_db.listItemAllocations)
            .filter((f) => f.tripId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_listItemAllocationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.expenses,
          aliasName: $_aliasNameGenerator(db.trips.id, db.expenses.tripId));

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.tripId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$KittyPaymentsTable, List<KittyPayment>>
      _kittyPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.kittyPayments,
              aliasName:
                  $_aliasNameGenerator(db.trips.id, db.kittyPayments.tripId));

  $$KittyPaymentsTableProcessedTableManager get kittyPaymentsRefs {
    final manager = $$KittyPaymentsTableTableManager($_db, $_db.kittyPayments)
        .filter((f) => f.tripId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_kittyPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysCount => $composableBuilder(
      column: $table.daysCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get climate => $composableBuilder(
      column: $table.climate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCharter => $composableBuilder(
      column: $table.isCharter, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get boatType => $composableBuilder(
      column: $table.boatType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fridgeCapacity => $composableBuilder(
      column: $table.fridgeCapacity,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CrewAppetite, CrewAppetite, String>
      get appetite => $composableBuilder(
          column: $table.appetite,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get reserveDays => $composableBuilder(
      column: $table.reserveDays, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CrewDrinking, CrewDrinking, String>
      get drinkingHabit => $composableBuilder(
          column: $table.drinkingHabit,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get hasStorageChecklist => $composableBuilder(
      column: $table.hasStorageChecklist,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TripPhase, TripPhase, String> get phase =>
      $composableBuilder(
          column: $table.phase,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<KittyModel, KittyModel, String>
      get kittyModel => $composableBuilder(
          column: $table.kittyModel,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get treasurerMemberId => $composableBuilder(
      column: $table.treasurerMemberId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> tripDaysRefs(
      Expression<bool> Function($$TripDaysTableFilterComposer f) f) {
    final $$TripDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tripDays,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripDaysTableFilterComposer(
              $db: $db,
              $table: $db.tripDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> crewMembersRefs(
      Expression<bool> Function($$CrewMembersTableFilterComposer f) f) {
    final $$CrewMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableFilterComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> shoppingStopsRefs(
      Expression<bool> Function($$ShoppingStopsTableFilterComposer f) f) {
    final $$ShoppingStopsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingStops,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingStopsTableFilterComposer(
              $db: $db,
              $table: $db.shoppingStops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> listItemsRefs(
      Expression<bool> Function($$ListItemsTableFilterComposer f) f) {
    final $$ListItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listItems,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemsTableFilterComposer(
              $db: $db,
              $table: $db.listItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> listItemAllocationsRefs(
      Expression<bool> Function($$ListItemAllocationsTableFilterComposer f) f) {
    final $$ListItemAllocationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listItemAllocations,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemAllocationsTableFilterComposer(
              $db: $db,
              $table: $db.listItemAllocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expensesRefs(
      Expression<bool> Function($$ExpensesTableFilterComposer f) f) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> kittyPaymentsRefs(
      Expression<bool> Function($$KittyPaymentsTableFilterComposer f) f) {
    final $$KittyPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.kittyPayments,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KittyPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.kittyPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysCount => $composableBuilder(
      column: $table.daysCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get climate => $composableBuilder(
      column: $table.climate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCharter => $composableBuilder(
      column: $table.isCharter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get boatType => $composableBuilder(
      column: $table.boatType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fridgeCapacity => $composableBuilder(
      column: $table.fridgeCapacity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appetite => $composableBuilder(
      column: $table.appetite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reserveDays => $composableBuilder(
      column: $table.reserveDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get drinkingHabit => $composableBuilder(
      column: $table.drinkingHabit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasStorageChecklist => $composableBuilder(
      column: $table.hasStorageChecklist,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phase => $composableBuilder(
      column: $table.phase, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kittyModel => $composableBuilder(
      column: $table.kittyModel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get treasurerMemberId => $composableBuilder(
      column: $table.treasurerMemberId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get daysCount =>
      $composableBuilder(column: $table.daysCount, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get climate =>
      $composableBuilder(column: $table.climate, builder: (column) => column);

  GeneratedColumn<bool> get isCharter =>
      $composableBuilder(column: $table.isCharter, builder: (column) => column);

  GeneratedColumn<String> get boatType =>
      $composableBuilder(column: $table.boatType, builder: (column) => column);

  GeneratedColumn<int> get fridgeCapacity => $composableBuilder(
      column: $table.fridgeCapacity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CrewAppetite, String> get appetite =>
      $composableBuilder(column: $table.appetite, builder: (column) => column);

  GeneratedColumn<String> get reserveDays => $composableBuilder(
      column: $table.reserveDays, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CrewDrinking, String> get drinkingHabit =>
      $composableBuilder(
          column: $table.drinkingHabit, builder: (column) => column);

  GeneratedColumn<bool> get hasStorageChecklist => $composableBuilder(
      column: $table.hasStorageChecklist, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TripPhase, String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<KittyModel, String> get kittyModel =>
      $composableBuilder(
          column: $table.kittyModel, builder: (column) => column);

  GeneratedColumn<int> get treasurerMemberId => $composableBuilder(
      column: $table.treasurerMemberId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> tripDaysRefs<T extends Object>(
      Expression<T> Function($$TripDaysTableAnnotationComposer a) f) {
    final $$TripDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tripDays,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.tripDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> crewMembersRefs<T extends Object>(
      Expression<T> Function($$CrewMembersTableAnnotationComposer a) f) {
    final $$CrewMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> shoppingStopsRefs<T extends Object>(
      Expression<T> Function($$ShoppingStopsTableAnnotationComposer a) f) {
    final $$ShoppingStopsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shoppingStops,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingStopsTableAnnotationComposer(
              $db: $db,
              $table: $db.shoppingStops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> listItemsRefs<T extends Object>(
      Expression<T> Function($$ListItemsTableAnnotationComposer a) f) {
    final $$ListItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listItems,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.listItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> listItemAllocationsRefs<T extends Object>(
      Expression<T> Function($$ListItemAllocationsTableAnnotationComposer a)
          f) {
    final $$ListItemAllocationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.listItemAllocations,
            getReferencedColumn: (t) => t.tripId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ListItemAllocationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.listItemAllocations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
      Expression<T> Function($$ExpensesTableAnnotationComposer a) f) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> kittyPaymentsRefs<T extends Object>(
      Expression<T> Function($$KittyPaymentsTableAnnotationComposer a) f) {
    final $$KittyPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.kittyPayments,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KittyPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.kittyPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TripsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TripsTable,
    Trip,
    $$TripsTableFilterComposer,
    $$TripsTableOrderingComposer,
    $$TripsTableAnnotationComposer,
    $$TripsTableCreateCompanionBuilder,
    $$TripsTableUpdateCompanionBuilder,
    (Trip, $$TripsTableReferences),
    Trip,
    PrefetchHooks Function(
        {bool tripDaysRefs,
        bool crewMembersRefs,
        bool shoppingStopsRefs,
        bool listItemsRefs,
        bool listItemAllocationsRefs,
        bool expensesRefs,
        bool kittyPaymentsRefs})> {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<int> daysCount = const Value.absent(),
            Value<String> region = const Value.absent(),
            Value<String> climate = const Value.absent(),
            Value<bool> isCharter = const Value.absent(),
            Value<String> boatType = const Value.absent(),
            Value<int> fridgeCapacity = const Value.absent(),
            Value<CrewAppetite> appetite = const Value.absent(),
            Value<String> reserveDays = const Value.absent(),
            Value<CrewDrinking> drinkingHabit = const Value.absent(),
            Value<bool> hasStorageChecklist = const Value.absent(),
            Value<TripPhase> phase = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<KittyModel> kittyModel = const Value.absent(),
            Value<int?> treasurerMemberId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TripsCompanion(
            id: id,
            name: name,
            startDate: startDate,
            daysCount: daysCount,
            region: region,
            climate: climate,
            isCharter: isCharter,
            boatType: boatType,
            fridgeCapacity: fridgeCapacity,
            appetite: appetite,
            reserveDays: reserveDays,
            drinkingHabit: drinkingHabit,
            hasStorageChecklist: hasStorageChecklist,
            phase: phase,
            isArchived: isArchived,
            currency: currency,
            kittyModel: kittyModel,
            treasurerMemberId: treasurerMemberId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required DateTime startDate,
            Value<int> daysCount = const Value.absent(),
            Value<String> region = const Value.absent(),
            Value<String> climate = const Value.absent(),
            Value<bool> isCharter = const Value.absent(),
            Value<String> boatType = const Value.absent(),
            Value<int> fridgeCapacity = const Value.absent(),
            Value<CrewAppetite> appetite = const Value.absent(),
            Value<String> reserveDays = const Value.absent(),
            Value<CrewDrinking> drinkingHabit = const Value.absent(),
            Value<bool> hasStorageChecklist = const Value.absent(),
            Value<TripPhase> phase = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<KittyModel> kittyModel = const Value.absent(),
            Value<int?> treasurerMemberId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TripsCompanion.insert(
            id: id,
            name: name,
            startDate: startDate,
            daysCount: daysCount,
            region: region,
            climate: climate,
            isCharter: isCharter,
            boatType: boatType,
            fridgeCapacity: fridgeCapacity,
            appetite: appetite,
            reserveDays: reserveDays,
            drinkingHabit: drinkingHabit,
            hasStorageChecklist: hasStorageChecklist,
            phase: phase,
            isArchived: isArchived,
            currency: currency,
            kittyModel: kittyModel,
            treasurerMemberId: treasurerMemberId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TripsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {tripDaysRefs = false,
              crewMembersRefs = false,
              shoppingStopsRefs = false,
              listItemsRefs = false,
              listItemAllocationsRefs = false,
              expensesRefs = false,
              kittyPaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tripDaysRefs) db.tripDays,
                if (crewMembersRefs) db.crewMembers,
                if (shoppingStopsRefs) db.shoppingStops,
                if (listItemsRefs) db.listItems,
                if (listItemAllocationsRefs) db.listItemAllocations,
                if (expensesRefs) db.expenses,
                if (kittyPaymentsRefs) db.kittyPayments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tripDaysRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TripsTableReferences._tripDaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0).tripDaysRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items),
                  if (crewMembersRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TripsTableReferences._crewMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0)
                                .crewMembersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items),
                  if (shoppingStopsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TripsTableReferences._shoppingStopsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0)
                                .shoppingStopsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items),
                  if (listItemsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TripsTableReferences._listItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0).listItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items),
                  if (listItemAllocationsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$TripsTableReferences
                            ._listItemAllocationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0)
                                .listItemAllocationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items),
                  if (expensesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TripsTableReferences._expensesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0).expensesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items),
                  if (kittyPaymentsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TripsTableReferences._kittyPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0)
                                .kittyPaymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TripsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TripsTable,
    Trip,
    $$TripsTableFilterComposer,
    $$TripsTableOrderingComposer,
    $$TripsTableAnnotationComposer,
    $$TripsTableCreateCompanionBuilder,
    $$TripsTableUpdateCompanionBuilder,
    (Trip, $$TripsTableReferences),
    Trip,
    PrefetchHooks Function(
        {bool tripDaysRefs,
        bool crewMembersRefs,
        bool shoppingStopsRefs,
        bool listItemsRefs,
        bool listItemAllocationsRefs,
        bool expensesRefs,
        bool kittyPaymentsRefs})>;
typedef $$TripDaysTableCreateCompanionBuilder = TripDaysCompanion Function({
  Value<int> id,
  required int tripId,
  required int dayNumber,
  Value<bool> lunchRestaurant,
  Value<bool> dinnerRestaurant,
  Value<String?> dayType,
  Value<String?> portName,
});
typedef $$TripDaysTableUpdateCompanionBuilder = TripDaysCompanion Function({
  Value<int> id,
  Value<int> tripId,
  Value<int> dayNumber,
  Value<bool> lunchRestaurant,
  Value<bool> dinnerRestaurant,
  Value<String?> dayType,
  Value<String?> portName,
});

final class $$TripDaysTableReferences
    extends BaseReferences<_$AppDatabase, $TripDaysTable, TripDay> {
  $$TripDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips
      .createAlias($_aliasNameGenerator(db.tripDays.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id($_item.tripId));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TripDaysTableFilterComposer
    extends Composer<_$AppDatabase, $TripDaysTable> {
  $$TripDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get lunchRestaurant => $composableBuilder(
      column: $table.lunchRestaurant,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dinnerRestaurant => $composableBuilder(
      column: $table.dinnerRestaurant,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayType => $composableBuilder(
      column: $table.dayType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get portName => $composableBuilder(
      column: $table.portName, builder: (column) => ColumnFilters(column));

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TripDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $TripDaysTable> {
  $$TripDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get lunchRestaurant => $composableBuilder(
      column: $table.lunchRestaurant,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dinnerRestaurant => $composableBuilder(
      column: $table.dinnerRestaurant,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayType => $composableBuilder(
      column: $table.dayType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get portName => $composableBuilder(
      column: $table.portName, builder: (column) => ColumnOrderings(column));

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TripDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripDaysTable> {
  $$TripDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<bool> get lunchRestaurant => $composableBuilder(
      column: $table.lunchRestaurant, builder: (column) => column);

  GeneratedColumn<bool> get dinnerRestaurant => $composableBuilder(
      column: $table.dinnerRestaurant, builder: (column) => column);

  GeneratedColumn<String> get dayType =>
      $composableBuilder(column: $table.dayType, builder: (column) => column);

  GeneratedColumn<String> get portName =>
      $composableBuilder(column: $table.portName, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TripDaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TripDaysTable,
    TripDay,
    $$TripDaysTableFilterComposer,
    $$TripDaysTableOrderingComposer,
    $$TripDaysTableAnnotationComposer,
    $$TripDaysTableCreateCompanionBuilder,
    $$TripDaysTableUpdateCompanionBuilder,
    (TripDay, $$TripDaysTableReferences),
    TripDay,
    PrefetchHooks Function({bool tripId})> {
  $$TripDaysTableTableManager(_$AppDatabase db, $TripDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tripId = const Value.absent(),
            Value<int> dayNumber = const Value.absent(),
            Value<bool> lunchRestaurant = const Value.absent(),
            Value<bool> dinnerRestaurant = const Value.absent(),
            Value<String?> dayType = const Value.absent(),
            Value<String?> portName = const Value.absent(),
          }) =>
              TripDaysCompanion(
            id: id,
            tripId: tripId,
            dayNumber: dayNumber,
            lunchRestaurant: lunchRestaurant,
            dinnerRestaurant: dinnerRestaurant,
            dayType: dayType,
            portName: portName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tripId,
            required int dayNumber,
            Value<bool> lunchRestaurant = const Value.absent(),
            Value<bool> dinnerRestaurant = const Value.absent(),
            Value<String?> dayType = const Value.absent(),
            Value<String?> portName = const Value.absent(),
          }) =>
              TripDaysCompanion.insert(
            id: id,
            tripId: tripId,
            dayNumber: dayNumber,
            lunchRestaurant: lunchRestaurant,
            dinnerRestaurant: dinnerRestaurant,
            dayType: dayType,
            portName: portName,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TripDaysTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable: $$TripDaysTableReferences._tripIdTable(db),
                    referencedColumn:
                        $$TripDaysTableReferences._tripIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TripDaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TripDaysTable,
    TripDay,
    $$TripDaysTableFilterComposer,
    $$TripDaysTableOrderingComposer,
    $$TripDaysTableAnnotationComposer,
    $$TripDaysTableCreateCompanionBuilder,
    $$TripDaysTableUpdateCompanionBuilder,
    (TripDay, $$TripDaysTableReferences),
    TripDay,
    PrefetchHooks Function({bool tripId})>;
typedef $$CrewMembersTableCreateCompanionBuilder = CrewMembersCompanion
    Function({
  Value<int> id,
  required int tripId,
  required String name,
  Value<bool> isChild,
  Value<bool> isVegetarian,
  Value<bool> isNonDrinker,
  Value<String?> customEatLevel,
  Value<String?> customDrinkLevel,
  Value<String> categoryParticipation,
  Value<bool> isSkipperFree,
  Value<String?> skipperFreeScope,
  Value<String?> iban,
  Value<String?> paypalLink,
  Value<String?> revolutLink,
});
typedef $$CrewMembersTableUpdateCompanionBuilder = CrewMembersCompanion
    Function({
  Value<int> id,
  Value<int> tripId,
  Value<String> name,
  Value<bool> isChild,
  Value<bool> isVegetarian,
  Value<bool> isNonDrinker,
  Value<String?> customEatLevel,
  Value<String?> customDrinkLevel,
  Value<String> categoryParticipation,
  Value<bool> isSkipperFree,
  Value<String?> skipperFreeScope,
  Value<String?> iban,
  Value<String?> paypalLink,
  Value<String?> revolutLink,
});

final class $$CrewMembersTableReferences
    extends BaseReferences<_$AppDatabase, $CrewMembersTable, CrewMember> {
  $$CrewMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips
      .createAlias($_aliasNameGenerator(db.crewMembers.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id($_item.tripId));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.expenses,
          aliasName: $_aliasNameGenerator(
              db.crewMembers.id, db.expenses.paidByCrewMemberId));

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.paidByCrewMemberId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$KittyPaymentsTable, List<KittyPayment>>
      _kittyPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.kittyPayments,
              aliasName: $_aliasNameGenerator(
                  db.crewMembers.id, db.kittyPayments.crewMemberId));

  $$KittyPaymentsTableProcessedTableManager get kittyPaymentsRefs {
    final manager = $$KittyPaymentsTableTableManager($_db, $_db.kittyPayments)
        .filter((f) => f.crewMemberId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_kittyPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CrewMembersTableFilterComposer
    extends Composer<_$AppDatabase, $CrewMembersTable> {
  $$CrewMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isChild => $composableBuilder(
      column: $table.isChild, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVegetarian => $composableBuilder(
      column: $table.isVegetarian, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isNonDrinker => $composableBuilder(
      column: $table.isNonDrinker, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customEatLevel => $composableBuilder(
      column: $table.customEatLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customDrinkLevel => $composableBuilder(
      column: $table.customDrinkLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryParticipation => $composableBuilder(
      column: $table.categoryParticipation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSkipperFree => $composableBuilder(
      column: $table.isSkipperFree, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get skipperFreeScope => $composableBuilder(
      column: $table.skipperFreeScope,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iban => $composableBuilder(
      column: $table.iban, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paypalLink => $composableBuilder(
      column: $table.paypalLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get revolutLink => $composableBuilder(
      column: $table.revolutLink, builder: (column) => ColumnFilters(column));

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> expensesRefs(
      Expression<bool> Function($$ExpensesTableFilterComposer f) f) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.paidByCrewMemberId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> kittyPaymentsRefs(
      Expression<bool> Function($$KittyPaymentsTableFilterComposer f) f) {
    final $$KittyPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.kittyPayments,
        getReferencedColumn: (t) => t.crewMemberId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KittyPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.kittyPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CrewMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $CrewMembersTable> {
  $$CrewMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isChild => $composableBuilder(
      column: $table.isChild, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVegetarian => $composableBuilder(
      column: $table.isVegetarian,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isNonDrinker => $composableBuilder(
      column: $table.isNonDrinker,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customEatLevel => $composableBuilder(
      column: $table.customEatLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customDrinkLevel => $composableBuilder(
      column: $table.customDrinkLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryParticipation => $composableBuilder(
      column: $table.categoryParticipation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSkipperFree => $composableBuilder(
      column: $table.isSkipperFree,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get skipperFreeScope => $composableBuilder(
      column: $table.skipperFreeScope,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iban => $composableBuilder(
      column: $table.iban, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paypalLink => $composableBuilder(
      column: $table.paypalLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get revolutLink => $composableBuilder(
      column: $table.revolutLink, builder: (column) => ColumnOrderings(column));

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CrewMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CrewMembersTable> {
  $$CrewMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isChild =>
      $composableBuilder(column: $table.isChild, builder: (column) => column);

  GeneratedColumn<bool> get isVegetarian => $composableBuilder(
      column: $table.isVegetarian, builder: (column) => column);

  GeneratedColumn<bool> get isNonDrinker => $composableBuilder(
      column: $table.isNonDrinker, builder: (column) => column);

  GeneratedColumn<String> get customEatLevel => $composableBuilder(
      column: $table.customEatLevel, builder: (column) => column);

  GeneratedColumn<String> get customDrinkLevel => $composableBuilder(
      column: $table.customDrinkLevel, builder: (column) => column);

  GeneratedColumn<String> get categoryParticipation => $composableBuilder(
      column: $table.categoryParticipation, builder: (column) => column);

  GeneratedColumn<bool> get isSkipperFree => $composableBuilder(
      column: $table.isSkipperFree, builder: (column) => column);

  GeneratedColumn<String> get skipperFreeScope => $composableBuilder(
      column: $table.skipperFreeScope, builder: (column) => column);

  GeneratedColumn<String> get iban =>
      $composableBuilder(column: $table.iban, builder: (column) => column);

  GeneratedColumn<String> get paypalLink => $composableBuilder(
      column: $table.paypalLink, builder: (column) => column);

  GeneratedColumn<String> get revolutLink => $composableBuilder(
      column: $table.revolutLink, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
      Expression<T> Function($$ExpensesTableAnnotationComposer a) f) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.paidByCrewMemberId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> kittyPaymentsRefs<T extends Object>(
      Expression<T> Function($$KittyPaymentsTableAnnotationComposer a) f) {
    final $$KittyPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.kittyPayments,
        getReferencedColumn: (t) => t.crewMemberId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$KittyPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.kittyPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CrewMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CrewMembersTable,
    CrewMember,
    $$CrewMembersTableFilterComposer,
    $$CrewMembersTableOrderingComposer,
    $$CrewMembersTableAnnotationComposer,
    $$CrewMembersTableCreateCompanionBuilder,
    $$CrewMembersTableUpdateCompanionBuilder,
    (CrewMember, $$CrewMembersTableReferences),
    CrewMember,
    PrefetchHooks Function(
        {bool tripId, bool expensesRefs, bool kittyPaymentsRefs})> {
  $$CrewMembersTableTableManager(_$AppDatabase db, $CrewMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CrewMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CrewMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CrewMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tripId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isChild = const Value.absent(),
            Value<bool> isVegetarian = const Value.absent(),
            Value<bool> isNonDrinker = const Value.absent(),
            Value<String?> customEatLevel = const Value.absent(),
            Value<String?> customDrinkLevel = const Value.absent(),
            Value<String> categoryParticipation = const Value.absent(),
            Value<bool> isSkipperFree = const Value.absent(),
            Value<String?> skipperFreeScope = const Value.absent(),
            Value<String?> iban = const Value.absent(),
            Value<String?> paypalLink = const Value.absent(),
            Value<String?> revolutLink = const Value.absent(),
          }) =>
              CrewMembersCompanion(
            id: id,
            tripId: tripId,
            name: name,
            isChild: isChild,
            isVegetarian: isVegetarian,
            isNonDrinker: isNonDrinker,
            customEatLevel: customEatLevel,
            customDrinkLevel: customDrinkLevel,
            categoryParticipation: categoryParticipation,
            isSkipperFree: isSkipperFree,
            skipperFreeScope: skipperFreeScope,
            iban: iban,
            paypalLink: paypalLink,
            revolutLink: revolutLink,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tripId,
            required String name,
            Value<bool> isChild = const Value.absent(),
            Value<bool> isVegetarian = const Value.absent(),
            Value<bool> isNonDrinker = const Value.absent(),
            Value<String?> customEatLevel = const Value.absent(),
            Value<String?> customDrinkLevel = const Value.absent(),
            Value<String> categoryParticipation = const Value.absent(),
            Value<bool> isSkipperFree = const Value.absent(),
            Value<String?> skipperFreeScope = const Value.absent(),
            Value<String?> iban = const Value.absent(),
            Value<String?> paypalLink = const Value.absent(),
            Value<String?> revolutLink = const Value.absent(),
          }) =>
              CrewMembersCompanion.insert(
            id: id,
            tripId: tripId,
            name: name,
            isChild: isChild,
            isVegetarian: isVegetarian,
            isNonDrinker: isNonDrinker,
            customEatLevel: customEatLevel,
            customDrinkLevel: customDrinkLevel,
            categoryParticipation: categoryParticipation,
            isSkipperFree: isSkipperFree,
            skipperFreeScope: skipperFreeScope,
            iban: iban,
            paypalLink: paypalLink,
            revolutLink: revolutLink,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CrewMembersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {tripId = false,
              expensesRefs = false,
              kittyPaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (expensesRefs) db.expenses,
                if (kittyPaymentsRefs) db.kittyPayments
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable:
                        $$CrewMembersTableReferences._tripIdTable(db),
                    referencedColumn:
                        $$CrewMembersTableReferences._tripIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expensesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CrewMembersTableReferences._expensesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CrewMembersTableReferences(db, table, p0)
                                .expensesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.paidByCrewMemberId == item.id),
                        typedResults: items),
                  if (kittyPaymentsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CrewMembersTableReferences
                            ._kittyPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CrewMembersTableReferences(db, table, p0)
                                .kittyPaymentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.crewMemberId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CrewMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CrewMembersTable,
    CrewMember,
    $$CrewMembersTableFilterComposer,
    $$CrewMembersTableOrderingComposer,
    $$CrewMembersTableAnnotationComposer,
    $$CrewMembersTableCreateCompanionBuilder,
    $$CrewMembersTableUpdateCompanionBuilder,
    (CrewMember, $$CrewMembersTableReferences),
    CrewMember,
    PrefetchHooks Function(
        {bool tripId, bool expensesRefs, bool kittyPaymentsRefs})>;
typedef $$ShoppingStopsTableCreateCompanionBuilder = ShoppingStopsCompanion
    Function({
  Value<int> id,
  required int tripId,
  Value<int> dayNumber,
  required String name,
  Value<bool> isInitial,
});
typedef $$ShoppingStopsTableUpdateCompanionBuilder = ShoppingStopsCompanion
    Function({
  Value<int> id,
  Value<int> tripId,
  Value<int> dayNumber,
  Value<String> name,
  Value<bool> isInitial,
});

final class $$ShoppingStopsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingStopsTable, ShoppingStop> {
  $$ShoppingStopsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips
      .createAlias($_aliasNameGenerator(db.shoppingStops.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id($_item.tripId));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ListItemAllocationsTable,
      List<ListItemAllocation>> _listItemAllocationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.listItemAllocations,
          aliasName: $_aliasNameGenerator(
              db.shoppingStops.id, db.listItemAllocations.shoppingStopId));

  $$ListItemAllocationsTableProcessedTableManager get listItemAllocationsRefs {
    final manager =
        $$ListItemAllocationsTableTableManager($_db, $_db.listItemAllocations)
            .filter((f) => f.shoppingStopId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_listItemAllocationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ShoppingStopsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingStopsTable> {
  $$ShoppingStopsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isInitial => $composableBuilder(
      column: $table.isInitial, builder: (column) => ColumnFilters(column));

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> listItemAllocationsRefs(
      Expression<bool> Function($$ListItemAllocationsTableFilterComposer f) f) {
    final $$ListItemAllocationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listItemAllocations,
        getReferencedColumn: (t) => t.shoppingStopId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemAllocationsTableFilterComposer(
              $db: $db,
              $table: $db.listItemAllocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ShoppingStopsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingStopsTable> {
  $$ShoppingStopsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isInitial => $composableBuilder(
      column: $table.isInitial, builder: (column) => ColumnOrderings(column));

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShoppingStopsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingStopsTable> {
  $$ShoppingStopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isInitial =>
      $composableBuilder(column: $table.isInitial, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> listItemAllocationsRefs<T extends Object>(
      Expression<T> Function($$ListItemAllocationsTableAnnotationComposer a)
          f) {
    final $$ListItemAllocationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.listItemAllocations,
            getReferencedColumn: (t) => t.shoppingStopId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ListItemAllocationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.listItemAllocations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ShoppingStopsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingStopsTable,
    ShoppingStop,
    $$ShoppingStopsTableFilterComposer,
    $$ShoppingStopsTableOrderingComposer,
    $$ShoppingStopsTableAnnotationComposer,
    $$ShoppingStopsTableCreateCompanionBuilder,
    $$ShoppingStopsTableUpdateCompanionBuilder,
    (ShoppingStop, $$ShoppingStopsTableReferences),
    ShoppingStop,
    PrefetchHooks Function({bool tripId, bool listItemAllocationsRefs})> {
  $$ShoppingStopsTableTableManager(_$AppDatabase db, $ShoppingStopsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingStopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingStopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingStopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tripId = const Value.absent(),
            Value<int> dayNumber = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isInitial = const Value.absent(),
          }) =>
              ShoppingStopsCompanion(
            id: id,
            tripId: tripId,
            dayNumber: dayNumber,
            name: name,
            isInitial: isInitial,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tripId,
            Value<int> dayNumber = const Value.absent(),
            required String name,
            Value<bool> isInitial = const Value.absent(),
          }) =>
              ShoppingStopsCompanion.insert(
            id: id,
            tripId: tripId,
            dayNumber: dayNumber,
            name: name,
            isInitial: isInitial,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ShoppingStopsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {tripId = false, listItemAllocationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (listItemAllocationsRefs) db.listItemAllocations
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable:
                        $$ShoppingStopsTableReferences._tripIdTable(db),
                    referencedColumn:
                        $$ShoppingStopsTableReferences._tripIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listItemAllocationsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ShoppingStopsTableReferences
                            ._listItemAllocationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShoppingStopsTableReferences(db, table, p0)
                                .listItemAllocationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.shoppingStopId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ShoppingStopsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShoppingStopsTable,
    ShoppingStop,
    $$ShoppingStopsTableFilterComposer,
    $$ShoppingStopsTableOrderingComposer,
    $$ShoppingStopsTableAnnotationComposer,
    $$ShoppingStopsTableCreateCompanionBuilder,
    $$ShoppingStopsTableUpdateCompanionBuilder,
    (ShoppingStop, $$ShoppingStopsTableReferences),
    ShoppingStop,
    PrefetchHooks Function({bool tripId, bool listItemAllocationsRefs})>;
typedef $$ListItemsTableCreateCompanionBuilder = ListItemsCompanion Function({
  Value<int> id,
  required int tripId,
  required String catalogId,
  Value<bool> isCustom,
  Value<String?> customName,
  Value<String?> customUnit,
  Value<String?> customDepartment,
  Value<bool> selected,
  Value<double> share,
  Value<double> calculatedQuantity,
  Value<int> calculatedPackages,
  Value<int?> overriddenPackages,
  Value<double?> customPackageSize,
  Value<CheckItemState> checkState,
  Value<bool> isAdopted,
});
typedef $$ListItemsTableUpdateCompanionBuilder = ListItemsCompanion Function({
  Value<int> id,
  Value<int> tripId,
  Value<String> catalogId,
  Value<bool> isCustom,
  Value<String?> customName,
  Value<String?> customUnit,
  Value<String?> customDepartment,
  Value<bool> selected,
  Value<double> share,
  Value<double> calculatedQuantity,
  Value<int> calculatedPackages,
  Value<int?> overriddenPackages,
  Value<double?> customPackageSize,
  Value<CheckItemState> checkState,
  Value<bool> isAdopted,
});

final class $$ListItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ListItemsTable, ListItem> {
  $$ListItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips
      .createAlias($_aliasNameGenerator(db.listItems.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id($_item.tripId));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ListItemAllocationsTable,
      List<ListItemAllocation>> _listItemAllocationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.listItemAllocations,
          aliasName: $_aliasNameGenerator(
              db.listItems.id, db.listItemAllocations.listItemId));

  $$ListItemAllocationsTableProcessedTableManager get listItemAllocationsRefs {
    final manager =
        $$ListItemAllocationsTableTableManager($_db, $_db.listItemAllocations)
            .filter((f) => f.listItemId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_listItemAllocationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get catalogId => $composableBuilder(
      column: $table.catalogId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customName => $composableBuilder(
      column: $table.customName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customUnit => $composableBuilder(
      column: $table.customUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customDepartment => $composableBuilder(
      column: $table.customDepartment,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get selected => $composableBuilder(
      column: $table.selected, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get share => $composableBuilder(
      column: $table.share, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get calculatedQuantity => $composableBuilder(
      column: $table.calculatedQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calculatedPackages => $composableBuilder(
      column: $table.calculatedPackages,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get overriddenPackages => $composableBuilder(
      column: $table.overriddenPackages,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customPackageSize => $composableBuilder(
      column: $table.customPackageSize,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CheckItemState, CheckItemState, String>
      get checkState => $composableBuilder(
          column: $table.checkState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isAdopted => $composableBuilder(
      column: $table.isAdopted, builder: (column) => ColumnFilters(column));

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> listItemAllocationsRefs(
      Expression<bool> Function($$ListItemAllocationsTableFilterComposer f) f) {
    final $$ListItemAllocationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.listItemAllocations,
        getReferencedColumn: (t) => t.listItemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemAllocationsTableFilterComposer(
              $db: $db,
              $table: $db.listItemAllocations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get catalogId => $composableBuilder(
      column: $table.catalogId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customName => $composableBuilder(
      column: $table.customName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customUnit => $composableBuilder(
      column: $table.customUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customDepartment => $composableBuilder(
      column: $table.customDepartment,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get selected => $composableBuilder(
      column: $table.selected, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get share => $composableBuilder(
      column: $table.share, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get calculatedQuantity => $composableBuilder(
      column: $table.calculatedQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calculatedPackages => $composableBuilder(
      column: $table.calculatedPackages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get overriddenPackages => $composableBuilder(
      column: $table.overriddenPackages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customPackageSize => $composableBuilder(
      column: $table.customPackageSize,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkState => $composableBuilder(
      column: $table.checkState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAdopted => $composableBuilder(
      column: $table.isAdopted, builder: (column) => ColumnOrderings(column));

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get catalogId =>
      $composableBuilder(column: $table.catalogId, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
      column: $table.customName, builder: (column) => column);

  GeneratedColumn<String> get customUnit => $composableBuilder(
      column: $table.customUnit, builder: (column) => column);

  GeneratedColumn<String> get customDepartment => $composableBuilder(
      column: $table.customDepartment, builder: (column) => column);

  GeneratedColumn<bool> get selected =>
      $composableBuilder(column: $table.selected, builder: (column) => column);

  GeneratedColumn<double> get share =>
      $composableBuilder(column: $table.share, builder: (column) => column);

  GeneratedColumn<double> get calculatedQuantity => $composableBuilder(
      column: $table.calculatedQuantity, builder: (column) => column);

  GeneratedColumn<int> get calculatedPackages => $composableBuilder(
      column: $table.calculatedPackages, builder: (column) => column);

  GeneratedColumn<int> get overriddenPackages => $composableBuilder(
      column: $table.overriddenPackages, builder: (column) => column);

  GeneratedColumn<double> get customPackageSize => $composableBuilder(
      column: $table.customPackageSize, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CheckItemState, String> get checkState =>
      $composableBuilder(
          column: $table.checkState, builder: (column) => column);

  GeneratedColumn<bool> get isAdopted =>
      $composableBuilder(column: $table.isAdopted, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> listItemAllocationsRefs<T extends Object>(
      Expression<T> Function($$ListItemAllocationsTableAnnotationComposer a)
          f) {
    final $$ListItemAllocationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.listItemAllocations,
            getReferencedColumn: (t) => t.listItemId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ListItemAllocationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.listItemAllocations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ListItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ListItemsTable,
    ListItem,
    $$ListItemsTableFilterComposer,
    $$ListItemsTableOrderingComposer,
    $$ListItemsTableAnnotationComposer,
    $$ListItemsTableCreateCompanionBuilder,
    $$ListItemsTableUpdateCompanionBuilder,
    (ListItem, $$ListItemsTableReferences),
    ListItem,
    PrefetchHooks Function({bool tripId, bool listItemAllocationsRefs})> {
  $$ListItemsTableTableManager(_$AppDatabase db, $ListItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tripId = const Value.absent(),
            Value<String> catalogId = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<String?> customName = const Value.absent(),
            Value<String?> customUnit = const Value.absent(),
            Value<String?> customDepartment = const Value.absent(),
            Value<bool> selected = const Value.absent(),
            Value<double> share = const Value.absent(),
            Value<double> calculatedQuantity = const Value.absent(),
            Value<int> calculatedPackages = const Value.absent(),
            Value<int?> overriddenPackages = const Value.absent(),
            Value<double?> customPackageSize = const Value.absent(),
            Value<CheckItemState> checkState = const Value.absent(),
            Value<bool> isAdopted = const Value.absent(),
          }) =>
              ListItemsCompanion(
            id: id,
            tripId: tripId,
            catalogId: catalogId,
            isCustom: isCustom,
            customName: customName,
            customUnit: customUnit,
            customDepartment: customDepartment,
            selected: selected,
            share: share,
            calculatedQuantity: calculatedQuantity,
            calculatedPackages: calculatedPackages,
            overriddenPackages: overriddenPackages,
            customPackageSize: customPackageSize,
            checkState: checkState,
            isAdopted: isAdopted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tripId,
            required String catalogId,
            Value<bool> isCustom = const Value.absent(),
            Value<String?> customName = const Value.absent(),
            Value<String?> customUnit = const Value.absent(),
            Value<String?> customDepartment = const Value.absent(),
            Value<bool> selected = const Value.absent(),
            Value<double> share = const Value.absent(),
            Value<double> calculatedQuantity = const Value.absent(),
            Value<int> calculatedPackages = const Value.absent(),
            Value<int?> overriddenPackages = const Value.absent(),
            Value<double?> customPackageSize = const Value.absent(),
            Value<CheckItemState> checkState = const Value.absent(),
            Value<bool> isAdopted = const Value.absent(),
          }) =>
              ListItemsCompanion.insert(
            id: id,
            tripId: tripId,
            catalogId: catalogId,
            isCustom: isCustom,
            customName: customName,
            customUnit: customUnit,
            customDepartment: customDepartment,
            selected: selected,
            share: share,
            calculatedQuantity: calculatedQuantity,
            calculatedPackages: calculatedPackages,
            overriddenPackages: overriddenPackages,
            customPackageSize: customPackageSize,
            checkState: checkState,
            isAdopted: isAdopted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ListItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {tripId = false, listItemAllocationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (listItemAllocationsRefs) db.listItemAllocations
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable:
                        $$ListItemsTableReferences._tripIdTable(db),
                    referencedColumn:
                        $$ListItemsTableReferences._tripIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listItemAllocationsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ListItemsTableReferences
                            ._listItemAllocationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ListItemsTableReferences(db, table, p0)
                                .listItemAllocationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.listItemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ListItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ListItemsTable,
    ListItem,
    $$ListItemsTableFilterComposer,
    $$ListItemsTableOrderingComposer,
    $$ListItemsTableAnnotationComposer,
    $$ListItemsTableCreateCompanionBuilder,
    $$ListItemsTableUpdateCompanionBuilder,
    (ListItem, $$ListItemsTableReferences),
    ListItem,
    PrefetchHooks Function({bool tripId, bool listItemAllocationsRefs})>;
typedef $$ListItemAllocationsTableCreateCompanionBuilder
    = ListItemAllocationsCompanion Function({
  Value<int> id,
  required int tripId,
  required int listItemId,
  required int shoppingStopId,
  required int allocatedPackages,
  Value<bool> isBought,
  Value<bool> isStored,
});
typedef $$ListItemAllocationsTableUpdateCompanionBuilder
    = ListItemAllocationsCompanion Function({
  Value<int> id,
  Value<int> tripId,
  Value<int> listItemId,
  Value<int> shoppingStopId,
  Value<int> allocatedPackages,
  Value<bool> isBought,
  Value<bool> isStored,
});

final class $$ListItemAllocationsTableReferences extends BaseReferences<
    _$AppDatabase, $ListItemAllocationsTable, ListItemAllocation> {
  $$ListItemAllocationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips.createAlias(
      $_aliasNameGenerator(db.listItemAllocations.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id($_item.tripId));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ListItemsTable _listItemIdTable(_$AppDatabase db) =>
      db.listItems.createAlias($_aliasNameGenerator(
          db.listItemAllocations.listItemId, db.listItems.id));

  $$ListItemsTableProcessedTableManager get listItemId {
    final manager = $$ListItemsTableTableManager($_db, $_db.listItems)
        .filter((f) => f.id($_item.listItemId));
    final item = $_typedResult.readTableOrNull(_listItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ShoppingStopsTable _shoppingStopIdTable(_$AppDatabase db) =>
      db.shoppingStops.createAlias($_aliasNameGenerator(
          db.listItemAllocations.shoppingStopId, db.shoppingStops.id));

  $$ShoppingStopsTableProcessedTableManager get shoppingStopId {
    final manager = $$ShoppingStopsTableTableManager($_db, $_db.shoppingStops)
        .filter((f) => f.id($_item.shoppingStopId));
    final item = $_typedResult.readTableOrNull(_shoppingStopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ListItemAllocationsTableFilterComposer
    extends Composer<_$AppDatabase, $ListItemAllocationsTable> {
  $$ListItemAllocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get allocatedPackages => $composableBuilder(
      column: $table.allocatedPackages,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBought => $composableBuilder(
      column: $table.isBought, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStored => $composableBuilder(
      column: $table.isStored, builder: (column) => ColumnFilters(column));

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ListItemsTableFilterComposer get listItemId {
    final $$ListItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listItemId,
        referencedTable: $db.listItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemsTableFilterComposer(
              $db: $db,
              $table: $db.listItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShoppingStopsTableFilterComposer get shoppingStopId {
    final $$ShoppingStopsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shoppingStopId,
        referencedTable: $db.shoppingStops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingStopsTableFilterComposer(
              $db: $db,
              $table: $db.shoppingStops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListItemAllocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListItemAllocationsTable> {
  $$ListItemAllocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get allocatedPackages => $composableBuilder(
      column: $table.allocatedPackages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBought => $composableBuilder(
      column: $table.isBought, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStored => $composableBuilder(
      column: $table.isStored, builder: (column) => ColumnOrderings(column));

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ListItemsTableOrderingComposer get listItemId {
    final $$ListItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listItemId,
        referencedTable: $db.listItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemsTableOrderingComposer(
              $db: $db,
              $table: $db.listItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShoppingStopsTableOrderingComposer get shoppingStopId {
    final $$ShoppingStopsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shoppingStopId,
        referencedTable: $db.shoppingStops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingStopsTableOrderingComposer(
              $db: $db,
              $table: $db.shoppingStops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListItemAllocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListItemAllocationsTable> {
  $$ListItemAllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get allocatedPackages => $composableBuilder(
      column: $table.allocatedPackages, builder: (column) => column);

  GeneratedColumn<bool> get isBought =>
      $composableBuilder(column: $table.isBought, builder: (column) => column);

  GeneratedColumn<bool> get isStored =>
      $composableBuilder(column: $table.isStored, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ListItemsTableAnnotationComposer get listItemId {
    final $$ListItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listItemId,
        referencedTable: $db.listItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ListItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.listItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShoppingStopsTableAnnotationComposer get shoppingStopId {
    final $$ShoppingStopsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shoppingStopId,
        referencedTable: $db.shoppingStops,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShoppingStopsTableAnnotationComposer(
              $db: $db,
              $table: $db.shoppingStops,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ListItemAllocationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ListItemAllocationsTable,
    ListItemAllocation,
    $$ListItemAllocationsTableFilterComposer,
    $$ListItemAllocationsTableOrderingComposer,
    $$ListItemAllocationsTableAnnotationComposer,
    $$ListItemAllocationsTableCreateCompanionBuilder,
    $$ListItemAllocationsTableUpdateCompanionBuilder,
    (ListItemAllocation, $$ListItemAllocationsTableReferences),
    ListItemAllocation,
    PrefetchHooks Function(
        {bool tripId, bool listItemId, bool shoppingStopId})> {
  $$ListItemAllocationsTableTableManager(
      _$AppDatabase db, $ListItemAllocationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListItemAllocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListItemAllocationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListItemAllocationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tripId = const Value.absent(),
            Value<int> listItemId = const Value.absent(),
            Value<int> shoppingStopId = const Value.absent(),
            Value<int> allocatedPackages = const Value.absent(),
            Value<bool> isBought = const Value.absent(),
            Value<bool> isStored = const Value.absent(),
          }) =>
              ListItemAllocationsCompanion(
            id: id,
            tripId: tripId,
            listItemId: listItemId,
            shoppingStopId: shoppingStopId,
            allocatedPackages: allocatedPackages,
            isBought: isBought,
            isStored: isStored,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tripId,
            required int listItemId,
            required int shoppingStopId,
            required int allocatedPackages,
            Value<bool> isBought = const Value.absent(),
            Value<bool> isStored = const Value.absent(),
          }) =>
              ListItemAllocationsCompanion.insert(
            id: id,
            tripId: tripId,
            listItemId: listItemId,
            shoppingStopId: shoppingStopId,
            allocatedPackages: allocatedPackages,
            isBought: isBought,
            isStored: isStored,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ListItemAllocationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {tripId = false, listItemId = false, shoppingStopId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable:
                        $$ListItemAllocationsTableReferences._tripIdTable(db),
                    referencedColumn: $$ListItemAllocationsTableReferences
                        ._tripIdTable(db)
                        .id,
                  ) as T;
                }
                if (listItemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.listItemId,
                    referencedTable: $$ListItemAllocationsTableReferences
                        ._listItemIdTable(db),
                    referencedColumn: $$ListItemAllocationsTableReferences
                        ._listItemIdTable(db)
                        .id,
                  ) as T;
                }
                if (shoppingStopId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.shoppingStopId,
                    referencedTable: $$ListItemAllocationsTableReferences
                        ._shoppingStopIdTable(db),
                    referencedColumn: $$ListItemAllocationsTableReferences
                        ._shoppingStopIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ListItemAllocationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ListItemAllocationsTable,
    ListItemAllocation,
    $$ListItemAllocationsTableFilterComposer,
    $$ListItemAllocationsTableOrderingComposer,
    $$ListItemAllocationsTableAnnotationComposer,
    $$ListItemAllocationsTableCreateCompanionBuilder,
    $$ListItemAllocationsTableUpdateCompanionBuilder,
    (ListItemAllocation, $$ListItemAllocationsTableReferences),
    ListItemAllocation,
    PrefetchHooks Function(
        {bool tripId, bool listItemId, bool shoppingStopId})>;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  required int tripId,
  required double amount,
  Value<String> currency,
  required ExpenseCategory category,
  Value<int?> paidByCrewMemberId,
  Value<bool> isPaidFromKitty,
  Value<String?> customSplit,
  Value<String?> note,
  Value<DateTime> createdAt,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<int> tripId,
  Value<double> amount,
  Value<String> currency,
  Value<ExpenseCategory> category,
  Value<int?> paidByCrewMemberId,
  Value<bool> isPaidFromKitty,
  Value<String?> customSplit,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips
      .createAlias($_aliasNameGenerator(db.expenses.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id($_item.tripId));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CrewMembersTable _paidByCrewMemberIdTable(_$AppDatabase db) =>
      db.crewMembers.createAlias($_aliasNameGenerator(
          db.expenses.paidByCrewMemberId, db.crewMembers.id));

  $$CrewMembersTableProcessedTableManager? get paidByCrewMemberId {
    if ($_item.paidByCrewMemberId == null) return null;
    final manager = $$CrewMembersTableTableManager($_db, $_db.crewMembers)
        .filter((f) => f.id($_item.paidByCrewMemberId!));
    final item = $_typedResult.readTableOrNull(_paidByCrewMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ExpenseCategory, ExpenseCategory, String>
      get category => $composableBuilder(
          column: $table.category,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isPaidFromKitty => $composableBuilder(
      column: $table.isPaidFromKitty,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customSplit => $composableBuilder(
      column: $table.customSplit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CrewMembersTableFilterComposer get paidByCrewMemberId {
    final $$CrewMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paidByCrewMemberId,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableFilterComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPaidFromKitty => $composableBuilder(
      column: $table.isPaidFromKitty,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customSplit => $composableBuilder(
      column: $table.customSplit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CrewMembersTableOrderingComposer get paidByCrewMemberId {
    final $$CrewMembersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paidByCrewMemberId,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableOrderingComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExpenseCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isPaidFromKitty => $composableBuilder(
      column: $table.isPaidFromKitty, builder: (column) => column);

  GeneratedColumn<String> get customSplit => $composableBuilder(
      column: $table.customSplit, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CrewMembersTableAnnotationComposer get paidByCrewMemberId {
    final $$CrewMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paidByCrewMemberId,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, $$ExpensesTableReferences),
    Expense,
    PrefetchHooks Function({bool tripId, bool paidByCrewMemberId})> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tripId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<ExpenseCategory> category = const Value.absent(),
            Value<int?> paidByCrewMemberId = const Value.absent(),
            Value<bool> isPaidFromKitty = const Value.absent(),
            Value<String?> customSplit = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            tripId: tripId,
            amount: amount,
            currency: currency,
            category: category,
            paidByCrewMemberId: paidByCrewMemberId,
            isPaidFromKitty: isPaidFromKitty,
            customSplit: customSplit,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tripId,
            required double amount,
            Value<String> currency = const Value.absent(),
            required ExpenseCategory category,
            Value<int?> paidByCrewMemberId = const Value.absent(),
            Value<bool> isPaidFromKitty = const Value.absent(),
            Value<String?> customSplit = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            tripId: tripId,
            amount: amount,
            currency: currency,
            category: category,
            paidByCrewMemberId: paidByCrewMemberId,
            isPaidFromKitty: isPaidFromKitty,
            customSplit: customSplit,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ExpensesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {tripId = false, paidByCrewMemberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable: $$ExpensesTableReferences._tripIdTable(db),
                    referencedColumn:
                        $$ExpensesTableReferences._tripIdTable(db).id,
                  ) as T;
                }
                if (paidByCrewMemberId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.paidByCrewMemberId,
                    referencedTable:
                        $$ExpensesTableReferences._paidByCrewMemberIdTable(db),
                    referencedColumn: $$ExpensesTableReferences
                        ._paidByCrewMemberIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, $$ExpensesTableReferences),
    Expense,
    PrefetchHooks Function({bool tripId, bool paidByCrewMemberId})>;
typedef $$KittyPaymentsTableCreateCompanionBuilder = KittyPaymentsCompanion
    Function({
  Value<int> id,
  required int tripId,
  required int crewMemberId,
  required double amount,
  Value<DateTime> paidAt,
});
typedef $$KittyPaymentsTableUpdateCompanionBuilder = KittyPaymentsCompanion
    Function({
  Value<int> id,
  Value<int> tripId,
  Value<int> crewMemberId,
  Value<double> amount,
  Value<DateTime> paidAt,
});

final class $$KittyPaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $KittyPaymentsTable, KittyPayment> {
  $$KittyPaymentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips
      .createAlias($_aliasNameGenerator(db.kittyPayments.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id($_item.tripId));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CrewMembersTable _crewMemberIdTable(_$AppDatabase db) =>
      db.crewMembers.createAlias($_aliasNameGenerator(
          db.kittyPayments.crewMemberId, db.crewMembers.id));

  $$CrewMembersTableProcessedTableManager get crewMemberId {
    final manager = $$CrewMembersTableTableManager($_db, $_db.crewMembers)
        .filter((f) => f.id($_item.crewMemberId));
    final item = $_typedResult.readTableOrNull(_crewMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$KittyPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $KittyPaymentsTable> {
  $$KittyPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnFilters(column));

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CrewMembersTableFilterComposer get crewMemberId {
    final $$CrewMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.crewMemberId,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableFilterComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KittyPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $KittyPaymentsTable> {
  $$KittyPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CrewMembersTableOrderingComposer get crewMemberId {
    final $$CrewMembersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.crewMemberId,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableOrderingComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KittyPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KittyPaymentsTable> {
  $$KittyPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CrewMembersTableAnnotationComposer get crewMemberId {
    final $$CrewMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.crewMemberId,
        referencedTable: $db.crewMembers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CrewMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.crewMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$KittyPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KittyPaymentsTable,
    KittyPayment,
    $$KittyPaymentsTableFilterComposer,
    $$KittyPaymentsTableOrderingComposer,
    $$KittyPaymentsTableAnnotationComposer,
    $$KittyPaymentsTableCreateCompanionBuilder,
    $$KittyPaymentsTableUpdateCompanionBuilder,
    (KittyPayment, $$KittyPaymentsTableReferences),
    KittyPayment,
    PrefetchHooks Function({bool tripId, bool crewMemberId})> {
  $$KittyPaymentsTableTableManager(_$AppDatabase db, $KittyPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KittyPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KittyPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KittyPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tripId = const Value.absent(),
            Value<int> crewMemberId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> paidAt = const Value.absent(),
          }) =>
              KittyPaymentsCompanion(
            id: id,
            tripId: tripId,
            crewMemberId: crewMemberId,
            amount: amount,
            paidAt: paidAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tripId,
            required int crewMemberId,
            required double amount,
            Value<DateTime> paidAt = const Value.absent(),
          }) =>
              KittyPaymentsCompanion.insert(
            id: id,
            tripId: tripId,
            crewMemberId: crewMemberId,
            amount: amount,
            paidAt: paidAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$KittyPaymentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({tripId = false, crewMemberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable:
                        $$KittyPaymentsTableReferences._tripIdTable(db),
                    referencedColumn:
                        $$KittyPaymentsTableReferences._tripIdTable(db).id,
                  ) as T;
                }
                if (crewMemberId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.crewMemberId,
                    referencedTable:
                        $$KittyPaymentsTableReferences._crewMemberIdTable(db),
                    referencedColumn: $$KittyPaymentsTableReferences
                        ._crewMemberIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$KittyPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KittyPaymentsTable,
    KittyPayment,
    $$KittyPaymentsTableFilterComposer,
    $$KittyPaymentsTableOrderingComposer,
    $$KittyPaymentsTableAnnotationComposer,
    $$KittyPaymentsTableCreateCompanionBuilder,
    $$KittyPaymentsTableUpdateCompanionBuilder,
    (KittyPayment, $$KittyPaymentsTableReferences),
    KittyPayment,
    PrefetchHooks Function({bool tripId, bool crewMemberId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$TripDaysTableTableManager get tripDays =>
      $$TripDaysTableTableManager(_db, _db.tripDays);
  $$CrewMembersTableTableManager get crewMembers =>
      $$CrewMembersTableTableManager(_db, _db.crewMembers);
  $$ShoppingStopsTableTableManager get shoppingStops =>
      $$ShoppingStopsTableTableManager(_db, _db.shoppingStops);
  $$ListItemsTableTableManager get listItems =>
      $$ListItemsTableTableManager(_db, _db.listItems);
  $$ListItemAllocationsTableTableManager get listItemAllocations =>
      $$ListItemAllocationsTableTableManager(_db, _db.listItemAllocations);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$KittyPaymentsTableTableManager get kittyPayments =>
      $$KittyPaymentsTableTableManager(_db, _db.kittyPayments);
}
