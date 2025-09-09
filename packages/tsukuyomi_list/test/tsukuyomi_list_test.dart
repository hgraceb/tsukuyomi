import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

import 'tsukuyomi_list_util.dart';

void main() {
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一定距离让第一个元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(microseconds: 500));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
      // 列表项尺寸动态增大时能够锚定第一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3]);
      // 列表项尺寸动态减小时能够锚定第一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 正向滚动一定距离让第二个元素作为新的锚点元素
      unawaited(controller.slideViewport(75 / 600));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 1);
      expect(controller.position.pixels, -25.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5, 6]);
      // 列表项尺寸动态增大时能够锚定第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 1);
      expect(controller.position.pixels, -25.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4]);
      // 列表项尺寸动态减小时能够锚定第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 1);
      expect(controller.position.pixels, -25.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5, 6]);

      // 正向滚动一定距离让倒数第二个元素作为新的锚点元素
      unawaited(controller.slideViewport(250 / 600));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, -475.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8, 9]);
      // 列表项尺寸动态增大时能够锚定倒数第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, -475.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8]);
      // 列表项尺寸动态减小时能够锚定倒数第二个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, -475.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8, 9]);

      // 正向滚动一定距离让最后一个元素作为新的锚点元素
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, -500.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);
      // 列表项尺寸动态增大时能够锚定最后一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, -500.0);
      expectList(length: itemKeys.length, visible: [5, 6, 7, 8, 9]);
      // 列表项尺寸动态减小时能够锚定最后一个元素的位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, -500.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);
    });

    testWidgets('when 0.5', (WidgetTester tester) async {
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 正向滚动半个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(0.5));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);
      // 列表项尺寸动态增大时能够锚定滚动位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 200.0)));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6]);
      // 列表项尺寸动态减小时能够锚定滚动位置
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);

      // 逆向滚动半个屏幕的距离可以回到原点
      unawaited(controller.slideViewport(-0.5));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 2);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
    });

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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [9]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);

      // 在列表首尾位置同时添加单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.insert(0, itemKeys.length);
        itemKeys.insert(itemKeys.length, itemKeys.length);
        itemHeights.insert(0, 100.0 + random.nextInt(100));
        itemHeights.insert(itemHeights.length, 100.0 + random.nextInt(100));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i);
        expect(controller.position.pixels, -200.0);
        expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [9]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);

      // 在列表首尾位置同时添加多个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.insertAll(0, List.generate(100, (index) => itemKeys.length + index));
        itemKeys.insertAll(itemKeys.length, List.generate(100, (index) => itemKeys.length + index));
        itemHeights.insertAll(0, List.generate(100, (index) => 100.0 + random.nextInt(100)));
        itemHeights.insertAll(itemHeights.length, List.generate(100, (index) => 100.0 + random.nextInt(100)));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i * 100);
        expect(controller.position.pixels, -200.0);
        expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [6, 7, 8, 9, 10, 11]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 2);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 在列表锚点位置移除单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 20; i++) {
        itemKeys.removeAt(controller.anchorIndex);
        await tester.pumpWidget(builder());
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, (itemKeys.length - 1).clamp(0, 2));
        expect(controller.position.pixels, controller.anchorIndex * -100.0);
        expectList(length: itemKeys.length, visible: itemKeys.length > 6 ? [0, 1, 2 + i, 3 + i, 4 + i, 5 + i] : itemKeys);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [13, 14, 15, 16, 17, 18]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [7, 8, 9, 10, 11, 12]);

      // 在列表首尾位置同时移除单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.removeAt(0);
        itemKeys.removeAt(itemKeys.length - 1);
        itemHeights.removeAt(0);
        itemHeights.removeAt(itemHeights.length - 1);
        await tester.pumpWidget(builder());
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, itemKeys.length > 6 ? 9 - i : (itemKeys.length - 1).clamp(0, 2));
        expect(controller.position.pixels, itemKeys.length > 2 ? -200.0 : itemKeys.length / 2 * -100.0);
        expectList(length: itemKeys.length, visible: itemKeys.length > 6 ? [7, 8, 9, 10, 11, 12] : itemKeys);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [1003, 1004, 1005, 1006, 1007, 1008]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 999);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [997, 998, 999, 1000, 1001, 1002]);

      // 在列表首尾位置同时移除多个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        itemKeys.removeRange(0, 100);
        itemKeys.removeRange(itemKeys.length - 100, itemKeys.length);
        itemHeights.removeRange(0, 100);
        itemHeights.removeRange(itemHeights.length - 100, itemHeights.length);
        await tester.pumpWidget(builder());
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, itemKeys.length > 6 ? 999 - i * 100 : (itemKeys.length - 1).clamp(0, 2));
        expect(controller.position.pixels, itemKeys.length > 2 ? -200.0 : itemKeys.length / 2 * -100.0);
        expectList(length: itemKeys.length, visible: itemKeys.length > 6 ? [997, 998, 999, 1000, 1001, 1002] : itemKeys);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [9]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);

      // 在锚点列表项的位置同时添加单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        final anchorIndex = itemKeys.indexOf(5);
        itemKeys.insert(anchorIndex + 1, itemKeys.length);
        itemHeights.insert(anchorIndex + 1, 300.0 + random.nextInt(100));
        itemKeys.insert(anchorIndex, itemKeys.length);
        itemHeights.insert(anchorIndex, 300.0 + random.nextInt(100));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i);
        expect(controller.position.pixels, -200.0);
        expectList(length: itemKeys.length, visible: [5, itemKeys.length - 2, itemKeys.length - 1]);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [9]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 5);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);

      // 在锚点列表项的位置同时添加多个列表项时能够锚定滚动位置
      for (int i = 1; i <= 10; i++) {
        final anchorIndex = itemKeys.indexOf(5);
        itemKeys.insertAll(anchorIndex + 1, List.generate(100, (index) => itemKeys.length + index));
        itemHeights.insertAll(anchorIndex + 1, List.generate(100, (index) => 300.0 + random.nextInt(100)));
        itemKeys.insertAll(anchorIndex, List.generate(100, (index) => itemKeys.length + index));
        itemHeights.insertAll(anchorIndex, List.generate(100, (index) => 300.0 + random.nextInt(100)));
        await tester.pumpWidget(builder());
        expect(controller.anchorIndex, 5 + i * 100);
        expectList(length: itemKeys.length, visible: [5, itemKeys.length - 200, itemKeys.length - 1]);
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

      // 可以指定初始元素并越界显示
      for (int i = 0; i < itemKeys.length; i++) {
        await tester.pumpWidget(builder(i));
        expect(controller.anchorIndex, i);
        expect(controller.position.pixels, 0.0);
        expectList(length: itemKeys.length, visible: List.generate(min(6, itemKeys.length - i), (index) => index + i));
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

      // 可以跳转到指定位置的元素并越界显示
      await tester.pumpWidget(builder());
      for (int i = 0; i < itemKeys.length; i++) {
        controller.jumpToIndex(i);
        await tester.pump();
        expect(controller.anchorIndex, i);
        expect(controller.position.pixels, 0.0);
        expectList(length: itemKeys.length, visible: List.generate(min(6, itemKeys.length - i), (index) => index + i));
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 动态修改列表项尺寸
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3]);

      // 跳转到指定元素
      controller.jumpToIndex(10);
      await tester.pump();
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [10, 11, 12, 13]);

      // 修改列表项尺寸
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)));
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [10, 11, 12, 13, 14, 15]);

      // 跳转回第一个元素，此时应该根据最新的列表项尺寸进行布局显示
      controller.jumpToIndex(0);
      await tester.pump();
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 再次修改列表项尺寸
      await tester.pumpWidget(builder(itemHeights: List.generate(itemKeys.length, (index) => 150.0)));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3]);

      // 再次跳转到指定元素，此时应该根据最新的列表项尺寸进行布局显示
      controller.jumpToIndex(10);
      await tester.pump();
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [10, 11, 12, 13]);
    });
  });

  group('TsukuyomiList respects TsukuyomiListController.slideViewport', () {
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 滚动零个屏幕的距离
      unawaited(controller.slideViewport(0.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 正向滚动半个屏幕的距离
      unawaited(controller.slideViewport(0.5));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 4);
      expect(controller.position.pixels, -100.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);
      // 正向滚动一个屏幕的距离
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 12);
      expect(controller.position.pixels, -300.0);
      expectList(length: itemKeys.length, visible: [9, 10, 11, 12, 13, 14]);
      // 正向滚动越界时停止滚动
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 19);
      expect(controller.position.pixels, -500.0);
      expectList(length: itemKeys.length, visible: [14, 15, 16, 17, 18, 19]);

      // 逆向滚动一个屏幕的距离
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 10);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [8, 9, 10, 11, 12, 13]);
      // 逆向滚动半个屏幕的距离
      unawaited(controller.slideViewport(-0.5));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 7);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [5, 6, 7, 8, 9, 10]);
      // 逆向滚动越界时停止滚动
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
    });

    testWidgets('when size changes', (WidgetTester tester) async {
      final itemKeys = List.generate(20, (index) => index);
      final itemHeights = List.generate(itemKeys.length, (index) => 100.0);
      final controller = TsukuyomiListController();

      Widget builder({required double customHeight}) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            controller: controller,
            itemKeys: itemKeys,
            itemBuilder: (context, index) => FutureBuilder(
              future: index == 0 ? Future.delayed(const Duration(seconds: 1), () => customHeight) : null,
              builder: (context, snapshot) => SizedBox(
                height: snapshot.data ?? itemHeights[index],
                child: Text('${itemKeys[index]}'),
              ),
            ),
          ),
        );
      }

      // 默认显示首屏的元素
      await tester.pumpWidget(builder(customHeight: 100.0));
      await tester.pump(const Duration(seconds: 1));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);

      // 自定义增加列表项的尺寸
      await tester.pumpWidget(builder(customHeight: 200.0));
      await tester.pump(const Duration(seconds: 1));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4]);

      // 正向滚动一个屏幕的距离
      unawaited(controller.slideViewport(6 / 6));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 7);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [5, 6, 7, 8, 9, 10]);

      // 还原回列表项的原始尺寸
      await tester.pumpWidget(builder(customHeight: 100.0));
      await tester.pump(const Duration(seconds: 1));
      expect(controller.anchorIndex, 7);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [5, 6, 7, 8, 9, 10]);

      // 逆向滚动回到首屏的元素
      unawaited(controller.slideViewport(5 / 6 * -1));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      await tester.pump(const Duration(seconds: 1));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [10, 11, 12, 13, 14, 15]);

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 6);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);

      // 在列表首尾位置同时移除单个列表项时能够锚定滚动位置
      for (int i = 1; i <= 4; i++) {
        itemKeys.removeAt(0);
        itemKeys.removeAt(itemKeys.length - 1);
        itemHeights.removeAt(0);
        itemHeights.removeAt(itemHeights.length - 1);
        await tester.pumpWidget(builder());
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, 6 - i);
        expect(controller.position.pixels, -200.0);
        expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);
      }

      // 正向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 8);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [10, 11, 12, 13, 14, 15]);

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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [10, 11, 12, 13, 14, 15]);

      // 在列表首尾位置同时移除单个列表项时能够锚定滚动位置
      for (int i = 0; i < 4; i++) {
        controller.jumpToIndex(10 - i);
        await tester.pump();
        expect(controller.anchorIndex, 10 - i);
        expect(controller.position.pixels, 0.0);
        expectList(length: itemKeys.length, visible: [10, 11, 12, 13, 14, 15]);
        itemKeys.removeAt(0);
        itemKeys.removeAt(itemKeys.length - 1);
        itemHeights.removeAt(0);
        itemHeights.removeAt(itemHeights.length - 1);
        await tester.pumpWidget(builder());
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(controller.anchorIndex, 10 - i - 1);
        expect(controller.position.pixels, 0.0);
        expectList(length: itemKeys.length, visible: [10, 11, 12, 13, 14, 15]);
      }

      // 逆向滚动一个屏幕的距离让处于屏幕指定位置的元素作为新的锚点元素
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 2);
      expect(controller.position.pixels, -200.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);

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
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [3, 4, 5, 6, 7, 8]);

      // 正向滚动一个屏幕的距离，列表不应该发生越界滚动
      controller.position.addListener(overscrollCheckListener);
      unawaited(controller.slideViewport(1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 9);
      expect(controller.position.pixels, -500.0);
      expectList(length: itemKeys.length, visible: [4, 5, 6, 7, 8, 9]);

      // 逆向滚动一个屏幕的距离，列表不应该发生越界滚动
      unawaited(controller.slideViewport(-1.0));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.anchorIndex, 0);
      expect(controller.position.pixels, 0.0);
      expectList(length: itemKeys.length, visible: [0, 1, 2, 3, 4, 5]);
      controller.position.removeListener(overscrollCheckListener);
    });
  });
}
