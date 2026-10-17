import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:proviantplaner/core/database/app_database.dart';
import 'package:proviantplaner/core/services/pdf_export_service.dart';
import 'package:proviantplaner/core/services/receipt_file_service.dart';
import 'package:proviantplaner/features/kitty/data/kitty_service.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';
import 'package:proviantplaner/features/kitty/domain/models/receipt_models.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ReceiptFileService receiptFileService;
  late PdfExportService pdfExportService;
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
    tempDir = await Directory.systemTemp.createTemp('pdf_receipts_test_');
    receiptFileService = ReceiptFileService(docsDirProvider: () async => tempDir);
    pdfExportService = PdfExportService();
    kittyService = KittyService(
      tripDao: db.tripDao,
      expenseDao: db.expenseDao,
      receiptFileService: receiptFileService,
    );

    tripId = await db.tripDao.createTrip(
      TripsCompanion.insert(
        name: 'Sommertörn Ostsee',
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

    await kittyService.addDeposit(tripId: tripId, memberId: member1Id, amountInCents: 10000);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('RECEIPT1: generateReceiptsPdfs returns empty list when no expenses have receipts', () async {
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Hafengebühr ohne Beleg',
        amountInCents: 3500,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.marinaBerth,
      ),
    );

    final data = await kittyService.loadKittyData(tripId);
    final pdfs = await pdfExportService.generateReceiptsPdfs(
      data: data,
      receiptFileService: receiptFileService,
    );

    expect(pdfs, isEmpty);
  });

  test('RECEIPT1: generateReceiptsPdfs creates valid Belege.pdf with embedded images', () async {
    final photo = createDummyJpeg(200, 200, img.ColorRgb8(200, 50, 50));
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Supermarkt Hafen',
        amountInCents: 4500,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [
          DraftReceipt(bytes: photo, fileName: 'receipt_supermarkt.jpg'),
        ],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);
    final pdfs = await pdfExportService.generateReceiptsPdfs(
      data: data,
      receiptFileService: receiptFileService,
    );

    expect(pdfs.length, 1);
    expect(pdfs.first.fileName, 'Belege.pdf');
    expect(pdfs.first.bytes.length, greaterThan(100));
    // Verify PDF Magic Bytes %PDF-
    final header = String.fromCharCodes(pdfs.first.bytes.sublist(0, 5));
    expect(header, '%PDF-');
  });

  test('RECEIPT1: generateReceiptsPdfs splits into Belege_1.pdf and Belege_2.pdf when chunk limit is exceeded', () async {
    final photo1 = createDummyJpeg(100, 100, img.ColorRgb8(10, 20, 30));
    final photo2 = createDummyJpeg(100, 100, img.ColorRgb8(40, 50, 60));

    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Einkauf 1',
        amountInCents: 1000,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [
          DraftReceipt(bytes: photo1, fileName: 'r1.jpg'),
        ],
      ),
    );

    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Einkauf 2',
        amountInCents: 2000,
        currency: 'EUR',
        paidByMemberId: member2Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [
          DraftReceipt(bytes: photo2, fileName: 'r2.jpg'),
        ],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);
    final firstReceiptSize = data.expenses.first.receipts.first.byteSize;

    // Set maxBytesPerChunk to firstReceiptSize so second entry forces a new chunk
    final pdfs = await pdfExportService.generateReceiptsPdfs(
      data: data,
      receiptFileService: receiptFileService,
      maxBytesPerChunk: firstReceiptSize,
    );

    expect(pdfs.length, 2);
    expect(pdfs[0].fileName, 'Belege_1.pdf');
    expect(pdfs[1].fileName, 'Belege_2.pdf');
    expect(String.fromCharCodes(pdfs[0].bytes.sublist(0, 5)), '%PDF-');
    expect(String.fromCharCodes(pdfs[1].bytes.sublist(0, 5)), '%PDF-');
  });

  test('RECEIPT1: generateSettlementPackage creates Abrechnung.pdf and Belege.pdf package', () async {
    final photo = createDummyJpeg(150, 150, img.ColorRgb8(120, 180, 240));
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Restaurant Skipperabend',
        amountInCents: 8500,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.restaurant,
        draftReceipts: [
          DraftReceipt(bytes: photo, fileName: 'dinner.jpg'),
        ],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);
    final package = await pdfExportService.generateSettlementPackage(
      data: data,
      receiptFileService: receiptFileService,
    );

    expect(package.settlementPdf.fileName, 'Abrechnung.pdf');
    expect(package.receiptPdfs.length, 1);
    expect(package.receiptPdfs.first.fileName, 'Belege.pdf');
    expect(package.receiptPdfs.isNotEmpty, isTrue);
    expect(package.allPdfs.length, 2);
    final totalBytes = package.allPdfs.fold<int>(0, (sum, p) => sum + p.bytes.length);
    expect(totalBytes, greaterThan(500));
  });
}
