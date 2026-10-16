/// Mengenfaktoren, Profile und Rundungsregeln (data/quantities_v0.4.json).
/// Strikte Typisierung mit Enums gemäß GEMINI.md v0.4 Programmierregel 1.
library;

/// Appetit-Einstufung der Crew.
enum CrewAppetite {
  light('light'),
  normal('normal'),
  hearty('hearty'),
  hungrySailors('hungry_sailors');

  final String rawValue;
  const CrewAppetite(this.rawValue);

  static CrewAppetite fromString(String val) {
    for (final a in values) {
      if (a.rawValue == val) return a;
    }
    throw FormatException('quantities_v0.4.json: Unbekannter Appetit: "$val"');
  }
}

/// Trinkverhalten der Crew für alkoholische Getränke.
enum CrewDrinking {
  relaxed('relaxed'),
  normal('normal'),
  festive('festive');

  final String rawValue;
  const CrewDrinking(this.rawValue);

  static CrewDrinking fromString(String val) {
    for (final d in values) {
      if (d.rawValue == val) return d;
    }
    throw FormatException('quantities_v0.4.json: Unbekanntes Trinklevel: "$val"');
  }
}

/// Individuelles Ess-Profil pro Person.
enum EatProfileLevel {
  small('small'),
  normal('normal'),
  big('big');

  final String rawValue;
  const EatProfileLevel(this.rawValue);

  static EatProfileLevel fromString(String val) {
    for (final e in values) {
      if (e.rawValue == val) return e;
    }
    throw FormatException('quantities_v0.4.json: Unbekanntes Ess-Profil: "$val"');
  }
}

/// Individuelles Trink-Profil pro Person.
enum DrinkProfileLevel {
  none('none'),
  little('little'),
  normal('normal'),
  aLot('a_lot');

  final String rawValue;
  const DrinkProfileLevel(this.rawValue);

  static DrinkProfileLevel fromString(String val) {
    for (final d in values) {
      if (d.rawValue == val) return d;
    }
    throw FormatException('quantities_v0.4.json: Unbekanntes Trink-Profil: "$val"');
  }
}

/// Wasserbedarfswerte für ein Revier.
class WaterRange {
  final double min;
  final double max;
  final double defaultValue;

  const WaterRange({
    required this.min,
    required this.max,
    required this.defaultValue,
  });

  factory WaterRange.fromJson(Map<String, dynamic> json) {
    return WaterRange(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      defaultValue: (json['default'] as num).toDouble(),
    );
  }
}

/// Urlaubszuschlag für Snacks und Genussmittel (Snacks, Softdrinks, Bier, Wein).
class HolidayUpliftInfo {
  final double defaultValue;
  final List<String> appliesToGroups;
  final String? note;

  const HolidayUpliftInfo({
    required this.defaultValue,
    required this.appliesToGroups,
    this.note,
  });

  factory HolidayUpliftInfo.fromJson(Map<String, dynamic> json) {
    return HolidayUpliftInfo(
      defaultValue: (json['default'] as num? ?? 1.2).toDouble(),
      appliesToGroups: (json['applies_to_groups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      note: json['note'] as String?,
    );
  }
}

/// Faktoren aus quantities_v0.4.json.
class QuantitiesFactors {
  final int freshFirstDays;
  final HolidayUpliftInfo holidaySnackDrinkUplift;
  final double child;

  const QuantitiesFactors({
    required this.freshFirstDays,
    required this.holidaySnackDrinkUplift,
    required this.child,
  });

  factory QuantitiesFactors.fromJson(Map<String, dynamic> json) {
    final holidayJson = json['holiday_snack_drink_uplift'];
    if (holidayJson == null || holidayJson is! Map<String, dynamic>) {
      throw const FormatException('quantities_v0.4.json: Fehlendes holiday_snack_drink_uplift');
    }

    return QuantitiesFactors(
      freshFirstDays: json['fresh_first_days'] as int? ?? 3,
      holidaySnackDrinkUplift: HolidayUpliftInfo.fromJson(holidayJson),
      child: (json['child'] as num? ?? 0.6).toDouble(),
    );
  }
}

/// Gesamtmodell für Mengen, Faktoren und Rundungsregeln (data/quantities_v0.4.json).
class QuantitiesData {
  final String version;
  final Map<String, WaterRange> waterLiters;
  final QuantitiesFactors factors;
  final Map<EatProfileLevel, double> eatProfiles;
  final Map<DrinkProfileLevel, double> drinkProfiles;
  final Map<CrewAppetite, double> appetiteOptions;
  final double reserveUplift;
  final Map<CrewDrinking, double> drinkingOptions;
  final int durableMinShelfLifeDays;
  final double freshMaxOvershootFraction;
  final String groupBalancingDescription;
  final double waterTankReserveLitersPerPerson;

  const QuantitiesData({
    required this.version,
    required this.waterLiters,
    required this.factors,
    required this.eatProfiles,
    required this.drinkProfiles,
    required this.appetiteOptions,
    required this.reserveUplift,
    required this.drinkingOptions,
    required this.durableMinShelfLifeDays,
    required this.freshMaxOvershootFraction,
    required this.groupBalancingDescription,
    this.waterTankReserveLitersPerPerson = 1.5,
  });

  factory QuantitiesData.fromJson(Map<String, dynamic> json) {
    final waterMap = <String, WaterRange>{};
    if (json['water_liters_per_person_day'] is Map) {
      final w = json['water_liters_per_person_day'] as Map<String, dynamic>;
      w.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          waterMap[key] = WaterRange.fromJson(val);
        }
      });
    }

