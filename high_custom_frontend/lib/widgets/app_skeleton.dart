import 'package:flutter/material.dart';

class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.light = false,
  });

  final Widget child;
  final bool light;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.light
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF171A20);
    final highlight = widget.light
        ? const Color(0xFFF7F8FA)
        : const Color(0xFF34302A);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final slide = (_controller.value * 2.4) - 1.2;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(slide - 1, 0),
              end: Alignment(slide + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
    this.light = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      light: light,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: light
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF171A20),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class AppCardSkeletonList extends StatelessWidget {
  const AppCardSkeletonList({
    super.key,
    this.itemCount = 5,
    this.light = false,
    this.compact = false,
  });

  final int itemCount;
  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      light: light,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 14 : 18),
              decoration: BoxDecoration(
                color: light
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF171A20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 42 : 52,
                    height: compact ? 42 : 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FractionallySizedBox(
                          widthFactor: 0.62,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
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
      ),
    );
  }
}

class AppDashboardSkeleton extends StatelessWidget {
  const AppDashboardSkeleton({
    super.key,
    this.light = false,
  });

  final bool light;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: AppShimmer(
            light: light,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: mobile ? 190 : 260, height: 28, light: light),
                const SizedBox(height: 12),
                _block(width: mobile ? 260 : 360, height: 13, light: light),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: List.generate(
                    mobile ? 2 : 4,
                    (_) => _block(
                      width: mobile
                          ? (constraints.maxWidth - 46) / 2
                          : (constraints.maxWidth - 90) / 4,
                      height: 118,
                      radius: 14,
                      light: light,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _block(
                  width: double.infinity,
                  height: mobile ? 190 : 240,
                  radius: 16,
                  light: light,
                ),
                const SizedBox(height: 16),
                _block(
                  width: double.infinity,
                  height: mobile ? 150 : 190,
                  radius: 16,
                  light: light,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _block({
    required double width,
    required double height,
    required bool light,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: light
            ? const Color(0xFFE5E7EB)
            : const Color(0xFF171A20),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
