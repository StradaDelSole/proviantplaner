import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/backup_coordinator.dart';
import 'package:proviantplaner/core/services/hullq_auth_service.dart';
import 'package:proviantplaner/core/services/hullq_backup_service.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';

void main() {
  late AppDatabase db;
  late MockHullqAuthService authService;
  late MockHullqBackupService backupService;
  late Directory tempDir;
  late ReceiptFileService receiptFileService;
  late BackupCoordinator coordinator;

  Uint8List createDummyJpeg(int width, int height, img.ColorRgb8 color) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: color);
    return Uint8List.fromList(img.encodeJpg(image));
  }

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    authService = MockHullqAuthService();
    // Simulate active logged in member
    await authService.loginWithEmail('test@example.com', newsletterOptIn: false);

    backupService = MockHullqBackupService();
    tempDir = await Directory.systemTemp.createTemp('backup_coord_v3_test_');
    receiptFileService = ReceiptFileService(docsDirProvider: () async => tempDir);

    coordinator = BackupCoordinator(
      db: db,
      backupService: backupService,
      authService: authService,
      receiptFileService: receiptFileService,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('RECEIPT1: createBackup exports version 3 with Base64 image payload', () async {
    final tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Backup V3 Törn',
        startDate: DateTime(2026, 8, 1),
      ),
    );

    final memberId = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Max',
        isChild: const Value(false),
        isVegetarian: const Value(false),
        isNonDrinker: const Value(false),
      ),
    );

    final expenseId = await db.expenseDao.addExpense(
      ExpensesCompanion.insert(
        tripId: tripId,
        amount: 32.50,
        currency: const Value('EUR'),
        category: ExpenseCategory.provisions,
        paidByCrewMemberId: Value(memberId),
        isPaidFromKitty: const Value(false),
        note: const Value('Supermarkt'),
      ),
    );

    final photo = createDummyJpeg(100, 100, img.ColorRgb8(11, 22, 33));
    final savedFile = await receiptFileService.saveReceiptImage(
      tripId: tripId,
      expenseId: expenseId,
      imageBytes: photo,
      preferredFileName: 'receipt_v3.jpg',
    );

    await db.expenseDao.addReceipt(
      ExpenseReceiptsCompanion.insert(
        tripId: tripId,
        expenseId: expenseId,
        filePath: savedFile.relativePath,
        fileName: savedFile.fileName,
        byteSize: Value(savedFile.byteSize),
        mimeType: const Value('image/jpeg'),
      ),
    );

    final success = await coordinator.createBackup();
    expect(success, isTrue);

    final backupJsonStr = await backupService.restoreData();
    expect(backupJsonStr, isNotNull);

    final decoded = jsonDecode(backupJsonStr!) as Map<String, dynamic>;
    expect(decoded['version'], equals(3));
    expect(decoded['trips'], isNotEmpty);

    final tripData = (decoded['trips'] as List<dynamic>).first as Map<String, dynamic>;
    final receipts = tripData['receipts'] as List<dynamic>;
    expect(receipts.length, 1);

    final rMap = receipts.first as Map<String, dynamic>;
    expect(rMap['fileName'], 'receipt_v3.jpg');
    expect(rMap['byteSize'], greaterThan(0));
    expect(rMap['imageBase64'], isNotNull);

    final restoredBytes = base64Decode(rMap['imageBase64'] as String);
    expect(restoredBytes.length, savedFile.byteSize);
  });

  test('RECEIPT1: restoreBackup restores receipts and re-creates files on disk with remapped IDs', () async {
    // 1. Create a trip with expense & receipt in first DB
    final tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Origin Trip',
        startDate: DateTime(2026, 8, 1),
      ),
    );
    final memberId = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Lisa',
        isChild: const Value(false),
        isVegetarian: const Value(false),
        isNonDrinker: const Value(false),
      ),
    );
    final expenseId = await db.expenseDao.addExpense(
      ExpensesCompanion.insert(
        tripId: tripId,
        amount: 55.0,
        currency: const Value('EUR'),
        category: ExpenseCategory.marinaBerth,
        paidByCrewMemberId: Value(memberId),
        isPaidFromKitty: const Value(false),
      ),
    );

    final photo = createDummyJpeg(120, 120, img.ColorRgb8(50, 100, 150));
    final savedFile = await receiptFileService.saveReceiptImage(
      tripId: tripId,
      expenseId: expenseId,
      imageBytes: photo,
      preferredFileName: 'marina_receipt.jpg',
    );
    await db.expenseDao.addReceipt(
      ExpenseReceiptsCompanion.insert(
        tripId: tripId,
        expenseId: expenseId,
        filePath: savedFile.relativePath,
        fileName: savedFile.fileName,
        byteSize: Value(savedFile.byteSize),
        mimeType: const Value('image/jpeg'),
      ),
    );

    await coordinator.createBackup();

    // 2. Setup a second fresh database and temp docs directory
    final db2 = AppDatabase(NativeDatabase.memory());
    final tempDir2 = await Directory.systemTemp.createTemp('backup_restore_target_');
    final receiptFileService2 = ReceiptFileService(docsDirProvider: () async => tempDir2);

    final coordinator2 = BackupCoordinator(
      db: db2,
      backupService: backupService,
      authService: authService,
      receiptFileService: receiptFileService2,
    );

    final restoreSuccess = await coordinator2.restoreBackup();
    expect(restoreSuccess, isTrue);

    // Verify DB2 content
    final allTrips = await db2.tripDao.getAllTrips();
    expect(allTrips.length, 1);
    final restoredTrip = allTrips.first;

    final allExpenses = await db2.expenseDao.getExpensesForTrip(restoredTrip.id);
    expect(allExpenses.length, 1);
    final restoredExpense = allExpenses.first;

    final restoredReceipts = await db2.expenseDao.getReceiptsForExpense(restoredExpense.id);
    expect(restoredReceipts.length, 1);
    expect(restoredReceipts.first.fileName, 'marina_receipt.jpg');
    expect(restoredReceipts.first.tripId, restoredTrip.id);
    expect(restoredReceipts.first.expenseId, restoredExpense.id);

    // Verify physical file was written to disk2
    final fileBytes = await receiptFileService2.readReceiptBytes(restoredReceipts.first.filePath);
    expect(fileBytes, isNotNull);
    expect(fileBytes!.length, savedFile.byteSize);

    await db2.close();
    await tempDir2.delete(recursive: true);
  });

  test('RECEIPT1: restoreBackup handles older v2 backup payload without receipts seamlessly', () async {
    // Construct legacy v2 backup JSON without receipts
    final legacyV2Payload = jsonEncode({
      'version': 2,
      'exportedAt': '2026-10-06T12:00:00.000Z',
      'boatProfiles': [],
      'trips': [
        {
          'trip': {
            'id': 100,
            'name': 'Legacy V2 Trip',
            'startDate': '2026-07-01T00:00:00.000Z',
            'currency': 'EUR',
          },
          'days': [],
          'crew': [
            {
              'id': 200,
              'name': 'Alt-Mitglied',
              'isChild': false,
              'isVegetarian': false,
              'isNonDrinker': false,
            }
          ],
          'stops': [],
          'items': [],
          'allocations': [],
          'expenses': [
            {
              'id': 300,
              'amount': 25.0,
              'currency': 'EUR',
              'category': 'provisions',
              'paidByCrewMemberId': 200,
              'isPaidFromKitty': false,
            }
          ],
          'payments': [],
          // Notice: no 'receipts' field here
        }
      ],
    });

    await backupService.backupData(legacyV2Payload);

    final restoreSuccess = await coordinator.restoreBackup();
    expect(restoreSuccess, isTrue);

    final allTrips = await db.tripDao.getAllTrips();
    expect(allTrips.length, 1);
    expect(allTrips.first.name, 'Legacy V2 Trip');

    final allExpenses = await db.expenseDao.getExpensesForTrip(allTrips.first.id);
    expect(allExpenses.length, 1);

    final receipts = await db.expenseDao.getReceiptsForExpense(allExpenses.first.id);
    expect(receipts, isEmpty);
  });
}
