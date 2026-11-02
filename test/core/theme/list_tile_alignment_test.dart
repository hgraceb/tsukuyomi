import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';

void main() {
  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    for (final direction in TextDirection.values) {
      for (final safeArea in [false, true]) {
        testWidgets('List actions align on $platform, $direction, safeArea=$safeArea', (tester) async {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData;
          final padding = safeArea ? const EdgeInsets.fromLTRB(24.0, 0.0, 40.0, 0.0) : EdgeInsets.zero;
          var pressed = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(padding: padding),
                child: Directionality(textDirection: direction, child: child!),
              ),
              home: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    TsukuyomiSliverAppBar(
                      title: const Text('Title'),
                      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
                    ),
                    SliverSafeArea(
                      top: false,
                      bottom: false,
                      sliver: SliverList.list(
                        children: [
                          ListTile(
                            title: const Text('Chapter'),
                            subtitle: const Text('Progress'),
                            trailing: IconButton(onPressed: () => pressed++, icon: const Icon(Icons.refresh)),
                          ),
                          const ListTile(leading: Icon(Icons.palette), title: Text('Settings')),
                          Card(
                            child: ListTile(
                              title: const Text('Dark mode'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                              trailing: Switch(value: true, onChanged: (_) {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final action = find.byIcon(Icons.search);
          final trailing = find.byIcon(Icons.refresh);
          expect(tester.getCenter(trailing).dx, closeTo(tester.getCenter(action).dx, 0.01));
          final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
          final title = tester.getRect(find.text('Chapter'));
          final leading = tester.getRect(find.byIcon(Icons.palette));
          if (direction == TextDirection.ltr) {
            expect(title.left, padding.left + 16.0);
            expect(leading.left, padding.left + 16.0);
          } else {
            expect(width - title.right, padding.right + 16.0);
            expect(width - leading.right, padding.right + 16.0);
          }
          final button = tester.getRect(find.widgetWithIcon(IconButton, Icons.refresh));
          final expectedSize = platform == TargetPlatform.android ? 48.0 : 40.0;
          expect(button.size, Size.square(expectedSize));
          await tester.tapAt(Offset(button.right - 1.0, button.center.dy));
          expect(pressed, 1);
          final card = tester.getRect(find.descendant(of: find.byType(Card), matching: find.byType(Material)).first);
          final toggle = tester.getRect(find.byType(Switch));
          final toggleMargin = direction == TextDirection.ltr ? card.right - toggle.right : toggle.left - card.left;
          expect(toggleMargin, 16.0);
          expect(tester.takeException(), isNull);
        }, variant: TargetPlatformVariant({platform}));
      }
    }
  }
}
