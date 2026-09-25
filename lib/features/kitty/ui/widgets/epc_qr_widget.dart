/// Widget zur Darstellung des EPC-QR-Codes (GiroCode) gemäß EPC069-12 (Slice S5).
/// Erlaubte Ausnahme im Nachtmodus: 240 dp weißer Hintergrund für Scanbarkeit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:proviantplaner/core/theme/theme_controller.dart';
import '../../domain/models/kitty_models.dart';

/// Stellt den EPC-QR-Code (GiroCode) mit Ausrichtungsmarkierungen dar.
class EpcQrWidget extends ConsumerWidget {
  final EpcQrPayload payload;

  const EpcQrWidget({
    super.key,
    required this.payload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final isNightwatch = themeMode == AppThemeMode.nightwatch;

    final epcString = payload.toEpcString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isNightwatch)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.light_mode_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.kittyNightwatchScanHint,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildCornerGuides(theme.colorScheme.primary),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 176,
                      height: 176,
                      padding: const EdgeInsets.all(4),
                      color: Colors.white,
                      child: QrImageView(
                        data: epcString,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        size: 168,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.kittyScanGiroCode,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      l10n.kittyScanGiroCodeSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCornerGuides(Color color) {
    const size = 12.0;
    const stroke = 2.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: 6,
              left: 6,
              child: _CornerBracket(size: size, stroke: stroke, color: color, top: true, left: true),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: _CornerBracket(size: size, stroke: stroke, color: color, top: true, left: false),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: _CornerBracket(size: size, stroke: stroke, color: color, top: false, left: true),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: _CornerBracket(size: size, stroke: stroke, color: color, top: false, left: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final double size;
  final double stroke;
  final Color color;
  final bool top;
  final bool left;

  const _CornerBracket({
    required this.size,
    required this.stroke,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(color: color, stroke: stroke, top: top, left: left),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double stroke;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.stroke,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.stroke != stroke ||
      oldDelegate.top != top ||
      oldDelegate.left != left;
}

