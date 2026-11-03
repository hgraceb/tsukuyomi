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

          Widget page(BuildContext context) {
            final drawer = leading == 'drawer' ? const Drawer(child: Text('Drawer content')) : null;
            const list = ListTile(title: Text('List title'));
            if (!sliver) {
              return Scaffold(
                drawer: drawer,
                appBar: const PreferredSize(
                  preferredSize: Size.fromHeight(kToolbarHeight),
                  child: TsukuyomiAppBar(title: Text('Title')),
                ),
                body: list,
              );
            }
            return Scaffold(
              drawer: drawer,
              body: CustomScrollView(
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
                  const SliverToBoxAdapter(child: list),
                ],
              ),
            );
          }

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

          // Sliver 用例的 action 和末尾占位会触发原生的标题靠左布局
          final centered = !sliver && (theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.macOS);
          _expectTitle(tester, centered: centered, start: hasLeading ? 56.0 : 16.0);
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
              _expectTitle(tester, centered: centered, start: 16.0);
            }
          } else {
            expect(button, findsNothing);
          }
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.all(),
      );
    }
  }

  testWidgets('Sliver app bar without actions retains native title alignment', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: CustomScrollView(
            slivers: const [
              TsukuyomiSliverAppBar(title: Text('Title'), shadow: false),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final centered = theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.macOS;
    _expectTitle(tester, centered: centered, start: 16.0);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());
}

void _expectTitle(WidgetTester tester, {required bool centered, required double start}) {
  final title = tester.getRect(find.text('Title'));
  if (centered) {
    final pageWidth = tester.getSize(find.byType(Scaffold).first).width;
    expect(title.center.dx, pageWidth / 2.0);
  } else {
    expect(title.left, start);
  }
}
