import 'dart:ui';

import 'package:flutter/material.dart';

import 'custom_loading_indicator.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const ColoredBox(color: Color(0x6697A1AD)),
            ),
            const Center(
              child: CustomLoadingIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
