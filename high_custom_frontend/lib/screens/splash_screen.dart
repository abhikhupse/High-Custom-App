import 'package:flutter/material.dart';

class HighCustomSplashScreen extends StatefulWidget {
  const HighCustomSplashScreen({super.key});

  @override
  State<HighCustomSplashScreen> createState() => _HighCustomSplashScreenState();
}

class _HighCustomSplashScreenState extends State<HighCustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _detailsOpacity;

  static const Color _background = Color(0xFF050607);
  static const Color _gold = Color(0xFFC8A96A);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.84, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
      ),
    );

    _detailsOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 1, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.18),
                radius: 0.88,
                colors: [Color(0xFF242016), Color(0xFF0B0C0E), _background],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
          const Positioned(
            top: -130,
            left: -90,
            child: _GoldOrb(size: 290, opacity: 0.055),
          ),
          const Positioned(
            right: -115,
            bottom: -145,
            child: _GoldOrb(size: 330, opacity: 0.045),
          ),
          const _JewellerySparkles(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                final logoWidth = compact ? 215.0 : 270.0;

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: logoWidth,
                                  padding: EdgeInsets.all(compact ? 22 : 28),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _gold.withValues(alpha: 0.16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _gold.withValues(alpha: 0.11),
                                        blurRadius: 60,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/high_custom_logo.png',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 30 : 36),
                            Opacity(
                              opacity: _detailsOpacity.value,
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 1,
                                    color: _gold.withValues(alpha: 0.72),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'CRAFTED FOR EXCELLENCE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFD4BD8A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 3.1,
                                    ),
                                  ),
                                  const SizedBox(height: 34),
                                  const _GoldenLoadingLine(),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: FadeTransition(
              opacity: _detailsOpacity,
              child: Text(
                'HIGH CUSTOM JEWELLERS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldenLoadingLine extends StatefulWidget {
  const _GoldenLoadingLine();

  @override
  State<_GoldenLoadingLine> createState() => _GoldenLoadingLineState();
}

class _GoldenLoadingLineState extends State<_GoldenLoadingLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(painter: _LoadingLinePainter(_controller.value));
          },
        ),
      ),
    );
  }
}

class _LoadingLinePainter extends CustomPainter {
  const _LoadingLinePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFF302B21);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final segmentWidth = size.width * 0.42;
    final start = (size.width + segmentWidth) * progress - segmentWidth;
    final rect = Rect.fromLTWH(start, 0, segmentWidth, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00C8A96A), Color(0xFFC8A96A), Color(0x00C8A96A)],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _LoadingLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GoldOrb extends StatelessWidget {
  const _GoldOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFC8A96A).withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _JewellerySparkles extends StatelessWidget {
  const _JewellerySparkles();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklePainter());
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFC8A96A);
    final points = <Offset>[
      Offset(size.width * 0.16, size.height * 0.27),
      Offset(size.width * 0.83, size.height * 0.22),
      Offset(size.width * 0.12, size.height * 0.68),
      Offset(size.width * 0.88, size.height * 0.63),
      Offset(size.width * 0.72, size.height * 0.78),
    ];

    for (var index = 0; index < points.length; index++) {
      paint.color = const Color(
        0xFFC8A96A,
      ).withValues(alpha: index.isEven ? 0.24 : 0.14);
      final radius = index.isEven ? 1.5 : 1.0;
      canvas.drawCircle(points[index], radius, paint);

      if (index < 2) {
        final arm = 5.0 + (index * 2);
        canvas.drawLine(
          points[index] - Offset(arm, 0),
          points[index] + Offset(arm, 0),
          paint,
        );
        canvas.drawLine(
          points[index] - Offset(0, arm),
          points[index] + Offset(0, arm),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
