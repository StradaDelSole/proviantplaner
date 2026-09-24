/// Mengenfaktoren, Profile und Rundungsregeln (data/quantities_v0.3.json).
library;

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

class QuantitiesData {
  final String version;
  final Map<String, WaterRange> waterLiters;
  final double childFactor;
  final int freshFirstDays;
  final double holidayUplift;
  final Map<String, double> eatProfiles;
  final Map<String, double> drinkProfiles;
  final Map<String, double> appetiteOptions;
  final double reserveUplift;
  final Map<String, double> drinkingOptions;
  final int durableMinShelfLifeDays;
  final double freshMaxOvershootFraction;

  const QuantitiesData({
    required this.version,
    required this.waterLiters,
    required this.childFactor,
    required this.freshFirstDays,
    required this.holidayUplift,
    required this.eatProfiles,
    required this.drinkProfiles,
    required this.appetiteOptions,
    required this.reserveUplift,
    required this.drinkingOptions,
    required this.durableMinShelfLifeDays,
    required this.freshMaxOvershootFraction,
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

    final factors = json['factors'] as Map<String, dynamic>? ?? {};
    final child = (factors['child'] as num?)?.toDouble() ?? 0.6;
    final freshDays = factors['fresh_first_days'] as int? ?? 3;
    final holiday = (factors['holiday_snack_drink_uplift']?['default'] as num?)?.toDouble() ?? 1.2;

    final profiles = json['profiles'] as Map<String, dynamic>? ?? {};
    final eatP = <String, double>{
      'small': (profiles['eat']?['small'] as num?)?.toDouble() ?? 0.8,
      'normal': (profiles['eat']?['normal'] as num?)?.toDouble() ?? 1.0,
      'big': (profiles['eat']?['big'] as num?)?.toDouble() ?? 1.25,
    };
    final drinkP = <String, double>{
      'none': (profiles['drink']?['none'] as num?)?.toDouble() ?? 0.0,
      'little': (profiles['drink']?['little'] as num?)?.toDouble() ?? 0.5,
      'normal': (profiles['drink']?['normal'] as num?)?.toDouble() ?? 1.0,
      'a_lot': (profiles['drink']?['a_lot'] as num?)?.toDouble() ?? 1.75,
    };

    final crewQ = json['crew_questions'] as Map<String, dynamic>? ?? {};
    final appetiteOpts = <String, double>{};
    if (crewQ['appetite']?['options'] is Map) {
      (crewQ['appetite']['options'] as Map<String, dynamic>).forEach((k, v) {
        appetiteOpts[k] = (v as num).toDouble();
      });
    }

    final reserveUplift = (crewQ['reserve']?['uplift'] as num?)?.toDouble() ?? 0.1;

    final drinkOpts = <String, double>{};
    if (crewQ['drinking']?['options'] is Map) {
      (crewQ['drinking']['options'] as Map<String, dynamic>).forEach((k, v) {
        drinkOpts[k] = (v as num).toDouble();
      });
    }

    final rounding = json['rounding'] as Map<String, dynamic>? ?? {};
    final durableShelf = rounding['durable_min_shelf_life_days'] as int? ?? 14;
    final freshOvershoot = (rounding['fresh_max_overshoot_pack_fraction'] as num?)?.toDouble() ?? 0.25;

    return QuantitiesData(
      version: json['version'] as String? ?? '0.3',
      waterLiters: waterMap,
      childFactor: child,
      freshFirstDays: freshDays,
      holidayUplift: holiday,
      eatProfiles: eatP,
      drinkProfiles: drinkP,
      appetiteOptions: appetiteOpts,
      reserveUplift: reserveUplift,
      drinkingOptions: drinkOpts,
      durableMinShelfLifeDays: durableShelf,
      freshMaxOvershootFraction: freshOvershoot,
    );
  }

  double getWaterLitersForRegion(String? region) {
    if (region == null) return 2.0;
    final reg = region.toLowerCase();
    if (reg.contains('mediterranean') || reg.contains('mittelmeer')) {
      return waterLiters['mediterranean_summer']?.defaultValue ?? 2.5;
    } else if (reg.contains('hot') || reg.contains('remote') || reg.contains('karibik') || reg.contains('tropen')) {
      return waterLiters['hot_or_remote']?.defaultValue ?? 3.5;
    }
    return waterLiters['temperate']?.defaultValue ?? 2.0;
  }
}
