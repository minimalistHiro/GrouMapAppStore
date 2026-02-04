import 'package:flutter/material.dart';

class IconImagePickerField extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showRemove;
  final double size;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  const IconImagePickerField({
    super.key,
    required this.child,
    this.onTap,
    this.onRemove,
    this.showRemove = false,
    this.size = 96,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.borderColor = const Color(0xFFE0E0E0),
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: ClipOval(child: child),
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
      ),
    );
  }
}
