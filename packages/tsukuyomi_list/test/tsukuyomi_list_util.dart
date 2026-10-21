import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

/// 比较目标列表中以整数文本标识的列表项，保留重复项以检测意外显示的内容
void expectList(WidgetTester tester, {required List<int> visible, Finder? list}) {
  final listFinder = list ?? find.byType(TsukuyomiList);
  expect(listFinder, findsOneWidget);
  final viewport = tester.getRect(listFinder);
  final items = find.descendant(of: listFinder, matching: find.byType(Text, skipOffstage: false), skipOffstage: false);
  final actual = <int>[];
  for (final element in items.evaluate()) {
    final box = element.findRenderObject()! as RenderBox;
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    final overlap = bounds.intersect(viewport);
    // 与 moreOrLessEquals 使用相同的精度，忽略浮点误差产生的边界交叠
    if (overlap.width > precisionErrorTolerance && overlap.height > precisionErrorTolerance) {
      actual.add(int.parse((element.widget as Text).data!));
    }
  }
  expect(actual, unorderedEquals(visible));
}
