import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'Default list text keeps symmetric 16dp margins in $direction',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (context, child) => Directionality(textDirection: direction, child: child!),
            home: const Scaffold(body: ListTile(title: Text('Default list item'))),
          ),
        );
        final row = tester.getRect(find.byType(ListTile));
        final text = tester.getRect(find.text('Default list item'));
        expect(text.left - row.left, 16.0);
        expect(row.right - text.right, 16.0);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.android}),
    );
  }
}
