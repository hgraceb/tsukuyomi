import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

import 'tsukuyomi_list_util.dart';

void main() {
  group('expectList', () {
    for (final axis in Axis.values) {
      testWidgets('ignores numerical overlap at viewport edges ($axis)', (WidgetTester tester) async {
        const itemExtent = 100.0;
        const viewportExtent = itemExtent * 2.0;
        const partialOverlap = 4.0;
        const itemKeys = [100, 200, 999];
        final controller = TsukuyomiListController();

        Widget builder() {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: axis == Axis.horizontal ? viewportExtent : itemExtent,
                height: axis == Axis.vertical ? viewportExtent : itemExtent,
                child: TsukuyomiList.builder(
                  itemKeys: itemKeys,
                  itemBuilder: (context, index) => SizedBox(
                    width: axis == Axis.horizontal ? itemExtent : null,
                    height: axis == Axis.vertical ? itemExtent : null,
                    child: Text('${itemKeys[index]}'),
                  ),
                  scrollDirection: axis,
                  controller: controller,
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(builder());
        expectList(tester, visible: [100, 200]);
        // 底部边界只重叠半个浮点容差时，不应多算一个可见项
        controller.position.jumpTo(precisionErrorTolerance / 2.0);
        await tester.pump();
        expectList(tester, visible: [100, 200]);
        // 顶部边界残留同样的浮点误差时，也不应保留已经离开的列表项
        controller.position.jumpTo(itemExtent - precisionErrorTolerance / 2.0);
        await tester.pump();
        expectList(tester, visible: [200, 999]);
        // 真实的像素级交叠仍然算可见，不能掩盖几像素的滚动误差
        controller.jumpToIndex(0);
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        controller.position.jumpTo(partialOverlap);
        await tester.pump();
        expectList(tester, visible: itemKeys);
        expect(() => expectList(tester, visible: [100, 200]), throwsA(isA<TestFailure>()));
      });
    }

    testWidgets('rejects unexpected items with noncontiguous keys', (WidgetTester tester) async {
      const itemKeys = [100, 999];

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('${itemKeys[index]}')),
          ),
        );
      }

      await tester.pumpWidget(builder());
      expectList(tester, visible: itemKeys);
      expect(() => expectList(tester, visible: [100]), throwsA(isA<TestFailure>()));
    });

    testWidgets('rejects duplicate visible labels', (WidgetTester tester) async {
      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiList.builder(
            itemKeys: const [100, 999],
            itemBuilder: (context, index) => const SizedBox(height: 100.0, child: Text('100')),
          ),
        );
      }

      await tester.pumpWidget(builder());
      expect(() => expectList(tester, visible: [100]), throwsA(isA<TestFailure>()));
    });

    testWidgets('only checks the selected list', (WidgetTester tester) async {
      const firstListKey = ValueKey('firstList');
      const secondListKey = ValueKey('secondList');

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              const Text('100'),
              Expanded(
                child: Row(
                  children: [
                    for (final (key, itemKey) in [(firstListKey, 100), (secondListKey, 999)]) ...[
                      Expanded(
                        child: TsukuyomiList.builder(
                          key: key,
                          itemKeys: [itemKey],
                          itemBuilder: (context, index) => SizedBox(height: 100.0, child: Text('$itemKey')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(builder());
      expectList(tester, list: find.byKey(firstListKey), visible: [100]);
      expectList(tester, list: find.byKey(secondListKey), visible: [999]);
    });

    testWidgets('includes partial items and excludes cached items', (WidgetTester tester) async {
      const itemHeight = 100.0;
      const itemKeys = [100, 200, 999];
      final controller = TsukuyomiListController();

      Widget builder() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: itemHeight * 2.0,
              height: itemHeight * 1.5,
              child: TsukuyomiList.builder(
                itemKeys: itemKeys,
                itemBuilder: (context, index) => SizedBox(height: itemHeight, child: Text('${itemKeys[index]}')),
                controller: controller,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(builder());
      expect(find.text('999', skipOffstage: false), findsOneWidget);
      expectList(tester, visible: [100, 200]);
      controller.position.jumpTo(itemHeight / 4.0);
      await tester.pump();
      expectList(tester, visible: [100, 200]);
      controller.position.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expectList(tester, visible: [200, 999]);
    });
  });
}
