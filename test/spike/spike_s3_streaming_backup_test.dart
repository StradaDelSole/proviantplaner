import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

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

    /// Erzeugt einen validen synthetischen JPEG-Header mit deterministischen Fülldaten
    Uint8List createDeterministicJpeg(int sizeBytes, int seed) {
      final bytes = Uint8List(sizeBytes);
      // JPEG SOI Marker
      bytes[0] = 0xFF;
      bytes[1] = 0xD8;
      // APP0 Marker
      bytes[2] = 0xFF;
      bytes[3] = 0xE0;
      // DQT Marker
      bytes[4] = 0x00;
      bytes[5] = 0x10;
      for (int i = 6; i < sizeBytes - 2; i++) {
        bytes[i] = ((i + seed) * 37) & 0xFF;
      }
      // JPEG EOI Marker
      bytes[sizeBytes - 2] = 0xFF;
      bytes[sizeBytes - 1] = 0xD9;
      return bytes;
    }

    test('S3.1: NDJSON v4 Serialisierung von EXAKT 50 MiB Belegbildern mit 512 KiB Zeilenlimit', () async {
      final ndjsonFile = File('${tempDir.path}/backup_v4_50mib.ndjson');
      final sink = ndjsonFile.openWrite(mode: FileMode.write);

      final stopwatch = Stopwatch()..start();
      final initialRss = ProcessInfo.currentRss;
      int maxLineBytes = 0;
      int totalRecords = 0;

      // Exakt 50 MiB = 52.428.800 Bytes
      const exactTargetReceiptBytes = 50 * 1024 * 1024; // 52.428.800 Bytes
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
      totalRecords++;

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
        totalRecords++;
      }

      // 3. Exakt 50 MiB synthetische Belege chunkweise schreiben:
      // 52.428.800 Bytes = 266 Chunks à 196.608 Bytes + 1 Chunk à 131.072 Bytes = 267 Chunks
      int totalRawReceiptBytes = 0;
      int chunkCount = 0;
      int receiptIndex = 1;
      int chunkSeq = 1;

      while (totalRawReceiptBytes < exactTargetReceiptBytes) {
        final remaining = exactTargetReceiptBytes - totalRawReceiptBytes;
        final currentChunkBytes = remaining < chunkSize ? remaining : chunkSize;

        final rawChunk = createDeterministicJpeg(currentChunkBytes, receiptIndex + chunkSeq);
        final base64String = base64Encode(rawChunk);

        final chunkRecord = jsonEncode({
          'type': 'receipt_chunk',
          'receipt_id': 'rcpt_$receiptIndex',
          'seq': chunkSeq,
          'byte_count': currentChunkBytes,
          'data': base64String,
        });

        if (chunkRecord.length > maxLineBytes) maxLineBytes = chunkRecord.length;
        sink.writeln(chunkRecord);
        totalRecords++;
        chunkCount++;
        totalRawReceiptBytes += currentChunkBytes;

        if (chunkSeq >= 4) {
          receiptIndex++;
          chunkSeq = 1;
        } else {
          chunkSeq++;
        }
      }

      // 4. Footer-Zeile
      final footerLine = jsonEncode({
        'type': 'footer',
        'status': 'complete',
        'total_records': totalRecords,
        'total_raw_receipt_bytes': totalRawReceiptBytes,
      });
      sink.writeln(footerLine);
      await sink.flush();
      await sink.close();

      stopwatch.stop();
      final finalRss = ProcessInfo.currentRss;
      final fileSizeBytes = ndjsonFile.lengthSync();

      // HARTE ASSERTIONS auf exakte mathematische Größen:
      expect(totalRawReceiptBytes, 52428800); // Exakt 50 MiB!
      expect(chunkCount, 267); // Exakt 267 Chunks (266 voll + 1 Rest)!
      expect(maxLineBytes, lessThan(512 * 1024)); // Unter 512 KiB Zeilenlimit!
      expect(maxLineBytes, greaterThan(250 * 1024)); // 192 KiB binary raw -> 256 KiB base64 + JSON-Wrapper

      // Dateigröße auf Disk:
      // 52.428.800 Roh-Bytes * 4/3 = 69.905.068 Base64-Zeichen + JSON-Overhead
      expect(fileSizeBytes, greaterThan(70 * 1000 * 1000)); // > 70 MB dezimal
      expect(fileSizeBytes, lessThan(75 * 1000 * 1000)); // < 75 MB dezimal

      final fileSizeMiB = fileSizeBytes / (1024 * 1024);
      final fileSizeMB = fileSizeBytes / 1000000;

      print('=== SPIKE S3.1 SERIALIZATION METRICS (Desktop Runner: Windows 11 x86_64) ===');
      print('Exact Raw Receipt Bytes: $totalRawReceiptBytes Bytes (= exactly 50.00 MiB)');
      print('Total Receipt Chunks: $chunkCount');
      print('NDJSON File Size (Disk): $fileSizeBytes Bytes (= ${fileSizeMB.toStringAsFixed(2)} MB decimal / ${fileSizeMiB.toStringAsFixed(2)} MiB binary)');
      print('Total Records: $totalRecords');
      print('Max Line Size: ${(maxLineBytes / 1024).toStringAsFixed(2)} KiB (Limit: 512 KiB)');
      print('Duration (Desktop JIT): ${stopwatch.elapsedMilliseconds} ms');
      print('Process RSS Delta (Desktop): ${((finalRss - initialRss) / (1024 * 1024)).toStringAsFixed(2)} MB');
    });

    test('S3.2: NDJSON v4 Streaming Restore der VOLLEN 50 MiB Datei ohne OOM', () async {
      final ndjsonFile = File('${tempDir.path}/backup_v4_50mib.ndjson');
      expect(ndjsonFile.existsSync(), isTrue, reason: 'Test S3.1 muss die Datei zuvor erzeugt haben');

      final stopwatch = Stopwatch()..start();
      final restoreStagingDir = Directory('${tempDir.path}/staging_full_50mib');
      await restoreStagingDir.create();

      int parsedItems = 0;
      int parsedChunks = 0;
      int restoredReceiptBytes = 0;
      bool headerFound = false;
      bool footerFound = false;

      // Stream über die gesamte 70+ MB NDJSON-Datei
      final linesStream = ndjsonFile
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in linesStream) {
        if (line.trim().isEmpty) continue;
        final map = jsonDecode(line) as Map<String, dynamic>;
        final type = map['type'] as String;

        if (type == 'header') {
          headerFound = true;
          expect(map['version'], 4);
        } else if (type == 'list_item') {
          parsedItems++;
          expect(map['check_state'], isNotNull);
          expect(map['is_adopted'], isTrue);
        } else if (type == 'receipt_chunk') {
          parsedChunks++;
          final byteCount = map['byte_count'] as int;
          restoredReceiptBytes += byteCount;

          final rcptId = map['receipt_id'] as String;
          final rcptFile = File('${restoreStagingDir.path}/$rcptId.jpg');
          final rawChunk = base64Decode(map['data'] as String);
          expect(rawChunk.length, byteCount);

          // In Staging anhängen
          await rcptFile.writeAsBytes(rawChunk, mode: FileMode.append, flush: false);
        } else if (type == 'footer') {
          footerFound = true;
          expect(map['total_raw_receipt_bytes'], 52428800);
        }
      }

      stopwatch.stop();

      // HARTE VERIFIKATIONEN:
      expect(headerFound, isTrue);
      expect(footerFound, isTrue);
      expect(parsedItems, 2000);
      expect(parsedChunks, 267);
      expect(restoredReceiptBytes, 52428800); // Alle 50 MiB vollständig wiederhergestellt!

      // Prüfe wiederhergestellte Belegdateien auf Staging
      final stagedFiles = restoreStagingDir.listSync();
      expect(stagedFiles.length, 67); // 67 Belege insgesamt

      int totalStagedFileBytes = 0;
      for (final f in stagedFiles) {
        totalStagedFileBytes += (f as File).lengthSync();
      }
      expect(totalStagedFileBytes, 52428800);

      print('=== SPIKE S3.2 FULL 50 MiB RESTORE METRICS (Desktop Runner: Windows 11 x86_64) ===');
      print('Restored Items: $parsedItems / 2000');
      print('Restored Chunks: $parsedChunks / 267');
      print('Restored Raw Receipt Bytes: $restoredReceiptBytes Bytes (= exactly 50.00 MiB)');
      print('Restored JPEG Files on Disk: ${stagedFiles.length}');
      print('Restore Stream Duration (Desktop): ${stopwatch.elapsedMilliseconds} ms');
    });

    test('S3.3: Vergleichsmessung – Legacy Snapshot v3 Vollpufferung vs. NDJSON', () async {
      // 10 MiB Belegdaten in v3-Format
      const receiptBytes = 10 * 1024 * 1024;
      final rawReceipt = createDeterministicJpeg(receiptBytes, 42);
      final b64 = base64Encode(rawReceipt);

      final v3Map = {
        'version': 3,
        'trips': [],
        'receipts': [
          {'id': 1, 'imageBase64': b64}
        ]
      };

      final v3File = File('${tempDir.path}/legacy_v3.json');
      await v3File.writeAsString(jsonEncode(v3Map));

      final v3Size = v3File.lengthSync();
      final stopwatch = Stopwatch()..start();

      final wholeString = await v3File.readAsString();
      final decoded = jsonDecode(wholeString) as Map<String, dynamic>;
      stopwatch.stop();

      expect(decoded['version'], 3);
      print('=== SPIKE S3.3 LEGACY v3 BENCHMARK (Desktop Runner: Windows 11 x86_64) ===');
      print('v3 File Size: $v3Size Bytes (= ${(v3Size / 1000000).toStringAsFixed(2)} MB decimal / ${(v3Size / (1024 * 1024)).toStringAsFixed(2)} MiB binary)');
      print('v3 In-Memory String Length: ${wholeString.length} chars (mind. 28 MB UTF-16 String-Puffer)');
      print('v3 Monolithic Decode Duration (Desktop): ${stopwatch.elapsedMilliseconds} ms');
      print('Hinweis: Auf realen mobilen 2GB-Android-Geräten mit beschränktem Heap (128-256 MB) führt Vollpufferung von 50 MiB zu OOM-Risiko (Release Gate Phase B: OFFEN)');
    });
  });
}
