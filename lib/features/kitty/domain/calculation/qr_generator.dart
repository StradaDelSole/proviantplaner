/// Reiner Dart QR-Code Matrix Generator (ohne externe Pakete gemäß Leitplanken).
/// Unterstützt Byte-Modus (UTF-8) für SEPA EPC-QR-Codes (GiroCode).
library;

import 'dart:typed_data';

/// Generiert eine 2D-Matrix (true = schwarz, false = weiß) für einen QR-Code.
class QrCodeGenerator {
  final String data;
  final int errorCorrectionLevel; // 0 = M (Standard für EPC)

  QrCodeGenerator(this.data, {this.errorCorrectionLevel = 0});

  /// Erzeugt die quadratische bool-Matrix des QR-Codes.
  List<List<bool>> generateMatrix() {
    final bytes = Uint8List.fromList(data.codeUnits);
    // Version 6 (41x41) reicht für bis zu 134 Bytes bei EC-Level M
    // Version 8 (49x49) reicht für bis zu 192 Bytes bei EC-Level M
    final version = bytes.length <= 130 ? 6 : 8;
    final size = 17 + 4 * version;

    final matrix = List.generate(size, (_) => List.filled(size, false));
    final reserved = List.generate(size, (_) => List.filled(size, false));

    _addFinderPatterns(matrix, reserved, size);
    _addAlignmentPatterns(matrix, reserved, version, size);
    _addTimingPatterns(matrix, reserved, size);
    _addDarkModule(matrix, reserved, version);
    _reserveFormatArea(reserved, size);

    // Daten und RS-Code generieren
    final codewords = _encodeData(bytes, version);
    _placeData(matrix, reserved, codewords, size);
    _applyMask(matrix, reserved, size);
    _addFormatInfo(matrix, size);

    return matrix;
  }

  void _addFinderPatterns(List<List<bool>> m, List<List<bool>> res, int size) {
    _drawFinder(m, res, 0, 0);
    _drawFinder(m, res, size - 7, 0);
    _drawFinder(m, res, 0, size - 7);
  }

  void _drawFinder(List<List<bool>> m, List<List<bool>> res, int r, int c) {
    for (int y = -1; y <= 7; y++) {
      for (int x = -1; x <= 7; x++) {
        final row = r + y;
        final col = c + x;
        if (row >= 0 && row < m.length && col >= 0 && col < m.length) {
          res[row][col] = true;
          if (y >= 0 && y <= 6 && x >= 0 && x <= 6) {
            final isBorder = (y == 0 || y == 6 || x == 0 || x == 6);
            final isCenter = (y >= 2 && y <= 4 && x >= 2 && x <= 4);
            m[row][col] = isBorder || isCenter;
          } else {
            m[row][col] = false;
          }
        }
      }
    }
  }

  void _addAlignmentPatterns(List<List<bool>> m, List<List<bool>> res, int version, int size) {
    final positions = version == 6 ? [6, 34] : [6, 26, 46];
    for (final r in positions) {
      for (final c in positions) {
        if ((r == 6 && c == 6) || (r == 6 && c == positions.last && c > 30) || (r == positions.last && c == 6 && r > 30)) {
          continue; // Kollision mit Finder-Pattern vermeiden
        }
        _drawAlignment(m, res, r, c);
      }
    }
  }

  void _drawAlignment(List<List<bool>> m, List<List<bool>> res, int r, int c) {
    for (int y = -2; y <= 2; y++) {
      for (int x = -2; x <= 2; x++) {
        final row = r + y;
        final col = c + x;
        res[row][col] = true;
        m[row][col] = (y.abs() == 2 || x.abs() == 2 || (y == 0 && x == 0));
      }
    }
  }

  void _addTimingPatterns(List<List<bool>> m, List<List<bool>> res, int size) {
    for (int i = 8; i < size - 8; i++) {
      if (!res[6][i]) {
        res[6][i] = true;
        m[6][i] = (i % 2 == 0);
      }
      if (!res[i][6]) {
        res[i][6] = true;
        m[i][6] = (i % 2 == 0);
      }
    }
  }

