import 'package:drift/drift.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/shopping_list/domain/models/quantities_models.dart';
import 'package:proviantplaner/features/trip/domain/models/trip_phase.dart';

/// Drift TypeConverter für CrewAppetite
class CrewAppetiteConverter extends TypeConverter<CrewAppetite, String> {
  const CrewAppetiteConverter();
  @override
  CrewAppetite fromSql(String fromDb) => CrewAppetite.fromString(fromDb);
  @override
  String toSql(CrewAppetite value) => value.rawValue;
}

/// Drift TypeConverter für CrewDrinking
class CrewDrinkingConverter extends TypeConverter<CrewDrinking, String> {
  const CrewDrinkingConverter();
  @override
  CrewDrinking fromSql(String fromDb) => CrewDrinking.fromString(fromDb);
  @override
  String toSql(CrewDrinking value) => value.rawValue;
}

/// Drift TypeConverter für TripPhase
class TripPhaseConverter extends TypeConverter<TripPhase, String> {
  const TripPhaseConverter();
  @override
  TripPhase fromSql(String fromDb) => TripPhase.fromString(fromDb);
  @override
  String toSql(TripPhase value) => value.rawValue;
}

/// Drift TypeConverter für KittyModel
class KittyModelConverter extends TypeConverter<KittyModel, String> {
  const KittyModelConverter();
  @override
  KittyModel fromSql(String fromDb) => KittyModel.fromString(fromDb);
  @override
  String toSql(KittyModel value) => value.rawValue;
}

/// Drift TypeConverter für ExpenseCategory
class ExpenseCategoryConverter extends TypeConverter<ExpenseCategory, String> {
  const ExpenseCategoryConverter();
  @override
  ExpenseCategory fromSql(String fromDb) => ExpenseCategory.fromString(fromDb);
  @override
  String toSql(ExpenseCategory value) => value.rawValue;
}

/// Zustand einer Prüflisten-Position (FEEDBACK_R1 Punkt 6).
enum CheckItemState {
  available('vorhanden'),
  missing('fehlt'),
  restock('nachkaufen');

  final String rawValue;
  const CheckItemState(this.rawValue);

  static CheckItemState fromString(String? val) {
    if (val == null) return CheckItemState.available;
    for (final s in values) {
      if (s.rawValue == val) return s;
    }
    throw FormatException('Unbekannter CheckItemState: "$val"');
  }
}

/// Drift TypeConverter für CheckItemState
class CheckItemStateConverter extends TypeConverter<CheckItemState, String> {
  const CheckItemStateConverter();
  @override
  CheckItemState fromSql(String fromDb) => CheckItemState.fromString(fromDb);
  @override
  String toSql(CheckItemState value) => value.rawValue;
}

/// 0. BoatProfile: Wiederverwendbare Bootsprofile mit Snapshot-Semantik (PIVOT3-A)
class BoatProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get fridgeCapacity => integer().withDefault(const Constant(100))();
  BoolColumn get hasFreezer => boolean().withDefault(const Constant(false))();
  IntColumn get freezerCapacity => integer().withDefault(const Constant(0))();
  IntColumn get waterTankLiters => integer().withDefault(const Constant(0))();
  BoolColumn get isWaterTankDrinkable => boolean().withDefault(const Constant(false))();
  BoolColumn get hasWatermaker => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 1. Trip: Törn-Stammdaten, Phasen, Crew-Fragen, Einstellungen
