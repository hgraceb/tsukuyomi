import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/update/update_filter.dart';
import 'package:tsukuyomi/pages/update/update_summary.dart';

import '../../fixtures/update_fixtures.dart';

void main() {
  testWidgets('Count presses paint one highlight without a second ripple across splash themes and text sizes', (tester) async {
    for (final factory in [InkRipple.splashFactory, InkSparkle.splashFactory]) {
      for (final scale in [1.0, 1.3]) {
        for (final count in [12, 12345]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(useMaterial3: true, splashFactory: factory),
              localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,
              supportedLocales: TsukuyomiLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Material(
                child: Center(
                  child: UpdateSummary(
                    report: updateReportFixture(totalTargets: count),
                    selection: UpdateFilter.all,
                    onChanged: (_) {},
                    progress: const SizedBox.square(dimension: 24.0),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final button = find.byKey(const ValueKey(UpdateFilter.all));
          final ink = Material.of(tester.element(button)) as RenderObject;
          final bounds = tester.getRect(button);
          final box = tester.renderObject<RenderBox>(button);
          final size = box.size;
          final rect = Rect.fromCenter(center: size.center(Offset.zero), width: math.max(size.height, size.width), height: size.height);
          final translation = MatrixUtils.getAsTranslation(box.getTransformTo(ink));
          final feedback = translation == null ? rect : rect.shift(translation);
          expect(bounds.height, greaterThanOrEqualTo(36.0));
          expect(ink, paintsExactlyCountTimes(#drawRect, 0));
          final press = await tester.startGesture(bounds.center + Offset(bounds.width / 4.0, 0.0));
          await tester.pump(const Duration(milliseconds: 150));
          // 检查实际绘制，确保按压时只有一个居中反馈，没有额外扩散圆
          expect(ink, paintsExactlyCountTimes(#drawRect, 1));
          expect(ink, paintsExactlyCountTimes(#drawCircle, 0));
          expect(ink, paints..rect(rect: feedback));
          await press.up();
          await tester.pump(const Duration(milliseconds: 20));
          expect(ink, paintsExactlyCountTimes(#drawCircle, 0));
          await tester.pumpAndSettle();
          expect(ink, paintsExactlyCountTimes(#drawRect, 0));
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    }
  });
}
