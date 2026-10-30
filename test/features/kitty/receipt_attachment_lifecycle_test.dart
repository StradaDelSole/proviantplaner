import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/database/daos.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/domain/models/receipt_models.dart';
import 'package:proviantplaner/features/shopping_list/data/catalog_repository.dart';
import 'package:proviantplaner/features/trip/data/trip_service.dart';

/// Test-Wrapper für [ExpenseDao] zur gezielten DB-Fehler-Injektion (R2).
class _FaultyExpenseDao extends ExpenseDao {
  bool failNextAddReceipt = false;
  bool failNextDeleteReceipt = false;
  bool failNextDeleteExpense = false;
  bool failNextAddExpense = false;

  _FaultyExpenseDao(super.db);

  @override
  Future<int> addReceipt(ExpenseReceiptsCompanion receipt) async {
    if (failNextAddReceipt) {
      failNextAddReceipt = false;
      throw StateError('Simulated DB failure in addReceipt');
    }
    return super.addReceipt(receipt);
  }

  @override
  Future<int> deleteReceipt(int id) async {
    if (failNextDeleteReceipt) {
      failNextDeleteReceipt = false;
      throw StateError('Simulated DB failure in deleteReceipt');
    }
    return super.deleteReceipt(id);
  }

  @override
  Future<int> deleteExpense(int id) async {
    if (failNextDeleteExpense) {
      failNextDeleteExpense = false;
      throw StateError('Simulated DB failure in deleteExpense');
    }
    return super.deleteExpense(id);
  }

  @override
  Future<int> addExpense(ExpensesCompanion expense) async {
    if (failNextAddExpense) {
      failNextAddExpense = false;
      throw StateError('Simulated DB failure in addExpense');
    }
    return super.addExpense(expense);
  }
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ReceiptFileService receiptFileService;
  late _FaultyExpenseDao faultyExpenseDao;
  late KittyService kittyService;
  late int tripId;
  late int member1Id;
  late int member2Id;

