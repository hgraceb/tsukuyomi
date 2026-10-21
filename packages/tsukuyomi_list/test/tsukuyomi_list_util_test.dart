import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

import 'tsukuyomi_list_util.dart';

void main() {
  group('expectList', () {
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
