import 'package:flutter/material.dart';

class ImagePickerField extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showRemove;
  final double aspectRatio;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  const ImagePickerField({
    super.key,
    required this.child,
    required this.aspectRatio,
    this.onTap,
    this.onRemove,
    this.showRemove = false,
    this.borderRadius = 12,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.borderColor = const Color(0xFFE0E0E0),
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: child,
              ),
            ),
          ),
          if (showRemove)
            Positioned(
              top: -2,
              right: -2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ImagePickerPlaceholder extends StatelessWidget {
  final double aspectRatio;
  final TextStyle? textStyle;
  final Color iconColor;

  const ImagePickerPlaceholder({
    super.key,
    required this.aspectRatio,
    this.textStyle,
    this.iconColor = const Color(0xFF757575),
  });

  @override
  Widget build(BuildContext context) {
    final label = _ratioText(aspectRatio);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 32,
            color: iconColor,
          ),
          const SizedBox(height: 8),
          Text(
            '比率：$label',
            style: textStyle ?? const TextStyle(fontSize: 12, color: Color(0xFF757575)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _ratioText(double aspectRatio) {
  final ratio = aspectRatio >= 1 ? aspectRatio : 1 / aspectRatio;
  final intScale = (ratio * 1000).round();
  int a = intScale;
  int b = 1000;
  int gcd(int x, int y) => y == 0 ? x : gcd(y, x % y);
  final g = gcd(a, b);
  a ~/= g;
  b ~/= g;
  if (aspectRatio < 1) {
    final tmp = a;
    a = b;
    b = tmp;
  }
  return '$a:$b';
}