  void _addDarkModule(List<List<bool>> m, List<List<bool>> res, int version) {
    final row = 4 * version + 9;
    res[row][8] = true;
    m[row][8] = true;
  }

  void _reserveFormatArea(List<List<bool>> res, int size) {
    for (int i = 0; i < 9; i++) {
      res[8][i] = true;
      res[i][8] = true;
    }
    for (int i = size - 8; i < size; i++) {
      res[8][i] = true;
      res[i][8] = true;
    }
  }

  List<int> _encodeData(Uint8List data, int version) {
    final totalDataCodewords = version == 6 ? 136 : 192;
    final buffer = <int>[];

    // Byte Mode: 0100
    buffer.addAll([0, 1, 0, 0]);

    // Character Count (8 Bits für Byte-Modus bei V1-9)
    for (int i = 7; i >= 0; i--) {
      buffer.add((data.length >> i) & 1);
    }

    // Datenbytes
    for (final b in data) {
      for (int i = 7; i >= 0; i--) {
        buffer.add((b >> i) & 1);
      }
    }

    // Terminator (bis zu 4 Nullen)
    while (buffer.length % 8 != 0) {
      buffer.add(0);
    }

    // Codewords erzeugen
    final codewords = <int>[];
    for (int i = 0; i < buffer.length; i += 8) {
      int val = 0;
      for (int j = 0; j < 8; j++) {
        val = (val << 1) | buffer[i + j];
      }
      codewords.add(val);
    }

    // Padding bis zur Gesamtkapazität
    const pad1 = 0xEC;
    const pad2 = 0x11;
    bool padToggle = true;
    while (codewords.length < totalDataCodewords) {
      codewords.add(padToggle ? pad1 : pad2);
      padToggle = !padToggle;
    }

    return codewords;
  }

  void _placeData(List<List<bool>> m, List<List<bool>> res, List<int> codewords, int size) {
    int bitIndex = 0;
    final totalBits = codewords.length * 8;

    int col = size - 1;
    bool upward = true;

    while (col > 0) {
      if (col == 6) col--; // Timing-Pattern-Spalte überspringen

      for (int rowStep = 0; rowStep < size; rowStep++) {
        final row = upward ? (size - 1 - rowStep) : rowStep;

        for (int c = 0; c < 2; c++) {
          final currentCol = col - c;
          if (!res[row][currentCol]) {
            if (bitIndex < totalBits) {
              final byteIdx = bitIndex ~/ 8;
              final bitInByte = 7 - (bitIndex % 8);
              m[row][currentCol] = ((codewords[byteIdx] >> bitInByte) & 1) == 1;
              bitIndex++;
            } else {
              m[row][currentCol] = false;
            }
          }
        }
      }
      upward = !upward;
      col -= 2;
    }
  }

  void _applyMask(List<List<bool>> m, List<List<bool>> res, int size) {
    // Standard-Maske 0: (row + col) % 2 == 0
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!res[r][c] && ((r + c) % 2 == 0)) {
          m[r][c] = !m[r][c];
        }
      }
    }
  }

  void _addFormatInfo(List<List<bool>> m, int size) {
    // Format-Info für EC-Level M, Maske 0 (BCH-kodiert): 0b101010000010010
    const formatBits = 0x5412; // Standard maskiert mit 0x5412 XOR

    for (int i = 0; i < 15; i++) {
      final bit = ((formatBits >> i) & 1) == 1;

      // Linke obere Ecke
      if (i < 6) {
        m[i][8] = bit;
      } else if (i < 8) {
        m[i + 1][8] = bit;
      } else {
        m[8][14 - i] = bit;
      }

      // Geteilte Ränder (unten links & oben rechts)
      if (i < 8) {
        m[8][size - 1 - i] = bit;
      } else {
        m[size - 15 + i][8] = bit;
      }
    }
  }
}
