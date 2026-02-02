import 'package:flutter/material.dart';

class ErrorDialog {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
                if (details != null && details.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '詳細: $details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            if (onRetry != null)
              TextButton(
                child: const Text('再試行'),
                onPressed: onRetry,
              ),
            TextButton(
              child: const Text('閉じる'),
              onPressed: onDismiss ?? () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }
}

class SuccessSnackBar {
  static void show(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
