import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_patch/material.dart';

void main() {
  for (final width in [360.0, 800.0]) {
    testWidgets('Short tabs keep a screen-wide viewport while dragging: width=$width', (tester) async {
      tester.view.physicalSize = Size(width, 600.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DefaultTabController(
              length: 2,
              child: PatchedTabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                tabs: [
                  Tab(text: 'First'),
                  Tab(text: 'Second'),
                ],
              ),
            ),
          ),
        ),
      );

      final viewport = find.byType(SingleChildScrollView);
      final tabs = find.byType(Tab);
      final viewportRect = tester.getRect(viewport);
      final tabsRect = tester.getRect(tabs.first).expandToInclude(tester.getRect(tabs.last));
      expect(viewportRect.width, width);
      expect(tabsRect.center.dx, moreOrLessEquals(viewportRect.center.dx));

      final gesture = await tester.startGesture(tester.getCenter(tabs.first));
      await gesture.moveBy(const Offset(60.0, 0.0));
      await tester.pump();

      expect(tester.getSize(viewport).width, width);
      for (final tab in [tabs.first, tabs.last]) {
        final rect = tester.getRect(tab);
        expect(rect.left, greaterThanOrEqualTo(viewportRect.left));
        expect(rect.right, lessThanOrEqualTo(viewportRect.right));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    });
  }
}