    final factorsJson = json['factors'];
    if (factorsJson == null || factorsJson is! Map<String, dynamic>) {
      throw const FormatException('quantities_v0.4.json: Fehlendes factors-Objekt');
    }
    final factors = QuantitiesFactors.fromJson(factorsJson);

    // Profile: eat
    final eatMap = <EatProfileLevel, double>{};
    if (json['profiles']?['eat'] is Map) {
      final m = json['profiles']['eat'] as Map<String, dynamic>;
      m.forEach((k, v) {
        if (v is num) {
          try {
            eatMap[EatProfileLevel.fromString(k)] = v.toDouble();
          } catch (_) {}
        }
      });
    }

    // Profile: drink
    final drinkMap = <DrinkProfileLevel, double>{};
    if (json['profiles']?['drink'] is Map) {
      final m = json['profiles']['drink'] as Map<String, dynamic>;
      m.forEach((k, v) {
        if (v is num) {
          try {
            drinkMap[DrinkProfileLevel.fromString(k)] = v.toDouble();
          } catch (_) {}
        }
      });
    }

    // Crew questions: appetite
    final appetiteMap = <CrewAppetite, double>{};
    if (json['crew_questions']?['appetite']?['options'] is Map) {
      final m = json['crew_questions']['appetite']['options'] as Map<String, dynamic>;
      m.forEach((k, v) {
        if (v is num) {
          try {
            appetiteMap[CrewAppetite.fromString(k)] = v.toDouble();
          } catch (_) {}
        }
      });
    }

    // Crew questions: reserve
    final reserveUplift = (json['crew_questions']?['reserve']?['uplift'] as num? ?? 0.1).toDouble();

    // Crew questions: drinking
    final drinkingMap = <CrewDrinking, double>{};
    if (json['crew_questions']?['drinking']?['options'] is Map) {
      final m = json['crew_questions']['drinking']['options'] as Map<String, dynamic>;
      m.forEach((k, v) {
        if (v is num) {
          try {
            drinkingMap[CrewDrinking.fromString(k)] = v.toDouble();
          } catch (_) {}
        }
      });
    }

    // Rounding
    final rounding = json['rounding'] as Map<String, dynamic>? ?? {};
    final durableDays = rounding['durable_min_shelf_life_days'] as int? ?? 14;
    final freshMaxOvershoot = (rounding['fresh_max_overshoot_pack_fraction'] as num? ?? 0.25).toDouble();
    final balancingDesc = rounding['group_balancing'] as String? ?? '';

    // Water tank
    final waterTankJson = json['water_tank'] as Map<String, dynamic>?;
    final waterTankReserve = (waterTankJson?['reserve_liters_per_person'] as num? ?? 1.5).toDouble();

    return QuantitiesData(
      version: json['version'] as String? ?? '0.6',
      waterLiters: waterMap,
      factors: factors,
      eatProfiles: eatMap,
      drinkProfiles: drinkMap,
      appetiteOptions: appetiteMap,
      reserveUplift: reserveUplift,
      drinkingOptions: drinkingMap,
      durableMinShelfLifeDays: durableDays,
      freshMaxOvershootFraction: freshMaxOvershoot,
      groupBalancingDescription: balancingDesc,
      waterTankReserveLitersPerPerson: waterTankReserve,
    );
  }
}
