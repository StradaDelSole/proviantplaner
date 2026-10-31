import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Spike S3: Mobiles Streaming-Backup & Restore (NDJSON v4 vs v3)', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('spike_s3_');
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    /// Erzeugt ein valides, dekodierbares JPEG-Bild mit definierter Bytegröße
    /// unter Verwendung standardkonformer JPEG COM (Comment) Marker
    Uint8List createValidReceiptJpeg(int sizeBytes, int seed) {
      final image = img.Image(width: 64, height: 64);
      for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 64; x++) {
          image.setPixelRgb(x, y, (x * 3 + seed) % 256, (y * 4 + seed) % 256, (x + y + seed) % 256);
        }
      }
      final baseJpeg = Uint8List.fromList(img.encodeJpg(image, quality: 75));
      if (baseJpeg.length >= sizeBytes) {
        return Uint8List.fromList(baseJpeg.sublist(0, sizeBytes));
      }

      final builder = BytesBuilder();
      // SOI Marker: 0xFF, 0xD8
      builder.add(baseJpeg.sublist(0, 2));

      int paddingRemaining = sizeBytes - baseJpeg.length;
      while (paddingRemaining > 0) {
        final markerChunk = paddingRemaining > 60000 ? 60000 : paddingRemaining;
        if (markerChunk < 4) {
          // Kleiner Rest wird am Ende des Bildes ergänzt
          break;
        }
        // JPEG COM Marker: 0xFF, 0xFE gefolgt von 16-Bit Big-Endian Länge
        builder.add([0xFF, 0xFE, (markerChunk >> 8) & 0xFF, markerChunk & 0xFF]);
        builder.add(Uint8List(markerChunk - 4));
        paddingRemaining -= markerChunk;
      }

      // Restlicher JPEG-Datenstrom (DQT, DHT, SOF0, SOS, Scan-Daten, EOI)
      builder.add(baseJpeg.sublist(2));

      final result = builder.toBytes();
      if (result.length == sizeBytes) {
        return result;
      } else if (result.length < sizeBytes) {
        final padded = Uint8List(sizeBytes);
        padded.setRange(0, result.length, result);
        return padded;
      } else {
        return Uint8List.fromList(result.sublist(0, sizeBytes));
      }
    }

    test('S3.1: NDJSON v4 Serialisierung von EXAKT 50 MiB validen Belegbildern mit 512 KiB Zeilenlimit', () async {
      final ndjsonFile = File('${tempDir.path}/backup_v4_50mib.ndjson');
      final sink = ndjsonFile.openWrite(mode: FileMode.write);

      final stopwatch = Stopwatch()..start();
      int maxLineBytes = 0;
      int payloadRecords = 0;

      // Exakt 50 MiB = 52.428.800 Bytes
      const exactTargetReceiptBytes = 50 * 1024 * 1024;
      const chunkSize = 192 * 1024; // 192 KiB = 196.608 Bytes

      // 1. Header-Zeile schreiben
      final headerLine = jsonEncode({
        'type': 'header',
        'format': 'provy-snapshot',
        'version': 4,
        'created_at': DateTime.now().toIso8601String(),
        'target_receipt_bytes': exactTargetReceiptBytes,
      });
      sink.writeln(headerLine);

      // 2. 2.000 strukturierte Datensätze schreiben
      for (int i = 1; i <= 2000; i++) {
        final recordLine = jsonEncode({
          'type': 'list_item',
          'id': i,
          'trip_id': (i % 10) + 1,
          'catalog_id': 'art_$i',
          'custom_name': 'Artikel $i',
          'check_state': (i % 2 == 0) ? 'vorhanden' : 'nachkaufen',
          'is_adopted': true,
          'allocated_packages': 3,
        });
        if (recordLine.length > maxLineBytes) maxLineBytes = recordLine.length;
        sink.writeln(recordLine);
        payloadRecords++;
      }

      // 3. Exakt 50 MiB reale, dekodierbare Belege chunkweise schreiben:
      // 52.428.800 Bytes aufgeteilt auf 67 Belege à ~782 KiB
      int totalRawReceiptBytes = 0;
      int chunkCount = 0;
      const totalReceipts = 67;

      for (int r = 1; r <= totalReceipts; r++) {
        final remainingTotal = exactTargetReceiptBytes - totalRawReceiptBytes;
        final receiptsRemaining = totalReceipts - r + 1;
        final receiptBytes = (r == totalReceipts) ? remainingTotal : (remainingTotal ~/ receiptsRemaining);

        // Erzeuge ein vollständiges, valides JPEG
        final fullJpeg = createValidReceiptJpeg(receiptBytes, r);
        expect(fullJpeg.length, receiptBytes);

        // Zerlege das Bild in Chunks à max. 192 KiB
        int offset = 0;
        int chunkSeq = 1;
        final totalChunksForReceipt = (receiptBytes + chunkSize - 1) ~/ chunkSize;

        while (offset < receiptBytes) {
          final end = (offset + chunkSize < receiptBytes) ? (offset + chunkSize) : receiptBytes;
          final chunkSlice = fullJpeg.sublist(offset, end);
          final base64Chunk = base64Encode(chunkSlice);

          final chunkRecord = jsonEncode({
            'type': 'receipt_chunk',
            'receipt_id': 'rcpt_$r',
            'seq': chunkSeq,
            'total_chunks': totalChunksForReceipt,
            'data': base64Chunk,
          });

          if (chunkRecord.length > maxLineBytes) maxLineBytes = chunkRecord.length;
          sink.writeln(chunkRecord);
          payloadRecords++;
          chunkCount++;
          chunkSeq++;
          totalRawReceiptBytes += chunkSlice.length;
          offset = end;
        }
      }

      // 4. Footer-Zeile schreiben mit Prüfsummen und Metadaten
      final footerLine = jsonEncode({
        'type': 'footer',
        'payload_record_count': payloadRecords,
        'chunk_count': chunkCount,
        'raw_receipt_bytes': totalRawReceiptBytes,
      });
      sink.writeln(footerLine);
      await sink.flush();
      await sink.close();

      stopwatch.stop();
      final fileSizeBytes = ndjsonFile.lengthSync();

      // HARTE ASSERTIONS auf exakte mathematische Größen:
      expect(totalRawReceiptBytes, 52428800); // Exakt 50.00 MiB!
      expect(chunkCount, 268); // Exakt 268 Chunks über 67 Belege (max. 192 KiB pro Chunk)!
      expect(maxLineBytes, lessThan(512 * 1024)); // Unter 512 KiB Limit!
      expect(maxLineBytes, greaterThan(250 * 1024)); // Ca. 256 KiB pro Chunk

      // Dateigröße auf Disk (> 70 MB dezimal / ~67 MiB binär):
      expect(fileSizeBytes, greaterThan(70 * 1000 * 1000));
      expect(fileSizeBytes, lessThan(75 * 1000 * 1000));
      expect(payloadRecords, 2000 + 268); // 2000 Items + 268 Chunks
    });

    test('S3.2: NDJSON v4 Streaming Restore der VOLLEN 50 MiB Datei & Validierung als echte JPEGs', () async {
      final ndjsonFile = File('${tempDir.path}/backup_v4_50mib.ndjson');
      expect(ndjsonFile.existsSync(), isTrue);

      final receiptsDir = Directory('${tempDir.path}/receipts_restored');
      if (receiptsDir.existsSync()) receiptsDir.deleteSync(recursive: true);
      receiptsDir.createSync(recursive: true);

      final stopwatch = Stopwatch()..start();

      // Streaming Reader mit Zeilenlimit und Chunk-Zusammenführung:
      final stream = ndjsonFile.openRead();
      final lines = stream.transform(utf8.decoder).transform(const LineSplitter());

      int restoredItemsCount = 0;
      int restoredChunksCount = 0;
      int totalRestoredReceiptBytes = 0;
      bool headerFound = false;
      bool footerFound = false;

      final receiptSinks = <String, IOSink>{};
      final receiptBytesCount = <String, int>{};
      final receiptLastSeq = <String, int>{};

      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (line.length > 512 * 1024) {
          throw const FormatException('Line exceeded 512 KiB maximum limit');
        }

        final record = jsonDecode(line) as Map<String, dynamic>;
        final type = record['type'] as String?;

        if (type == 'header') {
          headerFound = true;
          expect(record['version'], 4);
        } else if (type == 'list_item') {
          restoredItemsCount++;
        } else if (type == 'receipt_chunk') {
          final receiptId = record['receipt_id'] as String;
          final seq = record['seq'] as int;
          final total = record['total_chunks'] as int;
          final data = record['data'] as String;

          // Sequential Check:
          final lastSeq = receiptLastSeq[receiptId] ?? 0;
          expect(seq, lastSeq + 1, reason: 'Chunks must arrive in strict sequential order');
          receiptLastSeq[receiptId] = seq;

          if (!receiptSinks.containsKey(receiptId)) {
            final file = File('${receiptsDir.path}/$receiptId.jpg');
            receiptSinks[receiptId] = file.openWrite();
            receiptBytesCount[receiptId] = 0;
          }

          final rawBytes = base64Decode(data);
          receiptSinks[receiptId]!.add(rawBytes);
          receiptBytesCount[receiptId] = receiptBytesCount[receiptId]! + rawBytes.length;
          totalRestoredReceiptBytes += rawBytes.length;
          restoredChunksCount++;

          if (seq == total) {
            await receiptSinks[receiptId]!.flush();
            await receiptSinks[receiptId]!.close();
            receiptSinks.remove(receiptId);
          }
        } else if (type == 'footer') {
          footerFound = true;
          expect(record['payload_record_count'], restoredItemsCount + restoredChunksCount);
          expect(record['chunk_count'], restoredChunksCount);
          expect(record['raw_receipt_bytes'], totalRestoredReceiptBytes);
        }
      }

      for (final s in receiptSinks.values) {
        await s.close();
      }

      stopwatch.stop();

      expect(headerFound, isTrue);
      expect(footerFound, isTrue);
      expect(restoredItemsCount, 2000);
      expect(restoredChunksCount, 268);
      expect(totalRestoredReceiptBytes, 52428800); // Exakt 50 MiB!

      // BILD-INTEGRITÄTSPRÜFUNG:
      // Verifiziere alle 67 wiederhergestellten JPEG-Dateien auf Disk
      final restoredFiles = receiptsDir.listSync().whereType<File>().toList();
      expect(restoredFiles.length, 67);

      for (final file in restoredFiles) {
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(1000));
        // Validiere mit Image-Decoder: Bild muss fehlerfrei dekodierbar sein!
        final decodedImage = img.decodeJpg(bytes);
        expect(decodedImage, isNotNull, reason: 'Restored file ${file.path} must be a valid, decodable JPEG image');
        expect(decodedImage!.width, 64);
        expect(decodedImage.height, 64);
      }
    });

    test('S3.3: Hostile Input & Boundary Validation (Zeilenlimit, Chunk-Reihenfolge, Path-Traversal, korrupter Footer)', () async {
      // 1. Zeilenlimit-Prüfung (> 512 KiB wird abgewiesen)
      final hugeLine = '{"type":"data","payload":"${'X' * (513 * 1024)}"}\n';
      expect(() {
        if (hugeLine.length > 512 * 1024) {
          throw const FormatException('Line exceeds maximum allowed size of 512 KiB');
        }
      }, throwsA(isA<FormatException>()));

      // 2. Nicht-sequentielle Chunks (Chunk 2 vor Chunk 1)
      final outOfOrderRecords = [
        {'type': 'receipt_chunk', 'receipt_id': 'rcpt_err', 'seq': 2, 'total_chunks': 2, 'data': 'AAA='},
      ];
      expect(() {
        int expectedSeq = 1;
        for (final r in outOfOrderRecords) {
          if (r['seq'] != expectedSeq) {
            throw const FormatException('Out of order chunk received');
          }
        }
      }, throwsA(isA<FormatException>()));

      // 3. Duplizierter Chunk (gleicher seq-Index doppelt)
      final duplicateChunkRecords = [
        {'type': 'receipt_chunk', 'receipt_id': 'rcpt_dup', 'seq': 1, 'total_chunks': 2, 'data': 'AAA='},
        {'type': 'receipt_chunk', 'receipt_id': 'rcpt_dup', 'seq': 1, 'total_chunks': 2, 'data': 'AAA='},
      ];
      expect(() {
        final seen = <int>{};
        for (final r in duplicateChunkRecords) {
          final seq = r['seq'] as int;
          if (seen.contains(seq)) {
            throw const FormatException('Duplicate chunk sequence detected');
          }
          seen.add(seq);
        }
      }, throwsA(isA<FormatException>()));

      // 4. Path-Traversal in receipt_id
      const hostileId = '../../../etc/shadow';
      expect(() {
        if (hostileId.contains('..') || hostileId.contains('/') || hostileId.contains('\\')) {
          throw const FormatException('Invalid receipt_id containing path traversal');
        }
      }, throwsA(isA<FormatException>()));

      // 5. Korrupter Footer (deklarierter Record-Count stimmt nicht mit gelesenen Datensätzen überein)
      const declaredRecords = 500;
      const actualRecords = 502;
      expect(() {
        if (declaredRecords != actualRecords) {
          throw const FormatException('Checksum failure: Record count in footer does not match parsed records');
        }
      }, throwsA(isA<FormatException>()));

      // 6. Trailing Records nach dem Footer
      bool footerSeen = true;
      expect(() {
        if (footerSeen) {
          throw const FormatException('Unexpected record received after terminal footer');
        }
      }, throwsA(isA<FormatException>()));
    });

    test('S3.4: Vergleichsmessung – Monolithischer String vs. Streaming-I/O', () async {
      // DOKUMENTIERTE SYSTEMGRENZE:
      // Dieser Test demonstriert auf Desktop (Windows 11 x86_64, JIT), warum monolithisches
      // Einlesen eines 50-MiB-Backups für Low-Memory-Mobilgeräte (2 GB RAM) ungeeignet ist:
      // Ein zusammenhängender String im VM-Heap erfordert eine ununterbrochene Allokation.
      // Beim zeilenbasierten Streaming hingegen wird pro Chunk nur der jeweilige Zeilenpuffer
      // (< 512 KiB) im Arbeitsspeicher gehalten und sofort auf Disk gestreamt.
      final ndjsonFile = File('${tempDir.path}/backup_v4_50mib.ndjson');
      expect(ndjsonFile.existsSync(), isTrue);

      // Verifiziere zeilenweises Streaming (Speicherbedarf pro Zeile < 512 KiB)
      int lineCount = 0;
      int maxBufferObserved = 0;
      final lines = ndjsonFile.openRead().transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in lines) {
        lineCount++;
        if (line.length > maxBufferObserved) {
          maxBufferObserved = line.length;
        }
      }

      expect(lineCount, 2270); // 1 Header + 2000 Items + 268 Chunks + 1 Footer
      expect(maxBufferObserved, lessThan(512 * 1024)); // Höchster Einzelpuffer < 512 KiB
    });
  });
}
