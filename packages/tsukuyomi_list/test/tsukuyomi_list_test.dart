import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

void expectList({required int length, required List<int> visible}) {
  assert(length > 0, length);
  final hidden = List.generate(length, (i) => i).toSet().difference(visible.toSet());
  for (final i in visible) {
    expect(find.text('$i'), findsOneWidget);
  }
  for (final i in hidden) {
    expect(find.text('$i'), findsNothing);
  }
}

void main() {
  testWidgets('TsukuyomiList respects initialScrollIndex', (WidgetTester tester) async {
    const itemCount = 10;

    Widget builder(int initialScrollIndex) {
      return Directionality(
        key: ValueKey(initialScrollIndex),
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('$index')),
          initialScrollIndex: initialScrollIndex,
        ),
      );
    }

    // 可以指定初始元素并越界显示
    for (int i = 0; i < itemCount; i++) {
      await tester.pumpWidget(builder(i));
      expectList(length: itemCount, visible: List.generate(math.min(6, itemCount - i), (index) => index + i));
    }
  });

  testWidgets('TsukuyomiList respects TsukuyomiListController.jumpToIndex', (WidgetTester tester) async {
    const itemCount = 10;
    final controller = TsukuyomiListController();

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('$index')),
          controller: controller,
        ),
      );
    }

    // 可以跳转到指定位置的元素并越界显示
    await tester.pumpWidget(builder());
    for (int i = 0; i < itemCount; i++) {
      controller.jumpToIndex(i);
      await tester.pump();
      expectList(length: itemCount, visible: List.generate(math.min(6, itemCount - i), (index) => index + i));
    }
  });

  testWidgets('TsukuyomiList respects TsukuyomiListController.slideViewport', (WidgetTester tester) async {
    const itemCount = 3;
    final controller = TsukuyomiListController();

    Widget builder(int initialScrollIndex) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => SizedBox(height: 300.0, child: Text('$index')),
          controller: controller,
        ),
      );
    }

    // 默认只显示前面两个元素
    await tester.pumpWidget(builder(0));
    expectList(length: itemCount, visible: [0, 1]);

    // 滚动半个屏幕的距离
    unawaited(controller.slideViewport(0.5));
    await tester.pump();
    expectList(length: itemCount, visible: [0, 1]);
    await tester.pumpAndSettle();
    expectList(length: itemCount, visible: [1, 2]);

    // 不进行越界滚动
    unawaited(controller.slideViewport(0.5));
    await tester.pump();
    expectList(length: itemCount, visible: [1, 2]);
    await tester.pumpAndSettle();
    expectList(length: itemCount, visible: [1, 2]);
  });
}
