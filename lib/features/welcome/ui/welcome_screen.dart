import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proviantplaner/core/config/app_config.dart';
import 'package:proviantplaner/features/welcome/data/welcome_storage.dart';

/// Animierter PROVY Brand-Welcome-Screen (#62).
///
/// Präsentiert die App-Identität und die drei Kernschritte (Proviantplanung,
/// Bordkasse, Abrechnung) mit einer maritimen Routenlinie und gestaffelten
/// Animationen. Unterstützt reduzierten Bewegungseffekt (disableAnimations)
/// sowie den Nachtwache-Modus.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _headlineFade;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _routeProgress;
  late final Animation<double> _step1Anim;
  late final Animation<double> _step2Anim;
  late final Animation<double> _step3Anim;
  late final Animation<double> _ctaFade;
  late final Animation<Offset> _ctaSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    const curve = Curves.easeOutCubic;

    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: curve),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: curve),
    ));

    _headlineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.5, curve: curve),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.5, curve: curve),
    ));

    _routeProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.85, curve: Curves.easeInOutCubic),
    );

    _step1Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOutBack),
    );
    _step2Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutBack),
    );
    _step3Anim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOutBack),
    );

    _ctaFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: curve),
    );
    _ctaSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: curve),
    ));

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Barrierefreiheit: Bei reduzierter Bewegung Animationen direkt abschließen
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;
  bool _showContinueAnyway = false;

  Future<void> _handleGetStarted() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await ref.read(welcomeCompletedProvider.notifier).completeWelcome();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _showContinueAnyway = true;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const ValueKey('welcome_error_snackbar'),
          content: Text(l10n.welcomeStorageError),
          action: SnackBarAction(
            key: const ValueKey('welcome_retry_snackbar_action'),
            label: l10n.retry,
            onPressed: _handleGetStarted,
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isNightwatch = theme.scaffoldBackgroundColor == const Color(0xFF000000);

    final primaryColor = isNightwatch
        ? const Color(0xFFFF3B30)
        : theme.colorScheme.primary;

    final onSurfaceColor = isNightwatch
        ? const Color(0xFFFF3B30)
        : theme.colorScheme.onSurface;

    final onSurfaceVariantColor = isNightwatch
        ? const Color(0xFFFF3B30).withOpacity(0.7)
        : theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 40),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 1),

                      // 1. Wordmark PROVY
                      SlideTransition(
                        position: _wordmarkSlide,
                        child: FadeTransition(
                          opacity: _wordmarkFade,
                          child: Center(
                            child: Text(
                              AppConfig.appName.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'IBMPlexSans',
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6.0,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Headline & Subline
                      SlideTransition(
                        position: _headlineSlide,
                        child: FadeTransition(
                          opacity: _headlineFade,
                          child: Column(
                            children: [
                              Text(
                                l10n.welcomeBrandHeadline,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: onSurfaceColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.welcomeBrandSubline,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: onSurfaceVariantColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // 3. Maritime Routen-Wegpunkte mit RoutePainter
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _RoutePainter(
                                    progress: _routeProgress.value,
                                    lineColor: primaryColor.withOpacity(isNightwatch ? 0.6 : 0.35),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  _buildWaypoint(
                                    stepNumber: '01',
                                    title: l10n.welcomeStepPlanning,
                                    icon: Icons.checklist_outlined,
                                    scale: _step1Anim.value,
                                    primaryColor: primaryColor,
                                    onSurfaceColor: onSurfaceColor,
                                    theme: theme,
                                    isNightwatch: isNightwatch,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildWaypoint(
                                    stepNumber: '02',
                                    title: l10n.welcomeStepCosts,
                                    icon: Icons.account_balance_wallet_outlined,
                                    scale: _step2Anim.value,
                                    primaryColor: primaryColor,
                                    onSurfaceColor: onSurfaceColor,
                                    theme: theme,
                                    isNightwatch: isNightwatch,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildWaypoint(
                                    stepNumber: '03',
                                    title: l10n.welcomeStepSettlement,
                                    icon: Icons.receipt_long_outlined,
                                    scale: _step3Anim.value,
                                    primaryColor: primaryColor,
                                    onSurfaceColor: onSurfaceColor,
                                    theme: theme,
                                    isNightwatch: isNightwatch,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const Spacer(flex: 3),

                      // 4. Barrierefreier CTA-Button "Los geht's"
                      if (_showContinueAnyway) ...[
                        TextButton(
                          key: const ValueKey('welcome_continue_anyway_button'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ref.read(welcomeCompletedProvider.notifier).continueWithoutPersistence();
                            context.go('/');
                          },
                          child: Text(
                            l10n.welcomeContinueAnyway,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SlideTransition(
                        position: _ctaSlide,
                        child: FadeTransition(
                          opacity: _ctaFade,
                          child: FilledButton(
                            key: const ValueKey('welcome_get_started_button'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: primaryColor,
                              foregroundColor: isNightwatch ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: isNightwatch ? 0 : 2,
                            ),
                            onPressed: _handleGetStarted,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.welcomeGetStarted,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaypoint({
    required String stepNumber,
    required String title,
    required IconData icon,
    required double scale,
    required Color primaryColor,
    required Color onSurfaceColor,
    required ThemeData theme,
    required bool isNightwatch,
  }) {
    final clampedScale = scale.clamp(0.0, 1.0);
    return Opacity(
      opacity: clampedScale,
      child: Transform.scale(
        scale: 0.8 + (0.2 * clampedScale),
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isNightwatch
                ? const Color(0xFF1A0000)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isNightwatch
                  ? const Color(0xFFFF3B30).withOpacity(0.4)
                  : theme.colorScheme.outlineVariant.withOpacity(0.6),
            ),
          ),
          child: Row(
            children: [
              // Wegpunkt-Nummer in Monospace
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Icon
              Icon(icon, size: 22, color: primaryColor),
              const SizedBox(width: 12),

              // Schritt-Titel
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zeichnet eine maritime, sanft geschwungene Routenlinie entlang der Wegpunkte.
class _RoutePainter extends CustomPainter {
  final double progress;
  final Color lineColor;

  _RoutePainter({
    required this.progress,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Vertikale Linie links hinter den Wegpunkt-Ziffern (bei x = 32)
    const x = 32.0;
    const startY = 28.0;
    final endY = size.height - 28.0;

    path.moveTo(x, startY);
    // Sanfte maritime Biegung in der Mitte
    final midY = (startY + endY) / 2;
    path.cubicTo(
      x + 8.0,
      startY + (midY - startY) * 0.5,
      x - 8.0,
      midY + (endY - midY) * 0.5,
      x,
      endY,
    );

    // Animierter Pfadabschnitt gemäß Fortschritt
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * progress);
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.lineColor != lineColor;
  }
}
