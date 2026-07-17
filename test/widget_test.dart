import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groumapapp_store/widgets/game_dialog.dart';

void main() {
  testWidgets('押印済み案内をGameDialogで表示できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showGameDialog(
                context: context,
                title: '本日は押印済みです',
                message: 'この店舗では、本日分のスタンプがすでに記録されています。',
                actions: [
                  GameDialogAction(
                    label: 'OK',
                    isPrimary: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              child: const Text('表示'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('表示'));
    await tester.pumpAndSettle();

    expect(find.text('本日は押印済みです'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('本日は押印済みです'), findsNothing);
  });
}
