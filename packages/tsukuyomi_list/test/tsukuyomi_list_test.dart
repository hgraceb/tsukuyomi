import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

void main() {
  void expectList({required int length, required List<int> visible}) {
    final hidden = List.generate(length, (i) => i).toSet().difference(visible.toSet());
    for (final i in visible) {
      expect(find.text('$i'), findsOneWidget);
    }
    for (final i in hidden) {
      expect(find.text('$i'), findsNothing);
    }
  }

  testWidgets('TsukuyomiList respects initialScrollIndex', (WidgetTester tester) async {
    final itemKeys = List.generate(10, (index) => index);
    final controller = TsukuyomiListController();

    Widget builder(index) {
      return Directionality(
        key: ValueKey(index),
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemKeys: itemKeys,
          itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('$index')),
          controller: controller,
          initialScrollIndex: index,
        ),
      );
    }

    // 可以指定初始元素并越界显示
    for (int i = 0; i < itemKeys.length; i++) {
      await tester.pumpWidget(builder(i));
      expect(controller.centerIndex, i);
      expect(controller.anchorIndex, i);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: List.generate(math.min(6, itemKeys.length - i), (index) => index + i));
    }
  });

  testWidgets('TsukuyomiList respects TsukuyomiListController.jumpToIndex', (WidgetTester tester) async {
    final itemKeys = List.generate(10, (index) => index);
    final controller = TsukuyomiListController();

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemKeys: itemKeys,
          itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('$index')),
          controller: controller,
        ),
      );
    }

    // 可以跳转到指定位置的元素并越界显示
    await tester.pumpWidget(builder());
    for (int i = 0; i < itemKeys.length; i++) {
      controller.jumpToIndex(i);
      await tester.pump();
      expect(controller.centerIndex, i);
      expect(controller.anchorIndex, i);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: List.generate(math.min(6, itemKeys.length - i), (index) => index + i));
    }
  });

  testWidgets('TsukuyomiList respects TsukuyomiListController.slideViewport', (WidgetTester tester) async {
    final itemKeys = List.generate(20, (index) => index);
    final controller = TsukuyomiListController();

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemKeys: itemKeys,
          itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('$index')),
          controller: controller,
        ),
      );
    }

    // 默认显示首屏的元素
    await tester.pumpWidget(builder());
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 0);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

    // 滚动零个屏幕的距离
    unawaited(controller.slideViewport(0.0));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 0);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

    // 正向滚动半个屏幕的距离
    unawaited(controller.slideViewport(0.5));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 4);
    expect(controller.position.pixels, 300.0);
    expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);
    // 正向滚动一个屏幕的距离
    unawaited(controller.slideViewport(1.0));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 12);
    expect(controller.position.pixels, 900.0);
    expectList(length: itemKeys.length, visible: [9, 10, 11, 12, 13, 14]);
    // 正向滚动越界时停止滚动
    unawaited(controller.slideViewport(1.0));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 19);
    expect(controller.position.pixels, 1400.0);
    expectList(length: itemKeys.length, visible: [14, 15, 16, 17, 18, 19]);

    // 逆向滚动一个屏幕的距离
    unawaited(controller.slideViewport(-1.0));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 10);
    expect(controller.position.pixels, 800.0);
    expectList(length: itemKeys.length, visible: [8, 9, 10, 11, 12, 13]);
    // 逆向滚动半个屏幕的距离
    unawaited(controller.slideViewport(-0.5));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 7);
    expect(controller.position.pixels, 500.0);
    expectList(length: itemKeys.length, visible: [5, 6, 7, 8, 9, 10]);
    // 逆向滚动越界时停止滚动
    unawaited(controller.slideViewport(-1.0));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 0);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
  });

  testWidgets('TsukuyomiList respects anchor at default', (WidgetTester tester) async {
    final itemKeys = List.generate(10, (index) => index);
    final controller = TsukuyomiListController();

    Widget builder({required List<double> itemHeights}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemKeys: itemKeys,
          itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('$index')),
          controller: controller,
          initialScrollIndex: 4,
        ),
      );
    }

    // 初始化列表并让中间元素作为锚点元素
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 4);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);

    // 逆向滚动一定距离让第一个元素作为新的锚点元素
    unawaited(controller.slideViewport(-1.0));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 0);
    expect(controller.position.pixels, -400.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
    // 列表项尺寸动态增大时能够锚定第一个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 0);
    expect(controller.position.pixels, -600.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3]);
    // 列表项尺寸动态减小时能够锚定第一个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 0);
    expect(controller.position.pixels, -400.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

    // 正向滚动一定距离让第二个元素作为新的锚点元素
    unawaited(controller.slideViewport(75 / 600));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 1);
    expect(controller.position.pixels, -325.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5, 6]);
    // 列表项尺寸动态增大时能够锚定第二个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 1);
    expect(controller.position.pixels, -475.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4]);
    // 列表项尺寸动态减小时能够锚定第二个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 1);
    expect(controller.position.pixels, -325.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5, 6]);

    // 正向滚动一定距离让倒数第二个元素作为新的锚点元素
    unawaited(controller.slideViewport(250 / 600));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 8);
    expect(controller.position.pixels, -75.0);
    expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8, 9]);
    // 列表项尺寸动态增大时能够锚定倒数第二个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 8);
    expect(controller.position.pixels, 125.0);
    expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8]);
    // 列表项尺寸动态减小时能够锚定倒数第二个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 8);
    expect(controller.position.pixels, -75.0);
    expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8, 9]);

    // 正向滚动一定距离让最后一个元素作为新的锚点元素
    unawaited(controller.slideViewport(1.0));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 9);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);
    // 列表项尺寸动态增大时能够锚定最后一个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 9);
    expect(controller.position.pixels, 250.0);
    expectList(length: itemKeys.length, visible: [5, 6, 7, 8, 9]);
    // 列表项尺寸动态减小时能够锚定最后一个元素的位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 4);
    expect(controller.anchorIndex, 9);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);
  });

  testWidgets('TsukuyomiList respects anchor at 0.5', (WidgetTester tester) async {
    final itemKeys = List.generate(10, (index) => index);
    final controller = TsukuyomiListController();

    Widget builder({required List<double> itemHeights}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemKeys: itemKeys,
          itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('$index')),
          controller: controller,
          anchor: 0.5,
        ),
      );
    }

    // 初始化列表并让第一个元素作为锚点元素
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 0);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

    // 正向滚动半个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
    unawaited(controller.slideViewport(0.5));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 6);
    expect(controller.position.pixels, 300.0);
    expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);
    // 列表项尺寸动态增大时能够锚定滚动位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 6);
    expect(controller.position.pixels, 600.0);
    expectList(length: itemKeys.length, visible: [4, 5, 6, 7]);
    // 列表项尺寸动态减小时能够锚定滚动位置
    await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 6);
    expect(controller.position.pixels, 300.0);
    expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);

    // 逆向滚动半个屏幕的距离可以回到原点
    unawaited(controller.slideViewport(-0.5));
    await tester.pumpAndSettle();
    expect(controller.centerIndex, 0);
    expect(controller.anchorIndex, 3);
    expect(controller.position.pixels, 0.0);
    expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
  });
}
