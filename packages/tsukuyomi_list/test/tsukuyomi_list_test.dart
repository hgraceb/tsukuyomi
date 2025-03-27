import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

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
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    // 从第二个元素开始显示
    await tester.pumpWidget(builder(1));
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // 从第三个元素开始显示
    await tester.pumpWidget(builder(2));
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
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
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    // 可以跳转到当前位置的元素
    controller.jumpToIndex(0);
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    // 可以跳转到指定位置的元素
    controller.jumpToIndex(1);
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // 可以跳转到指定位置的元素并越界显示
    controller.jumpToIndex(2);
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
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
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    // 滚动半个屏幕的距离
    unawaited(controller.slideViewport(0.5));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // 不进行越界滚动
    unawaited(controller.slideViewport(0.5));
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
