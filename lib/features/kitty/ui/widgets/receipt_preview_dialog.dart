/// Vollbild-/Modal-Vorschau für Belegfotos (RECEIPT1).
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Zeigt ein Belegfoto vergrößert in einem Dialog an.

class ReceiptPreviewDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? filePath;
  final Uint8List? imageBytes;

  const ReceiptPreviewDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.filePath,
    this.imageBytes,
  });

  /// Öffnet den Beleg-Vorschau-Dialog.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? filePath,
    Uint8List? imageBytes,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ReceiptPreviewDialog(
        title: title,
        subtitle: subtitle,
        filePath: filePath,
        imageBytes: imageBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget imageWidget;

    if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
      );
    } else if (filePath != null && File(filePath!).existsSync()) {
      imageWidget = Image.file(
        File(filePath!),
        fit: BoxFit.contain,
      );
    } else {
      imageWidget = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'Belegdatei nicht gefunden',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ),
      );
    }

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),

        ),
        body: Container(
          color: theme.colorScheme.surface,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageWidget,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

