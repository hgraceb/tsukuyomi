import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_pixel_snap/src/tsukuyomi/widgets/basic.dart';

void main() {
  group('TsukuyomiPixelRow', () {
    testWidgets('space spread evenly', (WidgetTester tester) async {
      final itemCount = 99;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiPixelRow(children: List.generate(itemCount, (index) => Expanded(child: Text('$index')))),
        ),
      );
      for (var i = 0; i < itemCount; i++) {
        expect(tester.getSize(find.text('$i')).width, anyOf([equals(8.0), equals(8.0 + 1.0 / 3.0)]));
      }
    });
  });

  group('TsukuyomiPixelColumn', () {
    testWidgets('space spread evenly', (WidgetTester tester) async {
      final itemCount = 99;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TsukuyomiPixelColumn(children: List.generate(itemCount, (index) => Expanded(child: Text('$index')))),
        ),
      );
      for (var i = 0; i < itemCount; i++) {
        expect(tester.getSize(find.text('$i')).height, anyOf([equals(6.0), equals(6.0 + 1.0 / 3.0)]));
      }
    });
  });
}
