import 'package:flutter/material.dart';

import '../theme/store_ui.dart';
import 'custom_button.dart';

class GameDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;

  const GameDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.color,
  });
}

Future<void> showGameDialog({
  required BuildContext context,
  required String title,
  required String message,
  required List<GameDialogAction> actions,
  IconData icon = Icons.info_outline,
  Color headerColor = StoreUi.primary,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => GameDialog(
      title: title,
      message: message,
      actions: actions,
      icon: icon,
      headerColor: headerColor,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class GameDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color headerColor;
  final List<GameDialogAction> actions;

  const GameDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.icon = Icons.info_outline,
    this.headerColor = StoreUi.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9BB8D4).withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: 8,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...actions.asMap().entries.map((entry) {
                  final action = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == actions.length - 1 ? 0 : 10,
                    ),
                    child: CustomButton(
                      text: action.label,
                      onPressed: action.onPressed,
                      backgroundColor: action.isPrimary
                          ? action.color ?? StoreUi.primary
                          : const Color(0xFFF0F0F0),
                      textColor: action.isPrimary
                          ? Colors.white
                          : const Color(0xFF6B6B6B),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