class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get daysCount => integer().withDefault(const Constant(7))();
  TextColumn get region => text().withDefault(const Constant('mediterranean'))();
  TextColumn get climate => text().withDefault(const Constant('warm'))();
  BoolColumn get isCharter => boolean().withDefault(const Constant(true))();

  // PIVOT3-A: Bootsprofil-Referenz und Identitäts-Snapshots
  IntColumn get boatProfileId => integer().nullable().references(BoatProfiles, #id, onDelete: KeyAction.setNull)();
  TextColumn get boatName => text().nullable()();
  TextColumn get boatManufacturer => text().nullable()();
  TextColumn get boatModel => text().nullable()();

  // Snapshot-Werte der Bootskapazitäten
  TextColumn get boatType => text().withDefault(const Constant('mono'))();
  IntColumn get fridgeCapacity => integer().withDefault(const Constant(100))();
  BoolColumn get hasFreezer => boolean().withDefault(const Constant(false))();
  IntColumn get freezerCapacity => integer().withDefault(const Constant(0))();
  IntColumn get waterTankLiters => integer().withDefault(const Constant(0))();
  BoolColumn get isWaterTankDrinkable => boolean().withDefault(const Constant(false))();
  BoolColumn get hasWatermaker => boolean().withDefault(const Constant(false))();

  // Crew-Fragen (Appetit, Reserve, Trinken)
  TextColumn get appetite => text().map(const CrewAppetiteConverter()).withDefault(const Constant('normal'))();
  TextColumn get reserveDays => text().withDefault(const Constant('few_days'))();
  TextColumn get drinkingHabit => text().map(const CrewDrinkingConverter()).withDefault(const Constant('normal'))();

  BoolColumn get hasStorageChecklist => boolean().withDefault(const Constant(true))();
  TextColumn get phase => text().map(const TripPhaseConverter()).withDefault(const Constant('plan'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  TextColumn get kittyModel => text().map(const KittyModelConverter()).withDefault(const Constant('shared_kitty'))();
  IntColumn get treasurerMemberId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 2. TripDay: Törnverlauf, Restaurant-Schalter, Tagestyp, Hafenname
class TripDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayNumber => integer()(); // 1-basiert (Tag 1..N)
  BoolColumn get lunchRestaurant => boolean().withDefault(const Constant(false))();
  BoolColumn get dinnerRestaurant => boolean().withDefault(const Constant(false))();
  TextColumn get dayType => text().nullable()(); // marina, hafen, ankerbucht, ueberfahrt
  TextColumn get portName => text().nullable()(); // reine Info
}

/// 3. CrewMember: Crew-Mitglieder, Konsumprofil, Beteiligungen, Skipper frei
class CrewMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isChild => boolean().withDefault(const Constant(false))();
  BoolColumn get isVegetarian => boolean().withDefault(const Constant(false))();
  BoolColumn get isNonDrinker => boolean().withDefault(const Constant(false))();
  TextColumn get customEatLevel => text().nullable()(); // optional: low, normal, high
  TextColumn get customDrinkLevel => text().nullable()(); // optional: low, normal, high
  TextColumn get categoryParticipation => text().withDefault(const Constant('{"all": true}'))(); // JSON
  BoolColumn get isSkipperFree => boolean().withDefault(const Constant(false))();
  TextColumn get skipperFreeScope => text().nullable()(); // all, exclude_food
  TextColumn get iban => text().nullable()(); // Zahlungsdaten (FB1-A)
  TextColumn get paypalLink => text().nullable()();
  TextColumn get revolutLink => text().nullable()();
}

/// 4. ShoppingStop: Einkaufsstopps (erster Stopp automatisch)
class ShoppingStops extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayNumber => integer().withDefault(const Constant(1))();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isInitial => boolean().withDefault(const Constant(false))();
}

/// 5. ListItem: Position in der Vorratsliste
class ListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get catalogId => text()(); // ID aus Katalog oder eigene ID
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get customName => text().nullable()();
  TextColumn get customUnit => text().nullable()();
  TextColumn get customDepartment => text().nullable()();
  BoolColumn get selected => boolean().withDefault(const Constant(true))();
  RealColumn get share => real().withDefault(const Constant(1.0))();
  RealColumn get calculatedQuantity => real().withDefault(const Constant(0.0))();
  IntColumn get calculatedPackages => integer().withDefault(const Constant(1))();
  IntColumn get overriddenPackages => integer().nullable()(); // überschriebene Packungszahl oder null
  RealColumn get customPackageSize => real().nullable()(); // gemerkte Packungsgröße
  TextColumn get checkState => text().map(const CheckItemStateConverter()).withDefault(const Constant('vorhanden'))();
  BoolColumn get isAdopted => boolean().withDefault(const Constant(false))(); // FB1-B: Übernommen auf Vorratsliste
}

/// 6. ListItemAllocation: Zuordnung von Teilmengen eines ListItem zu einem ShoppingStop
class ListItemAllocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get listItemId => integer().references(ListItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get shoppingStopId => integer().references(ShoppingStops, #id, onDelete: KeyAction.cascade)();
  IntColumn get allocatedPackages => integer()(); // Anzahl zugeordneter Packungen
  BoolColumn get isBought => boolean().withDefault(const Constant(false))();
  BoolColumn get isStored => boolean().withDefault(const Constant(false))();
}

/// 7. Expense: Ausgaben für die Bordkasse
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  TextColumn get category => text().map(const ExpenseCategoryConverter())();
  IntColumn get paidByCrewMemberId => integer().nullable().references(CrewMembers, #id, onDelete: KeyAction.setNull)();
  BoolColumn get isPaidFromKitty => boolean().withDefault(const Constant(false))();
  TextColumn get customSplit => text().nullable()(); // JSON
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 8. KittyPayment: Einzahlungen in die gemeinsame Bordkasse
class KittyPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get crewMemberId => integer().references(CrewMembers, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
}