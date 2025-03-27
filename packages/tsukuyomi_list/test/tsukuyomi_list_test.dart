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

    await tester.pumpWidget(builder(0));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    controller.jumpToIndex(1);
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    controller.jumpToIndex(2);
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });
}
