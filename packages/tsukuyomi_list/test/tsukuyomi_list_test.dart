import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

void main() {
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

  testWidgets('TsukuyomiList respects initialScrollIndex', (WidgetTester tester) async {
    const itemCount = 10;
    final controller = TsukuyomiListController();

    Widget builder(int initialScrollIndex) {
      return Directionality(
        key: ValueKey(initialScrollIndex),
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('$index')),
          controller: controller,
          initialScrollIndex: initialScrollIndex,
        ),
      );
    }

    // 可以指定初始元素并越界显示
    for (int i = 0; i < itemCount; i++) {
      await tester.pumpWidget(builder(i));
      expect(controller.position.pixels, 0.0);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemCount, visible: List.generate(math.min(6, itemCount - i), (index) => index + i));
    }
  });

  testWidgets('TsukuyomiList respects TsukuyomiListController.slideViewport', (WidgetTester tester) async {
    const itemCount = 20;
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

    // 默认显示首屏的元素
    int current = 0;
    await tester.pumpWidget(builder());
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));

    // 滚动零个屏幕的距离
    current += 0;
    unawaited(controller.slideViewport(0.0));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));

    // 正向滚动半个屏幕的距离
    current += 3;
    unawaited(controller.slideViewport(0.5));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));

    // 正向滚动一个屏幕的距离
    current += 6;
    unawaited(controller.slideViewport(1.0));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));

    // 正向滚动越界时停止滚动
    current += 5;
    unawaited(controller.slideViewport(1.0));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));

    // 逆向滚动一个屏幕的距离
    current -= 6;
    unawaited(controller.slideViewport(-1.0));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));

    // 逆向滚动半个屏幕的距离
    current -= 3;
    unawaited(controller.slideViewport(-0.5));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));

    // 逆向滚动越界时停止滚动
    current -= 5;
    unawaited(controller.slideViewport(-1.0));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, current * 100.0);
    expectList(length: itemCount, visible: List.generate(6, (i) => i + current));
    expect(current, 0);
  });

  testWidgets('TsukuyomiList respects anchor', (WidgetTester tester) async {
    const itemCount = 20;
    final controller = TsukuyomiListController();

    Widget builder({required double anchor, required List<double> itemHeights}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('$index')),
          controller: controller,
          anchor: anchor,
        ),
      );
    }

    // 初始化列表并正向滚动半个屏幕的距离
    await tester.pumpWidget(builder(anchor: 0.5, itemHeights: List.generate(itemCount, (index) => 100.0)));
    unawaited(controller.slideViewport(0.5));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, 300.0);
    expectList(length: itemCount, visible: [3, 4, 5, 6, 7, 8]);

    // 列表项尺寸动态增大时能够锚定滚动位置
    await tester.pumpWidget(builder(anchor: 0.5, itemHeights: List.generate(itemCount, (index) => 150.0)));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, 600.0);
    expectList(length: itemCount, visible: [4, 5, 6, 7]);

    // 列表项尺寸动态减小时能够锚定滚动位置
    await tester.pumpWidget(builder(anchor: 0.5, itemHeights: List.generate(itemCount, (index) => 100.0)));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, 300.0);
    expectList(length: itemCount, visible: [3, 4, 5, 6, 7, 8]);

    // 逆向滚动半个屏幕的距离可以回到原点
    unawaited(controller.slideViewport(-0.5));
    await tester.pumpAndSettle();
    expect(controller.position.pixels, 0.0);
    expectList(length: itemCount, visible: [0, 1, 2, 3, 4, 5]);
  });
}
