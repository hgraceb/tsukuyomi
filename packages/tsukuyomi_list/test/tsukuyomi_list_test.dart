import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

import 'tsukuyomi_list_util.dart';

void main() {
  group('TsukuyomiList respects empty items', () {
    for (final initialScrollIndex in [0, 1]) {
      testWidgets('when initialized with index $initialScrollIndex', (WidgetTester tester) async {
        final controller = TsukuyomiListController();

        Widget builder() {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: TsukuyomiList.builder(
              itemKeys: const [],
              itemBuilder: (context, index) => throw StateError('Empty lists must not build items'),
              controller: controller,
              initialScrollIndex: initialScrollIndex,
            ),
          );
        }

        // 构造参数允许空列表，此时索引应统一回到 0
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 0);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
        expect(controller.position.minScrollExtent, 0.0);
        expect(controller.position.maxScrollExtent, 0.0);
        // 空列表上的跳转和翻页不应产生滚动
        controller.jumpToIndex(0);
        await tester.pump();
        await controller.slideViewport(-1.0);
        await controller.slideViewport(1.0);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
        expect(controller.position.isScrollingNotifier.value, false);
      });
    }

    testWidgets('when items are added and removed repeatedly', (WidgetTester tester) async {
      const itemHeight = 100.0;
      final itemKeys = <int>[];
      final controller = TsukuyomiListController();
      final viewportHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final visibleItemCount = viewportHeight ~/ itemHeight;

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeight, child: Text('${itemKeys[index]}')),
            controller: controller,
          ),
        );
      }

      await tester.pumpWidget(builder());
      // 使用同一个可变列表，覆盖首次添加和清空后再次添加
      for (final firstKey in [0, 100]) {
        itemKeys.addAll(List.generate(10, (index) => firstKey + index));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 0);
        expectList(tester, visible: itemKeys.take(visibleItemCount).toList());
        final firstItem = find.text('$firstKey');
        final initialTop = tester.getTopLeft(firstItem).dy;
        // 重新添加的数据必须恢复锚点 key，插入首项后才能继续锚定原来的内容
        itemKeys.insert(0, firstKey - 1);
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 1);
        expect(tester.getTopLeft(firstItem).dy, moreOrLessEquals(initialTop));
        // 先滚到末尾再清空，验证旧的锚点和滚动偏移不会残留
        controller.jumpToIndex(itemKeys.length - 1);
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, itemKeys.length - 1);
        itemKeys.clear();
        await tester.pumpWidget(builder());
        await tester.pump();
        expect(controller.anchorIndex, 0);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
        expect(find.byType(Text), findsNothing);
      }
    });

    testWidgets('when controller changes and list is disposed', (WidgetTester tester) async {
      final firstController = TsukuyomiListController();
      final secondController = TsukuyomiListController();

      Widget builder(TsukuyomiListController controller) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: const [],
            itemBuilder: (context, index) => throw StateError('Empty lists must not build items'),
            controller: controller,
          ),
        );
      }

      await tester.pumpWidget(builder(firstController));
      expect(firstController.position.hasContentDimensions, true);
      await tester.pumpWidget(builder(secondController));
      expect(() => firstController.position, throwsAssertionError);
      expect(secondController.position.hasContentDimensions, true);
      await tester.pumpWidget(const SizedBox());
      expect(() => secondController.position, throwsAssertionError);
    });
  });

  group('TsukuyomiList respects anchor', () {
    testWidgets('when default', (WidgetTester tester) async {
      final itemKeys = List.generate(10, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder({required List<double> itemHeights}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            initialScrollIndex: 4,
          ),
        );
      }

      // 初始化列表并让中间元素作为锚点元素
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 4);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一定距离让第一个元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);
      // 列表项尺寸动态增大时能够锚定第一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3]);
      // 列表项尺寸动态减小时能够锚定第一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 正向滚动一定距离让第二个元素作为新的锚点元素
      unawaited(controller.slideViewport(75 / 600));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 1);
      expect(controller.position.pixels, moreOrLessEquals(-25.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5, 6]);
      // 列表项尺寸动态增大时能够锚定第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 1);
      expect(controller.position.pixels, moreOrLessEquals(-25.0));
      expectList(tester, visible: [0, 1, 2, 3, 4]);
      // 列表项尺寸动态减小时能够锚定第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 1);
      expect(controller.position.pixels, moreOrLessEquals(-25.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5, 6]);

      // 正向滚动一定距离让倒数第二个元素作为新的锚点元素
      unawaited(controller.slideViewport(250 / 600));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, moreOrLessEquals(-475.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8, 9]);
      // 列表项尺寸动态增大时能够锚定倒数第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, moreOrLessEquals(-475.0));
      expectList(tester, visible: [4, 5, 6, 7, 8]);
      // 列表项尺寸动态减小时能够锚定倒数第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, moreOrLessEquals(-475.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8, 9]);

      // 正向滚动一定距离让最后一个元素作为新的锚点元素
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);
      // 列表项尺寸动态增大时能够锚定最后一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [5, 6, 7, 8, 9]);
      // 列表项尺寸动态减小时能够锚定最后一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);
    });

    final frameDurations = {
      '16ms': const Duration(milliseconds: 16),
      '60Hz': Duration(microseconds: (Duration.microsecondsPerSecond / 60).round()),
    };
    for (final frame in frameDurations.entries) {
      testWidgets('when 0.5 (${frame.key})', (WidgetTester tester) async {
        final itemKeys = List.generate(10, (index) => index);
        final controller = TsukuyomiListController();

        Widget builder({required List<double> itemHeights}) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: TsukuyomiList.builder(
              itemKeys: itemKeys,
              itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
              controller: controller,
              anchor: 0.5,
            ),
          );
        }

        // 初始化列表并让第一个元素作为锚点元素
        await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
        expect(controller.anchorIndex, 0);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
        expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

        // 正向滚动半个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
        unawaited(controller.slideViewport(0.5));
        await tester.pumpAndSettle(frame.value);
        expect(controller.anchorIndex, 5);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [3, 4, 5, 6, 7, 8]);
        // 列表项尺寸动态增大时能够锚定滚动位置
        await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 200.0)));
        await tester.pump();
        expect(controller.anchorIndex, 5);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [4, 5, 6]);
        // 列表项尺寸动态减小时能够锚定滚动位置
        await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
        await tester.pump();
        expect(controller.anchorIndex, 5);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [3, 4, 5, 6, 7, 8]);

        // 逆向滚动半个屏幕的距离可以回到原点
        unawaited(controller.slideViewport(-0.5));
        await tester.pumpAndSettle(frame.value);
        expect(controller.anchorIndex, 2);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [0, 1, 2, 3, 4, 5]);
      });
    }

    testWidgets('when adding single item to start and end', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(10, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: 9,
          ),
        );
      }

      // 初始化列表并让最后一个元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一个元素的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0 / 6));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);

      // 在列表首尾位置同时添加单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.insert(0, itemKeys.length);
        itemKeys.insert(itemKeys.length, itemKeys.length);
        itemHeights.insert(0, 100.0 + random.nextInt(100));
        itemHeights.insert(itemHeights.length, 100.0 + random.nextInt(100));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [3, 4, 5, 6, 7, 8]);
      }
    });

    testWidgets('when adding multi items to start and end', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(10, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: 9,
          ),
        );
      }

      // 初始化列表并让最后一个元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一个元素的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0 / 6));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);

      // 在列表首尾位置同时添加多个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.insertAll(0, List.generate(100, (index) => itemKeys.length + index));
        itemKeys.insertAll(itemKeys.length, List.generate(100, (index) => itemKeys.length + index));
        itemHeights.insertAll(0, List.generate(100, (index) => 100.0 + random.nextInt(100)));
        itemHeights.insertAll(itemHeights.length, List.generate(100, (index) => 100.0 + random.nextInt(100)));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i * 100);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [3, 4, 5, 6, 7, 8]);
      }
    });

    testWidgets('when removing single item at anchor', (WidgetTester tester) async {
      final itemKeys = List.generate(20, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: (itemKeys.length - 1).clamp(0, 6),
          ),
        );
      }

      // 初始化列表并让指定元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 6);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [6, 7, 8, 9, 10, 11]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 2);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 在列表锚点位置移除单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 20; i++) {
        itemKeys.removeAt(controller.anchorIndex);
        await tester.pumpWidget(builder());
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, (itemKeys.length - 1).clamp(0, 2));
        expect(controller.position.pixels, moreOrLessEquals(controller.anchorIndex * -100.0));
        expectList(tester, visible: itemKeys.length >= 6 ? [0, 1, 2 + i, 3 + i, 4 + i, 5 + i] : itemKeys);
      }

      // 列表项全部被移除
      expect(itemKeys.isEmpty, true);
    });

    testWidgets('when removing single item at start and end', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(20, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + (7 <= index && index <= 18 ? 0.0 : random.nextInt(100)));
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: (itemKeys.length - 1).clamp(0, 13),
          ),
        );
      }

      // 初始化列表并让指定元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 13);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [13, 14, 15, 16, 17, 18]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [7, 8, 9, 10, 11, 12]);

      // 在列表首尾位置同时移除单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.removeAt(0);
        itemKeys.removeAt(itemKeys.length - 1);
        itemHeights.removeAt(0);
        itemHeights.removeAt(itemHeights.length - 1);
        await tester.pumpWidget(builder());
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, itemKeys.length >= 6 ? 9 - i : (itemKeys.length - 1).clamp(0, 1));
        final expectedPixels = itemKeys.length >= 6 ? -200.0 : (itemKeys.length - 1).clamp(0, 1) * -100.0;
        expect(controller.position.pixels, moreOrLessEquals(expectedPixels));
        expectList(tester, visible: itemKeys.length >= 6 ? [7, 8, 9, 10, 11, 12] : itemKeys);
      }

      // 列表项全部被移除
      expect(itemKeys.isEmpty, true);
    });

    testWidgets('when removing multi items at start and end', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(2000, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + (997 <= index && index <= 1008 ? 0.0 : random.nextInt(100)));
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: (itemKeys.length - 1).clamp(0, 1003),
          ),
        );
      }

      // 初始化列表并让指定元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 1003);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [1003, 1004, 1005, 1006, 1007, 1008]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 999);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [997, 998, 999, 1000, 1001, 1002]);

      // 在列表首尾位置同时移除多个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.removeRange(0, 100);
        itemKeys.removeRange(itemKeys.length - 100, itemKeys.length);
        itemHeights.removeRange(0, 100);
        itemHeights.removeRange(itemHeights.length - 100, itemHeights.length);
        await tester.pumpWidget(builder());
        await tester.pump();
        expect(controller.position.isScrollingNotifier.value, false);
        expect(controller.anchorIndex, itemKeys.length >= 6 ? 999 - i * 100 : (itemKeys.length - 1).clamp(0, 1));
        final expectedPixels = itemKeys.length >= 6 ? -200.0 : (itemKeys.length - 1).clamp(0, 1) * -100.0;
        expect(controller.position.pixels, moreOrLessEquals(expectedPixels));
        expectList(tester, visible: itemKeys.length >= 6 ? [997, 998, 999, 1000, 1001, 1002] : itemKeys);
      }

      // 列表项全部被移除
      expect(itemKeys.isEmpty, true);
    });

    testWidgets('when adding single item before and after anchor', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(10, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: 9,
          ),
        );
      }

      // 初始化列表并让最后一个元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一个元素的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0 / 6));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);

      // 在锚点列表项的位置同时添加单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        final anchorIndex = itemKeys.indexOf(5);
        itemKeys.insert(anchorIndex + 1, itemKeys.length);
        itemHeights.insert(anchorIndex + 1, 300.0 + random.nextInt(100));
        itemKeys.insert(anchorIndex, itemKeys.length);
        itemHeights.insert(anchorIndex, 300.0 + random.nextInt(100));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [5, itemKeys.length - 2, itemKeys.length - 1]);
      }
    });

    testWidgets('when adding multi items before and after anchor', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(10, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: 9,
          ),
        );
      }

      // 初始化列表并让最后一个元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一个元素的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0 / 6));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);

      // 在锚点列表项的位置同时添加多个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        final anchorIndex = itemKeys.indexOf(5);
        itemKeys.insertAll(anchorIndex + 1, List.generate(100, (index) => itemKeys.length + index));
        itemHeights.insertAll(anchorIndex + 1, List.generate(100, (index) => 300.0 + random.nextInt(100)));
        itemKeys.insertAll(anchorIndex, List.generate(100, (index) => itemKeys.length + index));
        itemHeights.insertAll(anchorIndex, List.generate(100, (index) => 300.0 + random.nextInt(100)));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i * 100);
        expectList(tester, visible: [5, itemKeys.length - 200, itemKeys.length - 1]);
      }
    });
  });

  group('TsukuyomiList respects initialScrollIndex', () {
    testWidgets('when default', (WidgetTester tester) async {
      final itemKeys = List.generate(10, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder(index) {
        return Directionality(
          key: ValueKey(index),
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('${itemKeys[index]}')),
            controller: controller,
            initialScrollIndex: index,
          ),
        );
      }

      // 可以指定索引作为初始元素并且没有越界显示
      for (int i = 0; i < itemKeys.length; i++) {
        await tester.pumpWidget(builder(i));
        expect(controller.anchorIndex, i);
        expect(controller.position.pixels, moreOrLessEquals((i - 4).clamp(0, 5) * -100.0));
        expectList(tester, visible: List.generate(6, (index) => index + i.clamp(0, 4)));
      }
    });
  });

  group('TsukuyomiList respects TsukuyomiListController.jumpToIndex', () {
    testWidgets('when default', (WidgetTester tester) async {
      final itemKeys = List.generate(10, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('${itemKeys[index]}')),
            controller: controller,
          ),
        );
      }

      // 可以跳转到指定位置的元素并且没有越界显示
      await tester.pumpWidget(builder());
      for (int i = 0; i < itemKeys.length; i++) {
        controller.jumpToIndex(i);
        await tester.pump();
        expect(controller.anchorIndex, i);
        expect(controller.position.pixels, moreOrLessEquals((i - 4).clamp(0, 5) * -100.0));
        expectList(tester, visible: List.generate(6, (index) => index + i.clamp(0, 4)));
      }
    });

    testWidgets('when size changes', (WidgetTester tester) async {
      final itemKeys = List.generate(20, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder({required List<double> itemHeights}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
          ),
        );
      }

      // 默认显示首屏的元素
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 动态修改列表项尺寸
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3]);

      // 跳转到指定元素
      controller.jumpToIndex(10);
      await tester.pump();
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [10, 11, 12, 13]);

      // 修改列表项尺寸
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [10, 11, 12, 13, 14, 15]);

      // 跳转回第一个元素，此时应该根据最新的列表项尺寸进行布局显示
      controller.jumpToIndex(0);
      await tester.pump();
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 再次修改列表项尺寸
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3]);

      // 再次跳转到指定元素，此时应该根据最新的列表项尺寸进行布局显示
      controller.jumpToIndex(10);
      await tester.pump();
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [10, 11, 12, 13]);
    });
  });

  group('TsukuyomiList respects dragging', () {
    for (final physics in [const ClampingScrollPhysics(), const BouncingScrollPhysics()]) {
      for (final completeLayout in [false, true]) {
        final timing = completeLayout ? 'after layout' : 'before layout';
        final description = 'when released after anchor changes $timing (${physics.runtimeType})';
        testWidgets(description, (WidgetTester tester) async {
          const itemHeight = 100.0;
          const dragStartDistance = 20.0;
          const eventInterval = Duration(milliseconds: 20);
          final itemKeys = List.generate(10, (index) => index);
          final controller = TsukuyomiListController();
          final viewportHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
          final visibleItemCount = viewportHeight ~/ itemHeight;
          // 从最后一屏开始，向下拖动时让锚点发生切换
          final initialScrollIndex = itemKeys.length - visibleItemCount;
          final dragDistance = itemHeight * 2.0;

          Widget builder() {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: TsukuyomiList.builder(
                itemKeys: itemKeys,
                itemBuilder: (context, index) => SizedBox(height: itemHeight, child: Text('${itemKeys[index]}')),
                controller: controller,
                physics: physics,
                initialScrollIndex: initialScrollIndex,
              ),
            );
          }

          await tester.pumpWidget(builder());
          final initialItem = find.text('${itemKeys[initialScrollIndex]}');
          final initialTop = tester.getTopLeft(initialItem).dy;
          final gesture = await tester.startGesture(tester.getCenter(find.byType(TsukuyomiList)));
          // 先跨过触摸拖拽阈值，再拖动到两个列表项的距离
          await gesture.moveBy(const Offset(0.0, dragStartDistance), timeStamp: eventInterval);
          await gesture.moveBy(Offset(0.0, dragDistance - dragStartDistance), timeStamp: eventInterval * 2);
          // 布局后的回调切换锚点，此时新的滚动范围尚未完成布局
          await tester.pump();
          expect(controller.anchorIndex, isNot(initialScrollIndex));
          expect(controller.correction, isNotNull);
          if (completeLayout) {
            await tester.pump();
            expect(controller.correction, isNull);
          }
          final draggedTop = tester.getTopLeft(initialItem).dy;
          expect(draggedTop, greaterThan(initialTop));
          await gesture.up(timeStamp: eventInterval * 3);
          // 不推进时间，只启动惯性活动，列表项应保持松手时的屏幕位置
          await tester.pump();
          expect(tester.getTopLeft(initialItem).dy, moreOrLessEquals(draggedTop));
          await tester.pumpAndSettle(const Duration(milliseconds: 16));
        });
      }
    }
  });

  group('TsukuyomiList respects TsukuyomiListController.slideViewport', () {
    // 使用不同帧间隔验证翻页动画的位置变化
    final frameDurations = {
      '16ms': const Duration(milliseconds: 16),
      for (final frameRate in [120, 60, 30, 10]) ...{
        '${frameRate}Hz': Duration(microseconds: (Duration.microsecondsPerSecond / frameRate).round()),
      },
    };
    for (final frame in frameDurations.entries) {
      for (final physics in [const ClampingScrollPhysics(), const BouncingScrollPhysics()]) {
        final description = 'when anchor changes before layout (${frame.key}, ${physics.runtimeType})';
        testWidgets(description, (WidgetTester tester) async {
          const itemHeight = 100.0;
          const animationDuration = Duration(milliseconds: 300);
          const curve = Curves.easeInOutCubic;
          final itemKeys = List.generate(10, (index) => index);
          final controller = TsukuyomiListController();
          final frameDuration = frame.value;
          final viewportHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
          final visibleItemCount = viewportHeight ~/ itemHeight;
          // 从最后一屏的第一项开始，锚点应位于视口顶部，反向滚动时才能复现锚点跨帧切换
          final initialScrollIndex = itemKeys.length - visibleItemCount;

          Widget builder() {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: TsukuyomiList.builder(
                itemKeys: itemKeys,
                itemBuilder: (context, index) => SizedBox(height: itemHeight, child: Text('${itemKeys[index]}')),
                controller: controller,
                physics: physics,
                initialScrollIndex: initialScrollIndex,
              ),
            );
          }

          await tester.pumpWidget(builder());
          final viewport = tester.getRect(find.byType(TsukuyomiList));
          // 列表不足两屏，滑动一个屏幕时，实际位移会被首尾边界限制
          final scrollExtent = itemKeys.length * itemHeight - viewport.height;
          final initialItem = find.text('${itemKeys[initialScrollIndex]}');
          // 先逆向滚到首屏，再正向滚回末屏，初始锚点项在整个往返过程中始终可见
          for (final viewportFraction in [-1.0, 1.0]) {
            final initialTop = tester.getTopLeft(initialItem).dy;
            final scrolling = controller.slideViewport(viewportFraction, duration: animationDuration, curve: curve);
            // 首帧启动动画计时，之后再按指定的帧间隔推进
            await tester.pump();
            var elapsed = Duration.zero;
            while (elapsed < animationDuration) {
              elapsed += frameDuration;
              await tester.pump(frameDuration);
              final progress = (elapsed.inMicroseconds / animationDuration.inMicroseconds).clamp(0.0, 1.0);
              final offset = scrollExtent * viewportFraction * curve.transform(progress);
              expect(tester.getTopLeft(initialItem).dy, moreOrLessEquals(initialTop - offset));
            }
            await tester.pumpAndSettle(frameDuration);
            await scrolling;
            expect(tester.getTopLeft(initialItem).dy, moreOrLessEquals(initialTop - scrollExtent * viewportFraction));
            expect(controller.position.isScrollingNotifier.value, false);
          }
          expect(tester.getTopLeft(initialItem).dy, moreOrLessEquals(viewport.top));
        });
      }
    }

    testWidgets('when default', (WidgetTester tester) async {
      final itemKeys = List.generate(20, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('${itemKeys[index]}')),
            controller: controller,
          ),
        );
      }

      // 默认显示首屏的元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 滚动零个屏幕的距离
      await controller.slideViewport(0.0);
      await tester.pump();
      expect(controller.position.isScrollingNotifier.value, false);
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 正向滚动半个屏幕的距离
      unawaited(controller.slideViewport(0.5));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 4);
      expect(controller.position.pixels, moreOrLessEquals(-100.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);
      // 正向滚动一个屏幕的距离
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 12);
      expect(controller.position.pixels, moreOrLessEquals(-300.0));
      expectList(tester, visible: [9, 10, 11, 12, 13, 14]);
      // 正向滚动越界时停止滚动
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 19);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [14, 15, 16, 17, 18, 19]);

      // 逆向滚动一个屏幕的距离
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [8, 9, 10, 11, 12, 13]);
      // 逆向滚动半个屏幕的距离
      unawaited(controller.slideViewport(-0.5));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 7);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [5, 6, 7, 8, 9, 10]);
      // 逆向滚动越界时停止滚动
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);
    });

    testWidgets('when size changes', (WidgetTester tester) async {
      const itemHeight = 100.0;
      const expandedHeight = itemHeight * 2.0;
      final itemKeys = List.generate(20, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => itemHeight);
      final controller = TsukuyomiListController();

      Widget builder({Future<double>? heightFuture}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            controller: controller,
            itemKeys: itemKeys,
            itemBuilder: (context, index) => FutureBuilder(
              future: index == 0 ? heightFuture : null,
              builder: (context, snapshot) => SizedBox(
                height: snapshot.data ?? itemHeights[index],
                child: Text('${itemKeys[index]}'),
              ),
            ),
          ),
        );
      }

      // 默认显示首屏的元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 自定义增加列表项的尺寸
      final largerHeight = Completer<double>();
      await tester.pumpWidget(builder(heightFuture: largerHeight.future));
      // 异步任务完成前重建列表，列表项尺寸保持不变
      await tester.pumpWidget(builder(heightFuture: largerHeight.future));
      expect(tester.getSize(find.text('0')).height, itemHeight);
      largerHeight.complete(expandedHeight);
      await tester.idle();
      await tester.pump();
      expect(tester.getSize(find.text('0')).height, expandedHeight);
      // 异步任务完成后重建列表，列表项使用更新后的尺寸
      await tester.pumpWidget(builder(heightFuture: largerHeight.future));
      expect(tester.getSize(find.text('0')).height, expandedHeight);
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4]);

      // 正向滚动一个屏幕的距离
      unawaited(controller.slideViewport(6 / 6));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 7);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [5, 6, 7, 8, 9, 10]);

      // 还原回列表项的原始尺寸
      final restoredHeight = Completer<double>();
      await tester.pumpWidget(builder(heightFuture: restoredHeight.future));
      // 列表项未渲染时也能完成异步尺寸更新
      expect(find.text('0', skipOffstage: false), findsNothing);
      restoredHeight.complete(itemHeight);
      await tester.idle();
      expect(controller.anchorIndex, 7);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [5, 6, 7, 8, 9, 10]);

      // 逆向滚动回到首屏的元素
      unawaited(controller.slideViewport(5 / 6 * -1));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(tester.getSize(find.text('0')).height, itemHeight);
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);
    });

    testWidgets('when remove items', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(20, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + (4 <= index && index <= 15 ? 0.0 : random.nextInt(100)));
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: (itemKeys.length - 1).clamp(0, 10),
          ),
        );
      }

      // 初始化列表并让指定元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [10, 11, 12, 13, 14, 15]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 6);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 在列表首尾位置同时移除单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 4; i++) {
        itemKeys.removeAt(0);
        itemKeys.removeAt(itemKeys.length - 1);
        itemHeights.removeAt(0);
        itemHeights.removeAt(itemHeights.length - 1);
        await tester.pumpWidget(builder());
        await tester.pump();
        expect(controller.position.isScrollingNotifier.value, false);
        expect(controller.anchorIndex, 6 - i);
        expect(controller.position.pixels, moreOrLessEquals(-200.0));
        expectList(tester, visible: [4, 5, 6, 7, 8, 9]);
      }

      // 正向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [10, 11, 12, 13, 14, 15]);

      // 剩余指定的元素
      expect(itemKeys.equals([4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), true);
    });

    testWidgets('when remove items and jump to self', (WidgetTester tester) async {
      final random = Random(2147483647);
      final itemKeys = List.generate(20, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + (4 <= index && index <= 15 ? 0.0 : random.nextInt(100)));
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 0.5,
            initialScrollIndex: (itemKeys.length - 1).clamp(0, 10),
          ),
        );
      }

      // 初始化列表并让指定元素作为中心元素和锚点元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [10, 11, 12, 13, 14, 15]);

      // 在列表首尾位置同时移除单个列表项时能够锚定滚动位置
      for (int i = 0; i < 4; i++) {
        controller.jumpToIndex(10 - i);
        await tester.pump();
        expect(controller.anchorIndex, 10 - i);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
        expectList(tester, visible: [10, 11, 12, 13, 14, 15]);
        itemKeys.removeAt(0);
        itemKeys.removeAt(itemKeys.length - 1);
        itemHeights.removeAt(0);
        itemHeights.removeAt(itemHeights.length - 1);
        await tester.pumpWidget(builder());
        await tester.pump();
        expect(controller.position.isScrollingNotifier.value, false);
        expect(controller.anchorIndex, 10 - i - 1);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
        expectList(tester, visible: [10, 11, 12, 13, 14, 15]);
      }

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 2);
      expect(controller.position.pixels, moreOrLessEquals(-200.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 剩余指定的元素
      expect(itemKeys.equals([4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), true);
    });

    testWidgets('when out of range with bouncing scroll physics', (WidgetTester tester) async {
      final itemKeys = List.generate(10, (index) => index);
      final controller = TsukuyomiListController();

      overscrollCheckListener() {
        final position = controller.position;
        final correction = controller.correction ?? 0.0;
        final correctedPixels = position.pixels - correction;
        expect(position.outOfRange == false || controller.correction != null, true);
        expect(position.minScrollExtent <= correctedPixels && correctedPixels <= position.maxScrollExtent, true);
      }

      Widget builder({required List<double> itemHeights}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}')),
            controller: controller,
            initialScrollIndex: 3,
            physics: const BouncingScrollPhysics(),
          ),
        );
      }

      // 默认显示首屏的元素
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 3);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);

      // 正向滚动一个屏幕的距离，列表不应该发生越界滚动
      controller.position.addListener(overscrollCheckListener);
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一个屏幕的距离，列表不应该发生越界滚动
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);
      controller.position.removeListener(overscrollCheckListener);
    });
  });

  group('TsukuyomiList respects specific situations', () {
    testWidgets('when sliding to none zero and jump to anchor', (WidgetTester tester) async {
      final itemKeys = List.generate(10, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 1.0,
          ),
        );
      }

      // 默认显示首屏的元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 跳转到末尾元素
      controller.jumpToIndex(9);
      await tester.pump();
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一个元素的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0 / 6));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);

      // 跳转到当前索引，列表不应该发生越界滚动
      controller.jumpToIndex(8);
      await tester.pump();
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, moreOrLessEquals(-400.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);
    });

    testWidgets('when jumping to end and update anchor in next frame', (WidgetTester tester) async {
      final itemKeys = List.generate(10, (index) => index);
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('${itemKeys[index]}')),
            controller: controller,
            anchor: 2 / 6,
          ),
        );
      }

      // 默认显示首屏的元素
      await tester.pumpWidget(builder());
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, moreOrLessEquals(0.0));
      expectList(tester, visible: [0, 1, 2, 3, 4, 5]);

      // 跳转到指定元素
      controller.jumpToIndex(5);
      await tester.pump();
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, moreOrLessEquals(-100.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 跳转到末尾元素
      controller.jumpToIndex(9);
      await tester.pump();
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, moreOrLessEquals(-500.0));
      expectList(tester, visible: [4, 5, 6, 7, 8, 9]);

      // 触发索引的更新
      controller.position.jumpTo(controller.position.pixels - 100.0);
      await tester.pump();
      expect(controller.anchorIndex, 4);
      expect(controller.position.pixels, moreOrLessEquals(-100.0));
      expectList(tester, visible: [3, 4, 5, 6, 7, 8]);
    });
  });
}
