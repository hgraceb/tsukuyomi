import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

void expectList({List<int> visible = const [], List<int> hidden = const []}) {
  for (final i in visible) {
    expect(find.text('$i'), findsOneWidget);
  }
  for (final i in hidden) {
    expect(find.text('$i'), findsNothing);
  }
}

void main() {
  testWidgets('TsukuyomiList respects initialScrollIndex', (WidgetTester tester) async {
    Widget builder(int initialScrollIndex) {
      return Directionality(
        key: ValueKey(initialScrollIndex),
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: 3,
          itemBuilder: (context, index) => SizedBox(height: 300.0, child: Text('$index')),
          initialScrollIndex: initialScrollIndex,
        ),
      );
    }

    // 从第一个元素开始显示
    await tester.pumpWidget(builder(0));
    expectList(visible: [0, 1], hidden: [2]);

    // 从第二个元素开始显示
    await tester.pumpWidget(builder(1));
    expectList(visible: [1, 2], hidden: [0]);

    // 从第三个元素开始显示
    await tester.pumpWidget(builder(2));
    expectList(visible: [2], hidden: [0, 1]);
  });

  testWidgets('TsukuyomiList respects TsukuyomiListController.jumpToIndex', (WidgetTester tester) async {
    final controller = TsukuyomiListController();

    Widget builder(int initialScrollIndex) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: 3,
          itemBuilder: (context, index) => SizedBox(height: 300.0, child: Text('$index')),
          controller: controller,
        ),
      );
    }

    // 默认只显示前面两个元素
    await tester.pumpWidget(builder(0));
    expectList(visible: [0, 1], hidden: [2]);

    // 可以跳转到当前位置的元素
    controller.jumpToIndex(0);
    await tester.pump();
    expectList(visible: [0, 1], hidden: [2]);

    // 可以跳转到指定位置的元素
    controller.jumpToIndex(1);
    await tester.pump();
    expectList(visible: [1, 2], hidden: [0]);

    // 可以跳转到指定位置的元素并越界显示
    controller.jumpToIndex(2);
    await tester.pump();
    expectList(visible: [2], hidden: [0, 1]);
  });

  testWidgets('TsukuyomiList respects TsukuyomiListController.slideViewport', (WidgetTester tester) async {
    final controller = TsukuyomiListController();

    Widget builder(int initialScrollIndex) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TsukuyomiList.builder(
          itemCount: 3,
          itemBuilder: (context, index) => SizedBox(height: 300.0, child: Text('$index')),
          controller: controller,
        ),
      );
    }

    // 默认只显示前面两个元素
    await tester.pumpWidget(builder(0));
    expectList(visible: [0, 1], hidden: [2]);

    // 滚动半个屏幕的距离
    unawaited(controller.slideViewport(0.5));
    await tester.pump();
    expectList(visible: [0, 1], hidden: [2]);
    await tester.pumpAndSettle();
    expectList(visible: [1, 2], hidden: [0]);

    // 不进行越界滚动
    unawaited(controller.slideViewport(0.5));
    await tester.pump();
    expectList(visible: [1, 2], hidden: [0]);
    await tester.pumpAndSettle();
    expectList(visible: [1, 2], hidden: [0]);
  });
}
