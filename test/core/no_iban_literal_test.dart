/// Suchtest: Kein IBAN-Literal im Code außerhalb von Tests (FEEDBACK_R1 Punkt 10).
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kein IBAN-Literal in lib/ vorhanden', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib-Verzeichnis muss existieren');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    expect(dartFiles, isNotEmpty);

    // Typisches deutsches/europäisches IBAN-Muster (2 Buchstaben, 2 Ziffern, 12-30 Zeichen)
    final ibanRegex = RegExp(r'\b[A-Z]{2}\d{2}[A-Z0-9]{12,30}\b');

    final violations = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Erlaube Kommentare/Regex-Definitionen in Validatoren
        if (line.contains('RegExp') || line.trim().startsWith('//') || line.trim().startsWith('*')) {
          continue;
        }
        final match = ibanRegex.firstMatch(line);
        if (match != null) {
          violations.add('${file.path}:${i + 1}: ${match.group(0)}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'In lib/ wurden harte IBAN-Literale gefunden:\n${violations.join("\n")}',
    );
  });
}
