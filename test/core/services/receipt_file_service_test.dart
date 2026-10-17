import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:proviantplaner/core/services/receipt_file_service.dart';

void main() {
  group('ReceiptFileService', () {
    late Directory tempDir;
    late ReceiptFileService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('receipt_file_service_test_');
      service = ReceiptFileService(docsDirProvider: () async => tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('optimizeImageBytes downscales large landscape images to maxDimension 1800', () {
      final largeImage = img.Image(width: 2400, height: 1200);
      img.fill(largeImage, color: img.ColorRgb8(255, 0, 0));
      final rawJpeg = Uint8List.fromList(img.encodeJpg(largeImage));

      final optimizedBytes = service.optimizeImageBytes(rawJpeg);
      final decoded = img.decodeImage(optimizedBytes);

      expect(decoded, isNotNull);
      expect(decoded!.width, 1800);
      expect(decoded.height, 900);
    });

    test('optimizeImageBytes downscales large portrait images to maxDimension 1800', () {
      final largeImage = img.Image(width: 1200, height: 2400);
      img.fill(largeImage, color: img.ColorRgb8(0, 255, 0));
      final rawJpeg = Uint8List.fromList(img.encodeJpg(largeImage));

      final optimizedBytes = service.optimizeImageBytes(rawJpeg);
      final decoded = img.decodeImage(optimizedBytes);

      expect(decoded, isNotNull);
      expect(decoded!.width, 900);
      expect(decoded.height, 1800);
    });

    test('optimizeImageBytes preserves dimensions for images smaller than 1800', () {
      final smallImage = img.Image(width: 800, height: 600);
      img.fill(smallImage, color: img.ColorRgb8(0, 0, 255));
      final rawJpeg = Uint8List.fromList(img.encodeJpg(smallImage));

      final optimizedBytes = service.optimizeImageBytes(rawJpeg);
      final decoded = img.decodeImage(optimizedBytes);

      expect(decoded, isNotNull);
      expect(decoded!.width, 800);
      expect(decoded.height, 600);
    });

    test('optimizeImageBytes throws FormatException on invalid image data', () {
      final invalidBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(() => service.optimizeImageBytes(invalidBytes), throwsA(isA<FormatException>()));
    });

    test('saveReceiptImage, readReceiptBytes, resolveAbsolutePath and deleteReceiptFile', () async {
      final image = img.Image(width: 400, height: 300);
      img.fill(image, color: img.ColorRgb8(128, 128, 128));
      final rawJpeg = Uint8List.fromList(img.encodeJpg(image));

      final processed = await service.saveReceiptImage(
        tripId: 10,
        expenseId: 25,
        imageBytes: rawJpeg,
        preferredFileName: 'receipt_page_1.jpg',
      );

      expect(processed.fileName, 'receipt_page_1.jpg');
      expect(processed.relativePath, contains('trip_10'));
      expect(processed.relativePath, contains('expense_25'));
      expect(processed.byteSize, greaterThan(0));
      expect(processed.mimeType, 'image/jpeg');

      // Verify file exists at absolute path
      final absPath = await service.resolveAbsolutePath(processed.relativePath);
      expect(File(absPath).existsSync(), isTrue);

      // Verify reading bytes
      final readBytes = await service.readReceiptBytes(processed.relativePath);
      expect(readBytes, isNotNull);
      expect(readBytes!.length, processed.byteSize);

      // Verify deletion
      final deleted = await service.deleteReceiptFile(processed.relativePath);
      expect(deleted, isTrue);
      expect(File(absPath).existsSync(), isFalse);

      final secondDelete = await service.deleteReceiptFile(processed.relativePath);
      expect(secondDelete, isFalse);
    });

    test('saveRawReceiptBytes saves exact bytes without re-encoding', () async {
      final rawData = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);
      final saved = await service.saveRawReceiptBytes(
        tripId: 1,
        expenseId: 2,
        bytes: rawData,
        fileName: 'raw_backup_receipt.jpg',
      );

      expect(saved.byteSize, rawData.length);
      final loaded = await service.readReceiptBytes(saved.relativePath);
      expect(loaded, equals(rawData));
    });

    test('deleteExpenseReceiptFolder and deleteTripReceipts cleanup directories', () async {
      final dummy = Uint8List.fromList([1, 2, 3]);
      await service.saveRawReceiptBytes(
        tripId: 7,
        expenseId: 11,
        bytes: dummy,
        fileName: 'r1.jpg',
      );
      await service.saveRawReceiptBytes(
        tripId: 7,
        expenseId: 12,
        bytes: dummy,
        fileName: 'r2.jpg',
      );

      final expense11Folder = Directory('${tempDir.path}/receipts/trip_7/expense_11');
      final expense12Folder = Directory('${tempDir.path}/receipts/trip_7/expense_12');
      final tripFolder = Directory('${tempDir.path}/receipts/trip_7');

      expect(expense11Folder.existsSync(), isTrue);
      expect(expense12Folder.existsSync(), isTrue);

      await service.deleteExpenseReceiptFolder(7, 11);
      expect(expense11Folder.existsSync(), isFalse);
      expect(expense12Folder.existsSync(), isTrue);

      await service.deleteTripReceipts(7);
      expect(tripFolder.existsSync(), isFalse);
    });
  });
}
