import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_patch/material.dart';

void main() {
  testWidgets('One drag can hide and reopen the indicator without scrolling the list', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var refreshCount = 0;
    await _pumpIndicator(tester, controller: controller, onRefresh: () async => refreshCount++);

    final indicator = find.descendant(of: find.byType(PatchedRefreshIndicator), matching: find.byType(SizeTransition));
    final item = find.byKey(const ValueKey('item'));
    final itemTop = tester.getTopLeft(item).dy;
    final gesture = await tester.startGesture(const Offset(200.0, 100.0));
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pump();
    expect(tester.getSize(indicator).height, greaterThan(0.0));

    await gesture.moveBy(const Offset(0.0, -220.0));
    await tester.pump();
    expect(tester.getSize(indicator).height, 0.0);
    expect(controller.offset, 0.0);
    expect(tester.getTopLeft(item).dy, itemTop);
    expect(refreshCount, 0);

    await gesture.moveBy(const Offset(0.0, 220.0));
    await tester.pump();
    expect(tester.getSize(indicator).height, greaterThan(0.0));
    expect(controller.offset, 0.0);
    expect(tester.getTopLeft(item).dy, itemTop);
    expect(refreshCount, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(refreshCount, 1);
  });

  testWidgets('A ballistic update after retreat cancels the armed indicator', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var refreshCount = 0;
    await _pumpIndicator(tester, controller: controller, onRefresh: () async => refreshCount++);

    final context = tester.element(find.byType(ListView));
    void update(double delta, {required bool dragging}) {
      ScrollUpdateNotification(
        context: context,
        metrics: controller.position,
        scrollDelta: delta,
        dragDetails: dragging ? DragUpdateDetails(globalPosition: Offset.zero) : null,
      ).dispatch(context);
    }

    ScrollStartNotification(
      context: context,
      metrics: controller.position,
      dragDetails: DragStartDetails(),
    ).dispatch(context);
    update(-200.0, dragging: true);
    await tester.pump();
    update(150.0, dragging: true);
    await tester.pump();

    // 模拟回弹产生的不带拖动详情的滚动通知
    update(0.0, dragging: false);
    await tester.pumpAndSettle();
    expect(refreshCount, 0);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });
}

Future<void> _pumpIndicator(WidgetTester tester, {required ScrollController controller, required Future<void> Function() onRefresh}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PatchedRefreshIndicator(
          scrollController: controller,
          onRefresh: onRefresh,
          child: ListView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            children: const [SizedBox(key: ValueKey('item'), height: 1200.0)],
          ),
        ),
      ),
    ),
  );
}