  Uint8List createDummyJpeg(int width, int height, img.ColorRgb8 color) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: color);
    return Uint8List.fromList(img.encodeJpg(image));
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('receipt_lifecycle_test_');
    receiptFileService = ReceiptFileService(docsDirProvider: () async => tempDir);
    faultyExpenseDao = _FaultyExpenseDao(db);
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: faultyExpenseDao,
      receiptFileService: receiptFileService,
    );

    tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'RECEIPT1 Test Trip',
        startDate: DateTime(2026, 7, 1),
      ),
    );

    member1Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Skipper Anna',
        isChild: const Value(false),
        isVegetarian: const Value(false),
        isNonDrinker: const Value(false),
      ),
    );

    member2Id = await db.tripDao.addCrewMember(
      CrewMembersCompanion.insert(
        tripId: tripId,
        name: 'Ben',
        isChild: const Value(false),
        isVegetarian: const Value(false),
        isNonDrinker: const Value(false),
      ),
    );

    // Initial deposit: 100,00 EUR each
    await kittyService.addDeposit(tripId: tripId, memberId: member1Id, amountInCents: 10000);
    await kittyService.addDeposit(tripId: tripId, memberId: member2Id, amountInCents: 10000);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('RECEIPT1: Expense creation with draft receipts persists files and DB records', () async {
    final photo1 = createDummyJpeg(200, 200, img.ColorRgb8(255, 0, 0));
    final photo2 = createDummyJpeg(300, 300, img.ColorRgb8(0, 255, 0));

    final draftReceipts = [
      DraftReceipt(bytes: photo1, fileName: 'receipt_1.jpg'),
      DraftReceipt(bytes: photo2, fileName: 'receipt_2.jpg'),
    ];

    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Hafenbäcker Großeinkauf',
        amountInCents: 4500,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: draftReceipts,
      ),
    );

    expect(expenseId, greaterThan(0));

    // Verify DB records
    final dbReceipts = await db.expenseDao.getReceiptsForExpense(expenseId);
    expect(dbReceipts.length, 2);
    expect(dbReceipts[0].fileName, 'receipt_1.jpg');
    expect(dbReceipts[1].fileName, 'receipt_2.jpg');
    expect(dbReceipts[0].tripId, tripId);
    expect(dbReceipts[0].expenseId, expenseId);
    expect(dbReceipts[0].byteSize, greaterThan(0));

    // Verify files on disk
    final bytes1 = await receiptFileService.readReceiptBytes(dbReceipts[0].filePath);
    final bytes2 = await receiptFileService.readReceiptBytes(dbReceipts[1].filePath);
    expect(bytes1, isNotNull);
    expect(bytes2, isNotNull);

    // Verify loaded KittyData has receipts
    final kittyData = await kittyService.loadKittyData(tripId);
    final loadedExpense = kittyData.expenses.firstWhere((e) => e.id == expenseId);
    expect(loadedExpense.receipts.length, 2);
    expect(loadedExpense.receipts.isNotEmpty, isTrue);
    expect(loadedExpense.receipts.first.fileName, 'receipt_1.jpg');
  });

  test('RECEIPT1: Adding additional receipt page and deleting a single receipt', () async {
    final photo1 = createDummyJpeg(100, 100, img.ColorRgb8(10, 20, 30));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Diesel & Benzin',
        amountInCents: 12000,
        currency: 'EUR',
        category: ExpenseCategory.fuel,
        paidByMemberId: member2Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo1, fileName: 'diesel_page1.jpg')],
      ),
    );

    var receipts = await db.expenseDao.getReceiptsForExpense(expenseId);
    expect(receipts.length, 1);

    // Add page 2
    final photo2 = createDummyJpeg(100, 100, img.ColorRgb8(40, 50, 60));
    final addedReceipt = await kittyService.addReceiptToExpense(
      tripId: tripId,
      expenseId: expenseId,
      imageBytes: photo2,
      preferredFileName: 'diesel_page2.jpg',
    );
    expect(addedReceipt.fileName, 'diesel_page2.jpg');

    receipts = await db.expenseDao.getReceiptsForExpense(expenseId);
    expect(receipts.length, 2);

    // Delete first receipt
    final firstReceipt = receipts.first;
    await kittyService.deleteReceipt(firstReceipt.id);

    // Verify DB and disk cleanup
    final remaining = await db.expenseDao.getReceiptsForExpense(expenseId);
    expect(remaining.length, 1);
    expect(remaining.first.fileName, 'diesel_page2.jpg');

    final deletedFileExists = await receiptFileService.readReceiptBytes(firstReceipt.filePath);
    expect(deletedFileExists, isNull);
  });

  test('RECEIPT1: Expense delete and restore preserves receipts', () async {
    final photo = createDummyJpeg(150, 150, img.ColorRgb8(100, 150, 200));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Supermarkt Marina',
        amountInCents: 6780,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'supermarkt.jpg')],
      ),
    );

    final kittyDataBefore = await kittyService.loadKittyData(tripId);
    final expense = kittyDataBefore.expenses.firstWhere((e) => e.id == expenseId);
    expect(expense.receipts.length, 1);

    // Delete expense
    await kittyService.deleteExpense(expenseId);
    final kittyDataAfterDelete = await kittyService.loadKittyData(tripId);
    expect(kittyDataAfterDelete.expenses.any((e) => e.id == expenseId), isFalse);

    // Restore expense
    await kittyService.restoreExpense(expense);
    final kittyDataAfterRestore = await kittyService.loadKittyData(tripId);
    final restoredExpense = kittyDataAfterRestore.expenses.firstWhere((e) => e.id == expenseId);
    expect(restoredExpense.receipts.length, 1);
    expect(restoredExpense.receipts.first.fileName, 'supermarkt.jpg');
  });

  test('RECEIPT1: Financial settlement invariance - receipts do not alter FIX-B unified ledger', () async {
    // Case A: Expense without receipts
    final expId1 = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Ausgabe ohne Beleg',
        amountInCents: 5000,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
      ),
    );

    final dataWithoutReceipts = await kittyService.loadKittyData(tripId);

    // Now attach receipts to expId1
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(20, 20, 20));
    await kittyService.addReceiptToExpense(
      tripId: tripId,
      expenseId: expId1,
      imageBytes: photo,
      preferredFileName: 'receipt_test.jpg',
    );

    final dataWithReceipts = await kittyService.loadKittyData(tripId);

    // Balances and transfers must be completely invariant to receipt attachments
    expect(dataWithReceipts.cashBalanceCents, equals(dataWithoutReceipts.cashBalanceCents));
    expect(dataWithReceipts.balances.length, equals(dataWithoutReceipts.balances.length));
    for (var i = 0; i < dataWithoutReceipts.balances.length; i++) {
      expect(dataWithReceipts.balances[i].member.id, equals(dataWithoutReceipts.balances[i].member.id));
      expect(dataWithReceipts.balances[i].netBalanceInCents, equals(dataWithoutReceipts.balances[i].netBalanceInCents));
    }

    expect(dataWithReceipts.transfers.length, equals(dataWithoutReceipts.transfers.length));
    for (var i = 0; i < dataWithoutReceipts.transfers.length; i++) {
      expect(dataWithReceipts.transfers[i].fromMember.id, equals(dataWithoutReceipts.transfers[i].fromMember.id));
      expect(dataWithReceipts.transfers[i].toMember.id, equals(dataWithoutReceipts.transfers[i].toMember.id));
      expect(dataWithReceipts.transfers[i].amountInCents, equals(dataWithoutReceipts.transfers[i].amountInCents));
    }
  });

  test('Finding D: Expense softDelete moves files to trash and restoreExpense restores them byte-exact', () async {
    final photo = createDummyJpeg(120, 120, img.ColorRgb8(12, 34, 56));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Bunkern vor Abfahrt',
        amountInCents: 8900,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'bunkern.jpg')],
      ),
    );

    final receipts = await db.expenseDao.getReceiptsForExpense(expenseId);
    expect(receipts.length, 1);
    final receipt = receipts.first;
    final activeFile = File(p.join(tempDir.path, receipt.filePath));
    expect(await activeFile.exists(), isTrue);
    final origBytes = await activeFile.readAsBytes();

    final trashDir = Directory(p.join(tempDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    expect(await trashDir.exists(), isFalse);

    final kittyData = await kittyService.loadKittyData(tripId);
    final expense = kittyData.expenses.firstWhere((e) => e.id == expenseId);

    // 1. Soft delete
    await kittyService.deleteExpense(expenseId, softDelete: true);

    // File moved out of active directory into trash directory
    expect(await activeFile.exists(), isFalse);
    expect(await trashDir.exists(), isTrue);
    final trashedReceiptFiles = trashDir
        .listSync()
        .whereType<File>()
        .where((f) => !p.basename(f.path).startsWith('.'))
        .toList();
    expect(trashedReceiptFiles.length, 1);

    // 2. Restore
    await kittyService.restoreExpense(expense);

    // File restored to active path byte-exact and trash cleaned up
    expect(await activeFile.exists(), isTrue);
    expect(await activeFile.readAsBytes(), equals(origBytes));
    expect(await trashDir.exists(), isFalse);
  });

  test('Finding D: purgeDeletedExpenseReceipts permanently purges trash directory', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(50, 60, 70));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Hafenkaffee',
        amountInCents: 1500,
        currency: 'EUR',
        category: ExpenseCategory.other,
        paidByMemberId: member2Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'kaffee.jpg')],
      ),
    );

    await kittyService.deleteExpense(expenseId, softDelete: true);

    final trashDir = Directory(p.join(tempDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    expect(await trashDir.exists(), isTrue);

    // Purge after snackbar undo expires
    await kittyService.purgeDeletedExpenseReceipts(tripId, expenseId);
    expect(await trashDir.exists(), isFalse);
  });

  test('Finding D: TripService.deleteTrip removes all receipt files and trash from filesystem', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(80, 90, 100));
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Törn-Ausgabe vor Törnlöschung',
        amountInCents: 4500,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'pre_delete.jpg')],
      ),
    );

    final tripReceiptsDir = Directory(p.join(tempDir.path, 'receipts', 'trip_$tripId'));
    expect(await tripReceiptsDir.exists(), isTrue);

    final tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: CatalogRepository(),
      expenseDao: db.expenseDao,
      receiptFileService: receiptFileService,
    );

    final deleted = await tripService.deleteTrip(tripId);
    expect(deleted, isTrue);

    // Receipts directory for trip must be completely gone
    expect(await tripReceiptsDir.exists(), isFalse);
  });

  test('Finding G: addExpense rolls back DB and deletes files if draft receipt saving fails', () async {
    final validPhoto = createDummyJpeg(100, 100, img.ColorRgb8(1, 2, 3));
    final corruptBytes = Uint8List.fromList([0, 0, 0, 0]); // Not a valid image -> FormatException

    final draftReceipts = [
      DraftReceipt(bytes: validPhoto, fileName: 'valid.jpg'),
      DraftReceipt(bytes: corruptBytes, fileName: 'corrupt.jpg'),
    ];

    expect(
      () => kittyService.addExpense(
        ExpenseInput(
          tripId: tripId,
          title: 'Fehlschlagende Ausgabe',
          amountInCents: 5000,
          currency: 'EUR',
          category: ExpenseCategory.provisions,
          paidByMemberId: member1Id,
          isPaidFromKitty: false,
          draftReceipts: draftReceipts,
        ),
      ),
      throwsA(isA<FormatException>()),
    );

    // Verify DB rollback: no expenses created
    final expenses = await db.expenseDao.getExpensesForTrip(tripId);
    expect(expenses.any((e) => e.note == 'Fehlschlagende Ausgabe'), isFalse);

    // Verify disk cleanup: no lingering files
    final tripReceiptsDir = Directory(p.join(tempDir.path, 'receipts', 'trip_$tripId'));
    if (await tripReceiptsDir.exists()) {
      final entries = tripReceiptsDir.listSync(recursive: true);
      expect(entries, isEmpty);
    }
  });

  test('Finding G: addReceiptToExpense throws ArgumentError on cross-trip expenseId', () async {
    final trip2Id = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Zweiter Törn',
        startDate: DateTime(2026, 8, 1),
      ),
    );

    final photo = createDummyJpeg(100, 100, img.ColorRgb8(1, 1, 1));
    final expenseInTrip1Id = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Trip 1 Ausgabe',
        amountInCents: 2000,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
      ),
    );

    // Attempt to add receipt targeting trip2Id with expense from tripId
    expect(
      () => kittyService.addReceiptToExpense(
        tripId: trip2Id,
        expenseId: expenseInTrip1Id,
        imageBytes: photo,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('R2: addReceiptToExpense löscht die erzeugte Bilddatei sofort, wenn das DB-Insert scheitert (keine verwaiste Datei)', () async {
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Ausgabe für DB-Fehler-Test',
        amountInCents: 2500,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
      ),
    );

    faultyExpenseDao.failNextAddReceipt = true;

    final photo = createDummyJpeg(80, 80, img.ColorRgb8(22, 44, 66));
    await expectLater(
      kittyService.addReceiptToExpense(
        tripId: tripId,
        expenseId: expenseId,
        imageBytes: photo,
        preferredFileName: 'orphan_candidate.jpg',
      ),
      throwsA(isA<StateError>()),
    );

    // Weder DB-Eintrag noch verwaiste Bilddatei auf der Platte!
    final receipts = await db.expenseDao.getReceiptsForExpense(expenseId);
    expect(receipts, isEmpty);

    final expenseFolder = Directory(p.join(tempDir.path, 'receipts', 'trip_$tripId', 'expense_$expenseId'));
    if (await expenseFolder.exists()) {
      expect(expenseFolder.listSync(recursive: true).whereType<File>(), isEmpty);
    }
  });

  test('R2: deleteReceipt verschluckt Dateilöschfehler NICHT (keine stille DB-Löschung) und stellt die Datei wieder her, falls das DB-Delete scheitert', () async {
    final photo = createDummyJpeg(90, 90, img.ColorRgb8(77, 88, 99));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'DeleteReceipt Fehlerpfade',
        amountInCents: 3000,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'important.jpg')],
      ),
    );

    final receipt = (await db.expenseDao.getReceiptsForExpense(expenseId)).single;
    final receiptFile = File(p.join(tempDir.path, receipt.filePath));
    final origBytes = await receiptFile.readAsBytes();

    // Fall A: I/O-Fehler beim Löschen der Datei -> Fehler wird geworfen, DB-Eintrag bleibt erhalten!
    receiptFileService.faultInjector = (op) {
      if (op == 'deleteReceiptFile') {
        throw const FileSystemException('Simulated file permission error on deleteReceiptFile');
      }
    };

    await expectLater(
      kittyService.deleteReceipt(receipt.id),
      throwsA(isA<FileSystemException>()),
    );
    receiptFileService.faultInjector = null;

    expect(await db.expenseDao.getReceiptById(receipt.id), isNotNull);
    expect(await receiptFile.exists(), isTrue);

    // Fall B: Dateilöschung klappt, aber DB-Delete scheitert -> Datei wird automatisch wiederhergestellt!
    faultyExpenseDao.failNextDeleteReceipt = true;

    await expectLater(
      kittyService.deleteReceipt(receipt.id),
      throwsA(isA<StateError>()),
    );

    expect(await db.expenseDao.getReceiptById(receipt.id), isNotNull);
    expect(await receiptFile.exists(), isTrue);
    expect(await receiptFile.readAsBytes(), equals(origBytes));
  });

  test('R2: deleteExpense und restoreExpense behandeln Datei- und DB-Fehler konsistent mit Rollback', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(111, 122, 133));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Undo & Delete Rollback Test',
        amountInCents: 5500,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'rollback_test.jpg')],
      ),
    );

    final receipt = (await db.expenseDao.getReceiptsForExpense(expenseId)).single;
    final activeFile = File(p.join(tempDir.path, receipt.filePath));
    final origBytes = await activeFile.readAsBytes();

    // 1. deleteExpense: Wenn DB-Delete nach moveToTrash scheitert, werden die Dateien aus dem Papierkorb zurückgeholt!
    faultyExpenseDao.failNextDeleteExpense = true;
    await expectLater(
      kittyService.deleteExpense(expenseId, softDelete: true),
      throwsA(isA<StateError>()),
    );
    expect(await db.expenseDao.getExpenseById(expenseId), isNotNull);
    expect(await activeFile.exists(), isTrue);
    expect(await activeFile.readAsBytes(), equals(origBytes));

    // 2. Reguläres Soft-Delete in den Papierkorb
    final kittyData = await kittyService.loadKittyData(tripId);
    final expenseSnapshot = kittyData.expenses.firstWhere((e) => e.id == expenseId);
    await kittyService.deleteExpense(expenseId, softDelete: true);
    expect(await activeFile.exists(), isFalse);

    // 3. restoreExpense: Wenn restoreFromTrash wegen eines I/O-Fehlers scheitert, rollt auch die DB-Transaktion zurück!
    receiptFileService.faultInjector = (op) {
      if (op == 'restoreFromTrash') {
        throw const FileSystemException('Simulated I/O error on restoreFromTrash');
      }
    };
    await expectLater(
      kittyService.restoreExpense(expenseSnapshot),
      throwsA(isA<FileSystemException>()),
    );
    receiptFileService.faultInjector = null;

    // Weder Ausgabe noch Beleg dürfen halbherzig in der DB stehen, solange die Datei noch im Papierkorb liegt!
    expect(await db.expenseDao.getExpenseById(expenseId), isNull);
    expect(await db.expenseDao.getReceiptsForExpense(expenseId), isEmpty);

    // Anschließend funktioniert der reguläre Restore einwandfrei
    await kittyService.restoreExpense(expenseSnapshot);
    expect(await db.expenseDao.getExpenseById(expenseId), isNotNull);
    expect(await activeFile.exists(), isTrue);
    expect(await activeFile.readAsBytes(), equals(origBytes));
  });

  test('R2: Verwaiste temporäre Undo-Dateien im Papierkorb bleiben nach App-Absturz nicht dauerhaft zurück (TTL-Cleanup)', () async {
    final photo = createDummyJpeg(80, 80, img.ColorRgb8(200, 100, 50));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Abgestürztes Undo',
        amountInCents: 1900,
        currency: 'EUR',
        category: ExpenseCategory.other,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'crashed_undo.jpg')],
      ),
    );

    // Simuliere Soft-Delete vor 10 Minuten, gefolgt von einem App-Absturz (kein Snackbar-Callback mehr)
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    await receiptFileService.moveToTrash(tripId, expenseId, trashedAt: tenMinutesAgo);
    await db.expenseDao.deleteExpense(expenseId);

    final trashDir = Directory(p.join(tempDir.path, 'receipts_trash', 'trip_$tripId', 'expense_$expenseId'));
    expect(await trashDir.exists(), isTrue);

    // Beim nächsten Laden der Kassendaten (oder App-Start) räumt cleanupExpiredTrash verwaiste Undo-Ordner automatisch auf
    await kittyService.loadKittyData(tripId);
    expect(await trashDir.exists(), isFalse);
  });

  test('R2: TripService.deleteTrip verschluckt Bereinigungsfehler NICHT und rollt DB + Dateien bei I/O-Fehler zurück', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(33, 66, 99));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Ausgabe in zu löschendem Törn',
        amountInCents: 4000,
        currency: 'EUR',
        category: ExpenseCategory.provisions,
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'trip_delete_io.jpg')],
      ),
    );

    final receipt = (await db.expenseDao.getReceiptsForExpense(expenseId)).single;
    final receiptFile = File(p.join(tempDir.path, receipt.filePath));
    final origBytes = await receiptFile.readAsBytes();

    final tripService = TripService(
      tripDao: db.tripDao,
      listItemDao: db.listItemDao,
      catalogRepository: CatalogRepository(),
      expenseDao: db.expenseDao,
      receiptFileService: receiptFileService,
    );

    // Injiziere I/O-Fehler beim finalen Löschen der Törn-Belege
    receiptFileService.faultInjector = (op) {
      if (op == 'deleteTripReceipts') {
        throw const FileSystemException('Simulated I/O failure during trip receipt deletion');
      }
    };

    await expectLater(
      tripService.deleteTrip(tripId),
      throwsA(isA<FileSystemException>()),
    );
    receiptFileService.faultInjector = null;

    // Törn, Ausgabe und Belegdatei sind dank Rollback konsistent erhalten geblieben!
    expect(await db.tripDao.getTripById(tripId), isNotNull);
    expect(await receiptFile.exists(), isTrue);
    expect(await receiptFile.readAsBytes(), equals(origBytes));
  });
}
