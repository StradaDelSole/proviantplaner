import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
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

  test('Finding B: generateReceiptsPdfs throws ReceiptImageMissingException if physical receipt file is missing', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(100, 100, 100));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Bäcker',
        amountInCents: 1200,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [
          DraftReceipt(bytes: photo, fileName: 'missing_bill.jpg'),
        ],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);
    final receipt = data.expenses.firstWhere((e) => e.id == expenseId).receipts.first;

    // Delete the physical file from disk to simulate missing file
    final absPath = await receiptFileService.resolveAbsolutePath(receipt.filePath);
    await File(absPath).delete();

    expect(
      () => pdfExportService.generateReceiptsPdfs(
        data: data,
        receiptFileService: receiptFileService,
      ),
      throwsA(isA<ReceiptImageMissingException>()),
    );
  });

  test('Finding B: generateReceiptsPdfs throws ReceiptImageCorruptException if physical receipt file is corrupted', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(100, 100, 100));
    final expenseId = await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Tanken',
        amountInCents: 15000,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.fuel,
        draftReceipts: [
          DraftReceipt(bytes: photo, fileName: 'diesel.jpg'),
        ],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);
    final receipt = data.expenses.firstWhere((e) => e.id == expenseId).receipts.first;

    // Corrupt the physical file with garbage bytes
    final absPath = await receiptFileService.resolveAbsolutePath(receipt.filePath);
    await File(absPath).writeAsBytes([0, 1, 2, 3, 4, 5, 6, 7]);

    expect(
      () => pdfExportService.generateReceiptsPdfs(
        data: data,
        receiptFileService: receiptFileService,
      ),
      throwsA(isA<ReceiptImageCorruptException>()),
    );
  });

  test('Finding F: generateReceiptsPdfs throws PdfReceiptOversizedException if single receipt exceeds maxPdfBytes', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(10, 20, 30));
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Hafenbar',
        amountInCents: 5000,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.restaurant,
        draftReceipts: [
          DraftReceipt(bytes: photo, fileName: 'oversized_test.jpg'),
        ],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);

    // Pass maxPdfBytes smaller than the receipt image bytes
    expect(
      () => pdfExportService.generateReceiptsPdfs(
        data: data,
        receiptFileService: receiptFileService,
        maxPdfBytes: 100, // smaller than image size
      ),
      throwsA(isA<PdfReceiptOversizedException>()),
    );
  });

  test('Finding F: generateReceiptsPdfs throws PdfChunkOversizedException if generated PDF chunk exceeds limit', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(10, 20, 30));
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Supermarkt',
        amountInCents: 7000,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [
          DraftReceipt(bytes: photo, fileName: 'chunk_oversized.jpg'),
        ],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);

    // Pass maxPdfBytes that is larger than the image, but smaller than the resulting 8KB PDF document
    expect(
      () => pdfExportService.generateReceiptsPdfs(
        data: data,
        receiptFileService: receiptFileService,
        maxPdfBytes: 3000, // larger than photo (~1KB), but smaller than full PDF page (~8KB)
      ),
      throwsA(isA<PdfChunkOversizedException>()),
    );
  });

  test('R4: generateReceiptsPdfs teilt einen Multi-Beleg-Chunk automatisch anhand der tatsächlichen PDF-Bytegröße (maxPdfBytes) ohne fehlende oder doppelte Seiten auf', () async {
    final photo1 = createDummyJpeg(120, 120, img.ColorRgb8(15, 25, 35));
    final photo2 = createDummyJpeg(120, 120, img.ColorRgb8(45, 55, 65));
    final photo3 = createDummyJpeg(120, 120, img.ColorRgb8(75, 85, 95));

    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Einkauf Alpha',
        amountInCents: 1100,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [DraftReceipt(bytes: photo1, fileName: 'alpha.jpg')],
      ),
    );
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Einkauf Beta',
        amountInCents: 2200,
        currency: 'EUR',
        paidByMemberId: member2Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [DraftReceipt(bytes: photo2, fileName: 'beta.jpg')],
      ),
    );
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Einkauf Gamma',
        amountInCents: 3300,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [DraftReceipt(bytes: photo3, fileName: 'gamma.jpg')],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);

    // Zuerst ungeteilte Gesamtgröße messen (alle 3 Belege in 1 PDF)
    final unsplitPdfs = await pdfExportService.generateReceiptsPdfs(
      data: data,
      receiptFileService: receiptFileService,
    );
    expect(unsplitPdfs.length, equals(1));
    final threePagePdfBytes = unsplitPdfs.single.bytes.length;

    // Nun maxBytesPerChunk sehr groß lassen (15 MB), aber maxPdfBytes so wählen, dass
    // 1 oder 2 Seiten hineinpassen, alle 3 Seiten zusammen (threePagePdfBytes) jedoch das PDF-Limit überschreiten!
    final targetMaxPdfBytes = threePagePdfBytes - 500;

    final splitPdfs = await pdfExportService.generateReceiptsPdfs(
      data: data,
      receiptFileService: receiptFileService,
      maxBytesPerChunk: 15 * 1024 * 1024, // Rohbilder würden in 1 Chunk passen!
      maxPdfBytes: targetMaxPdfBytes,     // Tatsächliches PDF erzwingt automatische Aufteilung!
    );

    expect(splitPdfs.length, greaterThan(1));
    for (var i = 0; i < splitPdfs.length; i++) {
      expect(splitPdfs[i].fileName, equals('Belege_${i + 1}.pdf'));
      expect(splitPdfs[i].bytes.length, lessThanOrEqualTo(targetMaxPdfBytes));
    }

    // Prüfe Seitenanzahl über alle erzeugten PDF-Dateien (exakt 3 Seiten insgesamt, keine fehlenden oder doppelten Seiten)
    int countPdfPages(Uint8List pdfBytes) {
      final rawLatin1 = String.fromCharCodes(pdfBytes);
      return RegExp(r'/Type\s*/Page\b').allMatches(rawLatin1).length;
    }

    final totalPagesAcrossChunks =
        splitPdfs.fold<int>(0, (sum, pdf) => sum + countPdfPages(pdf.bytes));
    expect(totalPagesAcrossChunks, equals(3));
  });

  test('R4: prepareSettlementExportDirectory bereinigt frühere temporäre settlement_export_* Verzeichnisse zuverlässig', () async {
    final photo = createDummyJpeg(100, 100, img.ColorRgb8(10, 20, 30));
    await kittyService.addExpense(
      ExpenseInput(
        tripId: tripId,
        title: 'Export Cleanup Test',
        amountInCents: 1500,
        currency: 'EUR',
        paidByMemberId: member1Id,
        isPaidFromKitty: false,
        category: ExpenseCategory.provisions,
        draftReceipts: [DraftReceipt(bytes: photo, fileName: 'cleanup.jpg')],
      ),
    );

    final data = await kittyService.loadKittyData(tripId);
    final package = await pdfExportService.generateSettlementPackage(
      data: data,
      receiptFileService: receiptFileService,
    );

    final exportTempBase = await Directory.systemTemp.createTemp('pdf_export_temp_base_');
    addTearDown(() async {
      if (await exportTempBase.exists()) {
        await exportTempBase.delete(recursive: true);
      }
    });

    // Erster Export legt erstes Verzeichnis an
    final exportDir1 = await pdfExportService.prepareSettlementExportDirectory(
      package: package,
      tempDirProvider: () async => exportTempBase,
    );
    expect(await exportDir1.exists(), isTrue);
    expect(await File(p.join(exportDir1.path, 'Abrechnung.pdf')).exists(), isTrue);
    expect(await File(p.join(exportDir1.path, 'Belege.pdf')).exists(), isTrue);

    // Zweiter Export räumt das vorherige temporäre Verzeichnis auf und legt nur das aktuelle bereit
    final exportDir2 = await pdfExportService.prepareSettlementExportDirectory(
      package: package,
      tempDirProvider: () async => exportTempBase,
    );
    expect(await exportDir1.exists(), isFalse);
    expect(await exportDir2.exists(), isTrue);

    final remainingDirs = exportTempBase
        .listSync()
        .whereType<Directory>()
        .where((d) => p.basename(d.path).startsWith('settlement_export_'))
        .toList();
    expect(remainingDirs.length, equals(1));
  });
}
