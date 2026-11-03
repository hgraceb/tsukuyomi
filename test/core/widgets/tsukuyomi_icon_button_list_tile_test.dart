import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final density in [VisualDensity.standard, VisualDensity.compact]) {
      testWidgets(
        'Icon buttons keep 16dp visual margins in $direction at $density',
        (tester) async {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData.copyWith(visualDensity: density);

          for (final leading in [false, true]) {
            for (final trailing in [false, true]) {
              var pressed = 0;
              IconButton button(String side) => IconButton(
                key: ValueKey('${side}Button'),
                icon: Icon(Icons.info_outline, key: ValueKey('${side}Icon')),
                onPressed: () => pressed++,
              );

              await tester.pumpWidget(
                MaterialApp(
                  theme: theme,
                  builder: (context, child) => Directionality(textDirection: direction, child: child!),
                  home: Scaffold(
                    body: Column(
                      children: [
                        TsukuyomiIconButtonListTile(
                          title: const Text('Title'),
                          subtitle: const Text('Subtitle'),
                          leading: leading ? button('leading') : null,
                          trailing: trailing ? button('trailing') : null,
                        ),
                        ListTile(
                          title: const Text('Baseline'),
                          subtitle: const Text('Baseline subtitle'),
                          leading: leading ? IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}) : null,
                          trailing: trailing ? IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              final row = tester.getRect(find.widgetWithText(ListTile, 'Title'));
              final title = tester.getRect(find.text('Title'));
              final subtitle = tester.getRect(find.text('Subtitle'));
              final baseline = tester.getRect(find.widgetWithText(ListTile, 'Baseline'));
              final ltr = direction == TextDirection.ltr;
              expect(row.height, baseline.height);
              expect(subtitle.left, title.left);
              expect(subtitle.right, title.right);

              if (leading) {
                final icon = tester.getRect(find.byKey(const ValueKey('leadingIcon')));
                expect(ltr ? icon.left - row.left : row.right - icon.right, 16.0);
                expect(ltr ? title.left - icon.right : icon.left - title.right, 16.0);
              } else {
                expect(ltr ? title.left - row.left : row.right - title.right, 16.0);
              }
              if (trailing) {
                final icon = tester.getRect(find.byKey(const ValueKey('trailingIcon')));
                expect(ltr ? row.right - icon.right : icon.left - row.left, 16.0);
                expect(ltr ? icon.left - title.right : title.left - icon.right, 16.0);
              } else {
                expect(ltr ? row.right - title.right : title.left - row.left, 16.0);
              }

              for (final side in [if (leading) 'leading', if (trailing) 'trailing']) {
                final button = find.byKey(ValueKey('${side}Button'));
                final target = tester.getRect(button);
                final ink = find.descendant(of: button, matching: find.byType(InkWell));
                expect(target.size, const Size.square(48.0));
                expect(tester.getSize(find.byKey(ValueKey('${side}Icon'))), const Size.square(24.0));
                expect(tester.getSize(ink), const Size.square(40.0));
                expect(tester.widget<InkWell>(ink).splashFactory, theme.splashFactory);
                await tester.tapAt(Offset(target.left + 1.0, target.center.dy));
                await tester.tapAt(Offset(target.right - 1.0, target.center.dy));
                await tester.pump();
              }
              expect(pressed, 2 * ((leading ? 1 : 0) + (trailing ? 1 : 0)));
              expect(tester.takeException(), isNull);
            }
          }
        },
        variant: TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.android}),
      );
    }
  }

  testWidgets('Local vertical density is retained while horizontal spacing stays fixed', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData.copyWith(visualDensity: VisualDensity.standard);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListTileTheme(
            data: const ListTileThemeData(visualDensity: VisualDensity(horizontal: -3.0, vertical: -1.0)),
            child: Column(
              children: [
                TsukuyomiIconButtonListTile(
                  title: const Text('Title'),
                  subtitle: const Text('Subtitle'),
                  trailing: IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
                ),
                ListTile(
                  title: const Text('Baseline'),
                  subtitle: const Text('Baseline subtitle'),
                  trailing: IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final row = find.widgetWithText(ListTile, 'Title');
    final icon = find.descendant(of: row, matching: find.byType(Icon));
    expect(tester.getSize(row).height, tester.getSize(find.widgetWithText(ListTile, 'Baseline')).height);
    expect(tester.getRect(icon).left - tester.getRect(find.text('Title')).right, 16.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Row and button callbacks stay independent and disabled rows do not respond', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData;
    var rowPressed = 0;
    var buttonPressed = 0;
    for (final enabled in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TsukuyomiIconButtonListTile(
              enabled: enabled,
              title: const Text('Title'),
              textColor: Colors.red,
              trailing: IconButton(icon: const Icon(Icons.info_outline), onPressed: () => buttonPressed++),
              onTap: () => rowPressed++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Title'));
      await tester.pump();
      expect(rowPressed, 1);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(buttonPressed, enabled ? 1 : 2);
      expect(rowPressed, 1);
      expect(tester.takeException(), isNull);
    }
  });
}
