/// Riverpod Provider für den PDF-Exportdienst (Slice S8).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pdf_export_service.dart';

/// Provider für den [PdfExportService].
final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});
