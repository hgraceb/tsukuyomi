import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

void main() {
  testWidgets('TsukuyomiList.builder respects initialScrollIndex', (WidgetTester tester) async {
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

    await tester.pumpWidget(builder(0));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    await tester.pumpWidget(builder(1));
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.pumpWidget(builder(2));
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });
}
