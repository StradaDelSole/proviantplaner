import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';
import 'package:zxing2/qrcode.dart';
import 'package:proviantplaner/features/kitty/domain/models/kitty_models.dart';

void main() {
  group('S5a / Regel 8: EPC-QR-Code (GiroCode) Validierung & zxing2 Dekodier-Nachweis', () {
    test('1. Validierung: Ungültige IBAN (Prüfsumme) wirft EpcValidationException', () {
      expect(
        () => EpcQrPayload(
          beneficiaryName: 'Max Mustermann',
          iban: 'DE89370400440532013001', // Falsche Prüfsumme
          amountInCents: 1500,
          remittanceInformation: 'Einkauf',
        ),
        throwsA(isA<EpcValidationException>().having((e) => e.field, 'field', 'iban')),
      );
    });

    test('2. Validierung: Name > 70 Zeichen wirft EpcValidationException', () {
      expect(
        () => EpcQrPayload(
          beneficiaryName: 'A' * 71,
          iban: 'DE89370400440532013000',
          amountInCents: 1500,
          remittanceInformation: 'Einkauf',
        ),
        throwsA(isA<EpcValidationException>().having((e) => e.field, 'field', 'beneficiaryName')),
      );
    });

    test('3. Validierung: Verwendungszweck > 140 Zeichen wirft EpcValidationException', () {
      expect(
        () => EpcQrPayload(
          beneficiaryName: 'Max Mustermann',
          iban: 'DE89370400440532013000',
          amountInCents: 1500,
          remittanceInformation: 'B' * 141,
        ),
        throwsA(isA<EpcValidationException>().having((e) => e.field, 'field', 'remittanceInformation')),
      );
    });

    test('4. Validierung: Betrag <= 0 oder > 999.999.999,99 € wirft EpcValidationException', () {
      expect(
        () => EpcQrPayload(
          beneficiaryName: 'Max Mustermann',
          iban: 'DE89370400440532013000',
          amountInCents: 0,
          remittanceInformation: 'Einkauf',
        ),
        throwsA(isA<EpcValidationException>().having((e) => e.field, 'field', 'amountInCents')),
      );

      expect(
        () => EpcQrPayload(
          beneficiaryName: 'Max Mustermann',
          iban: 'DE89370400440532013000',
          amountInCents: 100000000000,
          remittanceInformation: 'Einkauf',
        ),
        throwsA(isA<EpcValidationException>().having((e) => e.field, 'field', 'amountInCents')),
      );
    });

    test('5. Validierung: Zeilenumbrüche im Namen oder Verwendungszweck werfen EpcValidationException (Injection-Schutz)', () {
      expect(
        () => EpcQrPayload(
          beneficiaryName: 'Max\nMustermann',
          iban: 'DE89370400440532013000',
          amountInCents: 1500,
          remittanceInformation: 'Einkauf',
        ),
        throwsA(isA<EpcValidationException>()),
      );

      expect(
        () => EpcQrPayload(
          beneficiaryName: 'Max Mustermann',
          iban: 'DE89370400440532013000',
          amountInCents: 1500,
          remittanceInformation: 'Einkauf\r\nAttacke',
        ),
        throwsA(isA<EpcValidationException>()),
      );
    });

    test('6. toEpcString erzeugt exaktes EPC-Format gem. PRD (Version 002, UTF-8, EUR)', () {
      final payload = EpcQrPayload(
        beneficiaryName: 'Max Mustermann',
        iban: 'DE89 3704 0044 0532 0130 00',
        bic: 'COBADEFFXXX',
        amountInCents: 12345, // 123.45 EUR
        remittanceInformation: 'Bordkasse Törnanteil',
      );

      final epc = payload.toEpcString();
      final lines = epc.split('\n');

      expect(lines[0], 'BCD');
      expect(lines[1], '002');
      expect(lines[2], '1'); // UTF-8
      expect(lines[3], 'SCT');
      expect(lines[4], 'COBADEFFXXX');
      expect(lines[5], 'Max Mustermann');
      expect(lines[6], 'DE89370400440532013000');
      expect(lines[7], 'EUR123.45');
      expect(lines[8], ''); // Purpose code
      expect(lines[9], ''); // Structured ref
      expect(lines[10], 'Bordkasse Törnanteil');
    });

    test('7. Echter Dekodier-Nachweis (Regel 8): QrCode generieren und mit zxing2 verlustfrei dekodieren (inkl. Umlaute)', () {
      final payload = EpcQrPayload(
        beneficiaryName: 'Müller & Söhne Proviant GbR',
        iban: 'DE89370400440532013000',
        amountInCents: 8750, // 87.50 EUR
        remittanceInformation: 'Törn Kornaten: Äpfel, Müsli & Öl',
      );

      final epcString = payload.toEpcString();

      // QR Code über Paket `qr` erzeugen
      final qrCode = QrCode.fromData(
        data: epcString,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);

      final moduleCount = qrImage.moduleCount;
      const scale = 4;
      const quietZone = 4;
      final width = (moduleCount + 2 * quietZone) * scale;
      final height = width;

      // ARGB32 Int32List Pixel-Array erstellen (weiß = 0xFFFFFFFF, schwarz = 0xFF000000)
      final pixels = Int32List(width * height);
      pixels.fillRange(0, pixels.length, 0xFFFFFFFF);

      for (var y = 0; y < moduleCount; y++) {
        for (var x = 0; x < moduleCount; x++) {
          if (qrImage.isDark(y, x)) {
            final startX = (x + quietZone) * scale;
            final startY = (y + quietZone) * scale;
            for (var dy = 0; dy < scale; dy++) {
              for (var dx = 0; dx < scale; dx++) {
                final px = startX + dx;
                final py = startY + dy;
                pixels[py * width + px] = 0xFF000000;
              }
            }
          }
        }
      }

      // Mit zxing2 dekodieren (mit UTF-8 Decode-Hint gemäß EPC-Spezifikation Feld 3 '1' = UTF-8)
      final luminanceSource = RGBLuminanceSource(width, height, pixels);
      final binarizer = HybridBinarizer(luminanceSource);
      final bitmap = BinaryBitmap(binarizer);

      final hints = DecodeHints()..put(DecodeHintType.characterSet, 'UTF-8');
      final reader = QRCodeReader();
      final result = reader.decode(bitmap, hints: hints);

      // zxing2 speichert die rohen Byte-Segmente im ResultMetadataType.byteSegments als Int8List.
      // Da Dart's utf8.decode vorzeichenlose Bytes (0..255) verlangt, wandeln wir b & 0xFF um:
      final byteSegments = result.resultMetadata[ResultMetadataType.byteSegments] as List<dynamic>?;
      final rawDecodedText = byteSegments != null && byteSegments.isNotEmpty
          ? utf8.decode((byteSegments.first as Iterable<int>).map((b) => b & 0xFF).toList())
          : result.text;

      expect(rawDecodedText, epcString);
      expect(rawDecodedText, contains('Müller & Söhne Proviant GbR'));
      expect(rawDecodedText, contains('EUR87.50'));
      expect(rawDecodedText, contains('Törn Kornaten: Äpfel, Müsli & Öl'));
    });
  });
}
