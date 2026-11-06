import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';

void main() {
  testWidgets('Cards and outlined buttons keep each theme border color', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    for (final config in container.read(themePredefinedProvider)) {
      await tester.pumpWidget(
        MaterialApp(
          theme: TsukuyomiTheme(config).themeData,
          home: Scaffold(
            body: Column(
              children: [
                const Card(child: Text('Card')),
                OutlinedButton(onPressed: () {}, child: const Text('Button')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Material>(find.descendant(of: find.byType(Card), matching: find.byType(Material)));
      final button = tester.widget<Material>(find.descendant(of: find.byType(OutlinedButton), matching: find.byType(Material)));
      expect(
        {
          'card': (card.shape! as OutlinedBorder).side.color,
          'button': (button.shape! as OutlinedBorder).side.color,
        },
        {'card': config.border, 'button': config.border},
        reason: config.name,
      );
    }
  });
}
