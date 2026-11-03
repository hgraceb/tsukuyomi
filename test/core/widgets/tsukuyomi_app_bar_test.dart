import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';

void main() {
  for (final sliver in [false, true]) {
    for (final leading in ['none', 'back', 'close', 'drawer']) {
      testWidgets(
        'App bar aligns content and keeps navigation clickable: sliver=$sliver, leading=$leading',
        (tester) async {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData;
          final hasLeading = leading != 'none';
          final dismissible = leading == 'back' || leading == 'close';

          Widget page(BuildContext context) => Scaffold(
            drawer: leading == 'drawer' ? const Drawer(child: Text('Drawer content')) : null,
            appBar: sliver
                ? null
                : const PreferredSize(
                    preferredSize: Size.fromHeight(kToolbarHeight),
                    child: TsukuyomiAppBar(title: Text('Title')),
                  ),
            body: sliver
                ? CustomScrollView(
                    slivers: [
                      SliverStack(
                        children: [
                          TsukuyomiSliverAppBar(
                            title: const Text('Title'),
                            shadow: false,
                            actions: [
                              IconButton(
                                key: const ValueKey('actionButton'),
                                icon: const Icon(Icons.info_outline, key: ValueKey('actionIcon')),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const TsukuyomiSliverLeadingAppBar(),
                        ],
                      ),
                      const SliverToBoxAdapter(child: ListTile(title: Text('List title'))),
                    ],
                  )
                : const ListTile(title: Text('List title')),
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              initialRoute: dismissible ? '/detail' : '/',
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                fullscreenDialog: leading == 'close' && settings.name == '/detail',
                builder: page,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.getRect(find.text('Title')).left, hasLeading ? 56.0 : 16.0);
          expect(tester.getRect(find.text('List title')).left, 16.0);
          if (sliver) {
            final pageWidth = tester.getSize(find.byType(Scaffold).first).width;
            final action = find.byKey(const ValueKey('actionButton'));
            expect(pageWidth - tester.getRect(find.byKey(const ValueKey('actionIcon'))).right, 16.0);
            expect(tester.getSize(action), const Size.square(48.0));
            expect(tester.getSize(find.descendant(of: action, matching: find.byType(InkWell))), const Size.square(40.0));
          }
          final button = find.byWidgetPredicate((widget) => widget is BackButton || widget is CloseButton || widget is DrawerButton);
          if (hasLeading) {
            expect(button, findsOneWidget);
            final target = tester.getRect(button);
            final icon = find.descendant(of: button, matching: find.byType(Icon));
            final ink = find.descendant(of: button, matching: find.byType(InkWell));
            expect(target.size, const Size.square(48.0));
            expect(tester.getRect(icon).left, 16.0);
            expect(tester.getSize(ink), const Size.square(40.0));
            await tester.tapAt(Offset(target.right - 1.0, target.center.dy));
            await tester.pumpAndSettle();
            if (leading == 'drawer') {
              expect(find.text('Drawer content'), findsOneWidget);
            } else {
              expect(button, findsNothing);
              expect(tester.getRect(find.text('Title')).left, 16.0);
            }
          } else {
            expect(button, findsNothing);
          }
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.android}),
      );
    }
  }
}
