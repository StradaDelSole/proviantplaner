import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Erstellt eine plattformgerechte SQLite-Verbindung für die Drift-Datenbank.
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'proviantplaner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}