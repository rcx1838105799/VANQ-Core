import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:material_ui/material_ui.dart';

/// VANQ Core brand header shown at the top of the dashboard.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  static const _logoSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: AppShape.all(AppCorner.fit(160)),
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: _StarlightPainter(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: AppShape.all(AppCorner.fit(_logoSize)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/vanq-logo-anime.webp',
                      width: _logoSize - 12,
                      height: _logoSize - 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VANQ Core',
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.appLocalizations.vanqTagline,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A few soft starlight dots; cheap to paint and fully static.
class _StarlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(20261016);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < 14; i++) {
      final radius = 1.0 + random.nextDouble() * 2.2;
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
