import 'dart:math' as math;

import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {
  const CustomLoadingIndicator({
    super.key,
    this.size = 72,
    this.padding = 18,
    this.primaryColor = const Color(0xFFFF6B35),
  });

  final double size;
  final double padding;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = Color.lerp(Colors.white, primaryColor, 0.18)!;
    final shadowColor = primaryColor.withValues(alpha: 0.08);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _DotSpinner(primaryColor: primaryColor),
    );
  }
}

class _DotSpinner extends StatefulWidget {
  const _DotSpinner({required this.primaryColor});

  final Color primaryColor;

  @override
  State<_DotSpinner> createState() => _DotSpinnerState();
}

class _DotSpinnerState extends State<_DotSpinner>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 10;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Color.lerp(Colors.white, widget.primaryColor, 0.32)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spinnerSize = constraints.biggest.shortestSide;
        final dotSize = spinnerSize * 0.16;
        final radius = (spinnerSize - dotSize) / 2;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final activeIndex = _controller.value * _dotCount;

            return Stack(
              children: List.generate(_dotCount, (index) {
                final angle =
                    (-math.pi / 2) + (2 * math.pi * index / _dotCount);
                final left = radius + radius * math.cos(angle);
                final top = radius + radius * math.sin(angle);
                final distance = (activeIndex - index + _dotCount) % _dotCount;
                final emphasis = 1 - (distance / _dotCount);
                final scale = 0.72 + (emphasis * 0.42);
                final color =
                    Color.lerp(baseColor, widget.primaryColor, emphasis)!;

                return Positioned(
                  left: left,
                  top: top,
                  child: Transform.translate(
                    offset: Offset(-dotSize / 2, -dotSize / 2),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: 0.28 + (emphasis * 0.72),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
