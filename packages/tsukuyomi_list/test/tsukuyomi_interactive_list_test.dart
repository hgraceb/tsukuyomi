import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_list/src/tsukuyomi/widgets/interactive_viewer.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_interactive_list.dart';
import 'package:tsukuyomi_list/src/tsukuyomi_list.dart';

import 'tsukuyomi_list_util.dart';

void main() {
  group('TsukuyomiInteractiveList respects list positions', () {
    for (final axis in Axis.values) {
      testWidgets('when initialized and jumping ($axis)', (WidgetTester tester) async {
        const initialIndex = 10;
        const targetIndex = initialIndex + 1;
        const itemExtent = 100.0;
        const viewportExtent = 600.0;
        final itemKeys = List.generate(40, (index) => index);
        final controller = TsukuyomiListController();
        final updates = <List<TsukuyomiListItem>>[];
        final scales = <double>[];

        Widget builder() {
          return _buildList(
            itemKeys: itemKeys,
            axis: axis,
            initialIndex: initialIndex,
            itemExtent: itemExtent,
            viewportSize: const Size.square(viewportExtent),
            controller: controller,
            onItemsChanged: updates.add,
            onScaleUpdate: scales.add,
          );
        }

        await tester.pumpWidget(builder());
        final visibleCount = viewportExtent ~/ itemExtent;
        expect(controller.anchorIndex, initialIndex);
        expectList(tester, visible: List.generate(visibleCount, (index) => initialIndex + index));
        expect(updates, isNotEmpty);
        final initialItem = updates.first.singleWhere((item) => item.index == initialIndex);
        expect(initialItem.leading, moreOrLessEquals(0.0));
        expect(initialItem.trailing, moreOrLessEquals(itemExtent / viewportExtent));
        expect(scales, isEmpty);
        updates.clear();
        controller.jumpToIndex(targetIndex);
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expectList(tester, visible: List.generate(visibleCount, (index) => targetIndex + index));
        final item = updates.last.firstWhere((item) => item.index == targetIndex);
        expect(item.leading, moreOrLessEquals(0.0));
        expect(item.trailing, moreOrLessEquals(itemExtent / viewportExtent));
        expect(scales, isEmpty);
      });
    }
  });

  group('TsukuyomiInteractiveList respects double taps', () {
    for (final axis in Axis.values) {
      testWidgets('when zooming around the tapped position ($axis)', (WidgetTester tester) async {
        const initialIndex = 10;
        const itemExtent = 100.0;
        const viewportSize = Size(600.0, 480.0);
        const viewportOffset = Offset(40.0, 60.0);
        const middleScale = 2.0;
        const focalFraction = Offset(0.25, 0.5);
        const scaleDuration = Duration(milliseconds: 200);
        final itemKeys = List.generate(40, (index) => index);
        final scales = <double>[];

        Widget builder() {
          return _buildList(
            itemKeys: itemKeys,
            axis: axis,
            initialIndex: initialIndex,
            itemExtent: itemExtent,
            viewportSize: viewportSize,
            viewportOffset: viewportOffset,
            middleScale: middleScale,
            scaleDuration: scaleDuration,
            onScaleUpdate: scales.add,
          );
        }

        await tester.pumpWidget(builder());
        final viewport = tester.getRect(find.byType(TsukuyomiInteractiveList));
        expect(viewport.topLeft, viewportOffset);
        expect(viewport.size, viewportSize);
        final localFocalPoint = Offset(viewport.width * focalFraction.dx, viewport.height * focalFraction.dy);
        final focalPoint = viewport.topLeft + localFocalPoint;
        final focalOffset = axis == Axis.vertical ? localFocalPoint.dy : localFocalPoint.dx;
        final trackedIndex = initialIndex + focalOffset ~/ itemExtent;
        final item = find.byKey(ValueKey(trackedIndex));
        final originalRect = tester.getRect(item);
        final contentFraction = Offset(
          (focalPoint.dx - originalRect.left) / originalRect.width,
          (focalPoint.dy - originalRect.top) / originalRect.height,
        );
        await _doubleTap(tester, focalPoint);
        // 首帧启动动画，再按配置时长推进到终点
        await tester.pump();
        await tester.pump(scaleDuration);
        expect(scales.last, moreOrLessEquals(middleScale));
        final zoomedRect = tester.getRect(item);
        expect(zoomedRect.width, moreOrLessEquals(originalRect.width * middleScale));
        expect(zoomedRect.height, moreOrLessEquals(originalRect.height * middleScale));
        expect(zoomedRect.left + zoomedRect.width * contentFraction.dx, moreOrLessEquals(focalPoint.dx));
        expect(zoomedRect.top + zoomedRect.height * contentFraction.dy, moreOrLessEquals(focalPoint.dy));
        scales.clear();
        await _doubleTap(tester, focalPoint);
        await tester.pump();
        await tester.pump(scaleDuration);
        expect(scales.last, moreOrLessEquals(1.0));
        expect(tester.getRect(item), originalRect);
      });

      testWidgets('when interrupted by a mouse wheel ($axis)', (WidgetTester tester) async {
        const middleScale = 2.0;
        const scaleDuration = Duration(seconds: 1);
        const animationProgress = 0.4;
        const wheelDistance = 100.0;
        final itemKeys = List.generate(40, (index) => index);
        final scales = <double>[];

        Widget builder() {
          return _buildList(
            itemKeys: itemKeys,
            axis: axis,
            middleScale: middleScale,
            scaleDuration: scaleDuration,
            onScaleUpdate: scales.add,
          );
        }

        await tester.pumpWidget(builder());
        final center = tester.getCenter(find.byType(TsukuyomiInteractiveList));
        await _doubleTap(tester, center);
        await tester.pump();
        await tester.pump(scaleDuration * animationProgress);
        expect(scales.last, moreOrLessEquals(1.0 + (middleScale - 1.0) * animationProgress));
        await tester.sendEventToBinding(
          PointerScrollEvent(
            kind: PointerDeviceKind.mouse,
            position: center,
            scrollDelta: const Offset(0.0, wheelDistance),
          ),
        );
        final viewer = tester.widget<TsukuyomiInteractiveViewer>(find.byType(TsukuyomiInteractiveViewer));
        final matrix = viewer.transformationController!.value.clone();
        expect(matrix.getMaxScaleOnAxis(), moreOrLessEquals(1.0));
        scales.clear();
        await tester.pump();
        await tester.pump(scaleDuration);
        expect(viewer.transformationController!.value, matrix);
        expect(scales, isEmpty);
      });

      for (final pinching in [false, true]) {
        testWidgets('when interrupted by a new gesture ($axis, pinching: $pinching)', (WidgetTester tester) async {
          const middleScale = 2.0;
          const scaleDuration = Duration(seconds: 1);
          const animationProgress = 0.4;
          const fingerDistance = 50.0;
          const closedFingerDistance = 1.0;
          final itemKeys = List.generate(40, (index) => index);
          final scales = <double>[];

          Widget builder() {
            return _buildList(
              itemKeys: itemKeys,
              axis: axis,
              initialIndex: 10,
              middleScale: middleScale,
              scaleDuration: scaleDuration,
              onScaleUpdate: scales.add,
            );
          }

          await tester.pumpWidget(builder());
          final center = tester.getCenter(find.byType(TsukuyomiInteractiveList));
          await _doubleTap(tester, center);
          await tester.pump();
          await tester.pump(scaleDuration * animationProgress);
          expect(scales.last, moreOrLessEquals(1.0 + (middleScale - 1.0) * animationProgress));
          final firstPosition = pinching ? center - const Offset(fingerDistance, 0.0) : center;
          final first = await tester.startGesture(firstPosition, pointer: 1);
          final second = pinching ? await tester.startGesture(center + const Offset(fingerDistance, 0.0), pointer: 2) : null;
          await tester.pump(kDoubleTapMinTime);
          if (second != null) {
            await first.moveBy(const Offset(-kTouchSlop * 2.0, 0.0));
            await second.moveBy(const Offset(kTouchSlop * 2.0, 0.0));
            await tester.pump();
            await first.moveTo(center - const Offset(closedFingerDistance, 0.0));
            await second.moveTo(center + const Offset(closedFingerDistance, 0.0));
            await tester.pump();
            expect(scales.last, moreOrLessEquals(1.0));
          } else {
            final delta = axis == Axis.vertical ? const Offset(0.0, -kTouchSlop * 2.0) : const Offset(-kTouchSlop * 2.0, 0.0);
            await first.moveBy(delta);
            await tester.pump();
          }
          final viewer = tester.widget<TsukuyomiInteractiveViewer>(find.byType(TsukuyomiInteractiveViewer));
          final matrix = viewer.transformationController!.value.clone();
          scales.clear();
          await tester.pump(scaleDuration);
          expect(viewer.transformationController!.value, matrix);
          expect(scales, isEmpty);
          await first.up();
          await second?.up();
          await tester.pumpAndSettle(const Duration(milliseconds: 16));
        });
      }
    }
  });

  group('TsukuyomiInteractiveList respects dragging', () {
    for (final axis in Axis.values) {
      for (final zoomed in [false, true]) {
        testWidgets('when dragging along the main axis ($axis, zoomed: $zoomed)', (WidgetTester tester) async {
          const initialIndex = 10;
          const itemExtent = 100.0;
          const viewportExtent = 600.0;
          const middleScale = 2.0;
          const scaleDuration = Duration(milliseconds: 200);
          const dragDistance = 100.0;
          const eventInterval = Duration(milliseconds: 16);
          final itemKeys = List.generate(40, (index) => index);
          final controller = TsukuyomiListController();
          final scales = <double>[];
          final trackedIndex = initialIndex + viewportExtent ~/ itemExtent ~/ 2;

          Widget builder() {
            return _buildList(
              itemKeys: itemKeys,
              axis: axis,
              initialIndex: initialIndex,
              itemExtent: itemExtent,
              viewportSize: const Size.square(viewportExtent),
              middleScale: middleScale,
              scaleDuration: scaleDuration,
              controller: controller,
              onScaleUpdate: scales.add,
            );
          }

          await tester.pumpWidget(builder());
          final center = tester.getCenter(find.byType(TsukuyomiInteractiveList));
          if (zoomed) {
            await _doubleTap(tester, center);
            await tester.pump();
            await tester.pump(scaleDuration);
          }
          scales.clear();
          final trackedItem = find.byKey(ValueKey(trackedIndex));
          final gesture = await tester.startGesture(center);
          final startDelta = axis == Axis.vertical ? const Offset(0.0, -kTouchSlop * 2.0) : const Offset(-kTouchSlop * 2.0, 0.0);
          await gesture.moveBy(startDelta, timeStamp: eventInterval);
          await tester.pump(eventInterval);
          final before = tester.getTopLeft(trackedItem);
          final beforeOffset = controller.anchorIndex * itemExtent + controller.position.pixels;
          final delta = axis == Axis.vertical ? const Offset(0.0, -dragDistance) : const Offset(-dragDistance, 0.0);
          await gesture.moveBy(delta, timeStamp: eventInterval * 2);
          await tester.pump(eventInterval);
          final after = tester.getTopLeft(trackedItem);
          final displacement = axis == Axis.vertical ? after.dy - before.dy : after.dx - before.dx;
          final afterOffset = controller.anchorIndex * itemExtent + controller.position.pixels;
          final scale = zoomed ? middleScale : 1.0;
          expect(displacement, moreOrLessEquals(-dragDistance));
          expect(afterOffset - beforeOffset, moreOrLessEquals(dragDistance / scale));
          expect(scales, isEmpty);
          // 松手前停止移动，避免惯性滚动影响拖动距离的验证
          await tester.pump(kPressTimeout);
          await gesture.up(timeStamp: eventInterval * 2 + kPressTimeout);
          await tester.pumpAndSettle(const Duration(milliseconds: 16));
          if (zoomed) {
            final offsetBeforePan = controller.anchorIndex * itemExtent + controller.position.pixels;
            final crossDelta = axis == Axis.vertical ? const Offset(dragDistance, 0.0) : const Offset(0.0, dragDistance);
            final pan = await tester.startGesture(center);
            await tester.pump(kDoubleTapMinTime);
            final panStart = axis == Axis.vertical ? const Offset(kTouchSlop * 2.0, 0.0) : const Offset(0.0, kTouchSlop * 2.0);
            await pan.moveBy(panStart, timeStamp: kDoubleTapMinTime);
            await tester.pump();
            final beforePan = tester.getTopLeft(trackedItem);
            await pan.moveBy(crossDelta, timeStamp: kDoubleTapMinTime + eventInterval);
            await tester.pump(eventInterval);
            final afterPan = tester.getTopLeft(trackedItem);
            final displacement = axis == Axis.vertical ? afterPan.dx - beforePan.dx : afterPan.dy - beforePan.dy;
            expect(displacement, moreOrLessEquals(dragDistance));
            expect(controller.anchorIndex * itemExtent + controller.position.pixels, moreOrLessEquals(offsetBeforePan));
            expect(scales, isEmpty);
            await tester.pump(kPressTimeout);
            await pan.up(timeStamp: kDoubleTapMinTime + eventInterval + kPressTimeout);
            await tester.pumpAndSettle(const Duration(milliseconds: 16));
            expect(controller.anchorIndex * itemExtent + controller.position.pixels, moreOrLessEquals(offsetBeforePan));
            expect(scales, isEmpty);
          }
        });
      }
    }
  });

  group('TsukuyomiInteractiveList respects flinging', () {
    for (final axis in Axis.values) {
      for (final zoomed in [false, true]) {
        for (final direction in [-1.0, 1.0]) {
          testWidgets('when releasing a fast drag ($axis, zoomed: $zoomed, direction: $direction)', (WidgetTester tester) async {
            const initialIndex = 10;
            const itemExtent = 100.0;
            const middleScale = 2.0;
            const scaleDuration = Duration(milliseconds: 200);
            const flingDistance = 120.0;
            const flingSpeed = 1200.0;
            const eventInterval = Duration(milliseconds: 16);
            const physics = ClampingScrollPhysics();
            final itemKeys = List.generate(40, (index) => index);
            final controller = TsukuyomiListController();

            Widget builder() {
              return _buildList(
                itemKeys: itemKeys,
                axis: axis,
                initialIndex: initialIndex,
                itemExtent: itemExtent,
                middleScale: middleScale,
                scaleDuration: scaleDuration,
                controller: controller,
                physics: physics,
              );
            }

            await tester.pumpWidget(builder());
            final center = tester.getCenter(find.byType(TsukuyomiInteractiveList));
            if (zoomed) {
              await _doubleTap(tester, center);
              await tester.pump();
              await tester.pump(scaleDuration);
            }
            final distance = direction * flingDistance;
            final delta = axis == Axis.vertical ? Offset(0.0, distance) : Offset(distance, 0.0);
            await tester.flingFrom(center, delta, flingSpeed);
            final scale = zoomed ? middleScale : 1.0;
            final expectedVelocity = -direction * flingSpeed / scale;
            final simulation = physics.createBallisticSimulation(controller.position, expectedVelocity)!;
            await tester.pump();
            final before = controller.anchorIndex * itemExtent + controller.position.pixels;
            await tester.pump(eventInterval);
            final after = controller.anchorIndex * itemExtent + controller.position.pixels;
            final elapsed = eventInterval.inMicroseconds / Duration.microsecondsPerSecond;
            final expectedDistance = simulation.x(elapsed) - simulation.x(0.0);
            expect((after - before) * -direction, greaterThan(0.0));
            expect(after - before, moreOrLessEquals(expectedDistance));
            await tester.pumpAndSettle(eventInterval);
            final stoppedOffset = controller.anchorIndex * itemExtent + controller.position.pixels;
            final expectedTotalDistance = simulation.x(double.infinity) - simulation.x(0.0);
            expect(stoppedOffset - before, moreOrLessEquals(expectedTotalDistance));
            expect(controller.position.isScrollingNotifier.value, false);
          });
        }
      }
    }
  });

  group('TsukuyomiInteractiveList respects pinch scaling', () {
    for (final axis in Axis.values) {
      testWidgets('when reaching scale limits ($axis)', (WidgetTester tester) async {
        const initialIndex = 10;
        const trackedIndex = initialIndex + 2;
        const itemExtent = 100.0;
        const viewportExtent = 600.0;
        const maxScale = 2.0;
        const fingerDistance = itemExtent / 2.0;
        const recognizedFingerDistance = fingerDistance + kTouchSlop * 2.0;
        const intermediateFingerDistance = itemExtent;
        const closedFingerDistance = 1.0;
        final itemKeys = List.generate(40, (index) => index);
        final controller = TsukuyomiListController();
        final scales = <double>[];

        Widget builder() {
          return _buildList(
            itemKeys: itemKeys,
            axis: axis,
            initialIndex: initialIndex,
            itemExtent: itemExtent,
            viewportSize: const Size.square(viewportExtent),
            middleScale: maxScale,
            maxScale: maxScale,
            controller: controller,
            onScaleUpdate: scales.add,
          );
        }

        await tester.pumpWidget(builder());
        final trackedItem = find.byKey(const ValueKey(trackedIndex));
        final center = tester.getCenter(trackedItem);
        final first = await tester.startGesture(center - const Offset(fingerDistance, 0.0), pointer: 1);
        final second = await tester.startGesture(center + const Offset(fingerDistance, 0.0), pointer: 2);
        await tester.pump(kDoubleTapMinTime);
        final firstRecognizedPosition = center - const Offset(recognizedFingerDistance, 0.0);
        final secondRecognizedPosition = center + const Offset(recognizedFingerDistance, 0.0);
        await first.moveTo(firstRecognizedPosition);
        await second.moveTo(secondRecognizedPosition);
        await tester.pump();
        final beforeSpan = (secondRecognizedPosition - firstRecognizedPosition).distance;
        final viewer = tester.widget<TsukuyomiInteractiveViewer>(find.byType(TsukuyomiInteractiveViewer));
        final beforeScale = viewer.transformationController!.value.getMaxScaleOnAxis();
        final beforeRect = tester.getRect(trackedItem);
        final contentFraction = Offset(
          (center.dx - beforeRect.left) / beforeRect.width,
          (center.dy - beforeRect.top) / beforeRect.height,
        );
        final firstTargetPosition = center - const Offset(intermediateFingerDistance, 0.0);
        final secondTargetPosition = center + const Offset(intermediateFingerDistance, 0.0);
        await first.moveTo(firstTargetPosition);
        await second.moveTo(secondTargetPosition);
        await tester.pump();
        final afterSpan = (secondTargetPosition - firstTargetPosition).distance;
        final intermediateScale = scales.last;
        expect(intermediateScale, inExclusiveRange(1.0, maxScale));
        expect(intermediateScale / beforeScale, moreOrLessEquals(afterSpan / beforeSpan));
        final itemRect = tester.getRect(trackedItem);
        final extent = axis == Axis.vertical ? itemRect.height : itemRect.width;
        expect(extent, moreOrLessEquals(itemExtent * intermediateScale));
        expect(itemRect.left + itemRect.width * contentFraction.dx, moreOrLessEquals(center.dx));
        expect(itemRect.top + itemRect.height * contentFraction.dy, moreOrLessEquals(center.dy));
        await first.moveTo(center - const Offset(viewportExtent, 0.0));
        await second.moveTo(center + const Offset(viewportExtent, 0.0));
        await tester.pump();
        expect(scales.last, moreOrLessEquals(maxScale));
        expect(controller.anchorIndex, initialIndex);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
        await first.moveTo(center - const Offset(closedFingerDistance, 0.0));
        await second.moveTo(center + const Offset(closedFingerDistance, 0.0));
        await tester.pump();
        expect(scales.last, moreOrLessEquals(1.0));
        await first.up();
        await second.up();
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        expect(scales, everyElement(inInclusiveRange(1.0, maxScale)));
        expect(controller.anchorIndex, initialIndex);
        expect(controller.position.pixels, moreOrLessEquals(0.0));
      });

      testWidgets('when adding and removing a second pointer during a drag ($axis)', (WidgetTester tester) async {
        const initialIndex = 10;
        const itemExtent = 100.0;
        const dragDistance = 100.0;
        const fingerDistance = 60.0;
        const eventInterval = Duration(milliseconds: 16);
        final itemKeys = List.generate(40, (index) => index);
        final controller = TsukuyomiListController();

        Widget builder() {
          return _buildList(
            itemKeys: itemKeys,
            axis: axis,
            initialIndex: initialIndex,
            itemExtent: itemExtent,
            controller: controller,
          );
        }

        await tester.pumpWidget(builder());
        final center = tester.getCenter(find.byType(TsukuyomiInteractiveList));
        final startDelta = axis == Axis.vertical ? const Offset(0.0, -kTouchSlop * 2.0) : const Offset(-kTouchSlop * 2.0, 0.0);
        final dragDelta = axis == Axis.vertical ? const Offset(0.0, -dragDistance) : const Offset(-dragDistance, 0.0);
        final crossDelta = axis == Axis.vertical ? const Offset(fingerDistance, 0.0) : const Offset(0.0, fingerDistance);
        final first = await tester.startGesture(center, pointer: 1);
        await first.moveBy(startDelta, timeStamp: eventInterval);
        await tester.pump(eventInterval);
        await first.moveBy(dragDelta, timeStamp: eventInterval * 2);
        await tester.pump(eventInterval);
        final beforePinch = controller.anchorIndex * itemExtent + controller.position.pixels;
        expect(beforePinch, greaterThan(initialIndex * itemExtent));
        final second = await tester.createGesture(pointer: 2);
        await second.down(center + startDelta + dragDelta + crossDelta, timeStamp: eventInterval * 2);
        await first.moveBy(dragDelta, timeStamp: eventInterval * 3);
        await second.moveBy(dragDelta, timeStamp: eventInterval * 3);
        await tester.pump(eventInterval);
        expect(controller.anchorIndex * itemExtent + controller.position.pixels, moreOrLessEquals(beforePinch));
        await second.up(timeStamp: eventInterval * 3);
        await tester.pump();
        expect(controller.anchorIndex * itemExtent + controller.position.pixels, moreOrLessEquals(beforePinch));
        await first.moveBy(startDelta, timeStamp: eventInterval * 4);
        await tester.pump(eventInterval);
        final beforeDrag = controller.anchorIndex * itemExtent + controller.position.pixels;
        final viewer = tester.widget<TsukuyomiInteractiveViewer>(find.byType(TsukuyomiInteractiveViewer));
        final scale = viewer.transformationController!.value.getMaxScaleOnAxis();
        await first.moveBy(dragDelta, timeStamp: eventInterval * 5);
        await tester.pump(eventInterval);
        final afterDrag = controller.anchorIndex * itemExtent + controller.position.pixels;
        expect(afterDrag - beforeDrag, moreOrLessEquals(dragDistance / scale));
        await tester.pump(kPressTimeout);
        await first.up(timeStamp: eventInterval * 5 + kPressTimeout);
        await tester.pumpAndSettle(eventInterval);
        expect(controller.position.isScrollingNotifier.value, false);
        final stoppedOffset = controller.anchorIndex * itemExtent + controller.position.pixels;
        await tester.pump(kPressTimeout);
        expect(controller.anchorIndex * itemExtent + controller.position.pixels, moreOrLessEquals(stoppedOffset));
      });
    }
  });

  group('TsukuyomiInteractiveList respects zoomed boundaries', () {
    for (final axis in Axis.values) {
      for (final itemCount in [2, 4, 40]) {
        testWidgets('when scrolling to both ends ($axis, items: $itemCount)', (WidgetTester tester) async {
          const itemExtent = 100.0;
          const viewportExtent = 600.0;
          const middleScale = 2.0;
          const scaleDuration = Duration(milliseconds: 200);
          final itemKeys = List.generate(itemCount, (index) => index);
          final controller = TsukuyomiListController();

          Widget builder() {
            return _buildList(
              itemKeys: itemKeys,
              axis: axis,
              itemExtent: itemExtent,
              viewportSize: const Size.square(viewportExtent),
              middleScale: middleScale,
              scaleDuration: scaleDuration,
              controller: controller,
              physics: const ClampingScrollPhysics(),
            );
          }

          await tester.pumpWidget(builder());
          final viewport = tester.getRect(find.byType(TsukuyomiInteractiveList));
          final contentExtent = itemCount * itemExtent;
          await _doubleTap(tester, viewport.center);
          await tester.pump();
          await tester.pump(scaleDuration);
          controller.jumpToIndex(0);
          await tester.pumpAndSettle(const Duration(milliseconds: 16));
          controller.position.jumpTo(controller.position.minScrollExtent);
          await tester.pumpAndSettle(const Duration(milliseconds: 16));
          final firstRect = tester.getRect(find.byKey(const ValueKey(0)));
          final firstLeading = axis == Axis.vertical ? firstRect.top : firstRect.left;
          final viewportLeading = axis == Axis.vertical ? viewport.top : viewport.left;
          expect(firstLeading, moreOrLessEquals(viewportLeading));
          final lastItem = find.byKey(ValueKey(itemCount - 1));
          final viewportTrailing = axis == Axis.vertical ? viewport.bottom : viewport.right;
          if (contentExtent * middleScale <= viewportExtent) {
            final lastRect = tester.getRect(lastItem);
            final lastTrailing = axis == Axis.vertical ? lastRect.bottom : lastRect.right;
            expect(lastTrailing, lessThanOrEqualTo(viewportTrailing));
            final lastLeading = axis == Axis.vertical ? lastRect.top : lastRect.left;
            expect(lastLeading, greaterThanOrEqualTo(viewportLeading));
          } else {
            if (contentExtent < viewportExtent) {
              final lastRect = tester.getRect(lastItem);
              final lastTrailing = axis == Axis.vertical ? lastRect.bottom : lastRect.right;
              final delta = (lastTrailing - viewportTrailing) / middleScale;
              controller.position.jumpTo(controller.position.pixels + delta);
            } else {
              controller.jumpToIndex(itemCount - 1);
              await tester.pumpAndSettle(const Duration(milliseconds: 16));
              controller.position.jumpTo(controller.position.maxScrollExtent);
            }
            await tester.pumpAndSettle(const Duration(milliseconds: 16));
            final lastRect = tester.getRect(lastItem);
            final lastTrailing = axis == Axis.vertical ? lastRect.bottom : lastRect.right;
            expect(lastTrailing, moreOrLessEquals(viewportTrailing));
          }
          expect(controller.position.outOfRange, false);
        });
      }
    }
  });

  testWidgets('TsukuyomiInteractiveList respects controller replacement', (WidgetTester tester) async {
    const initialIndex = 10;
    const targetIndex = initialIndex + 1;
    const itemExtent = 100.0;
    const scrollOffset = itemExtent / 4.0;
    final itemKeys = List.generate(40, (index) => index);
    final firstController = TsukuyomiListController();
    final secondController = TsukuyomiListController();

    Widget builder(TsukuyomiListController? controller) {
      return _buildList(itemKeys: itemKeys, initialIndex: initialIndex, itemExtent: itemExtent, controller: controller);
    }

    await tester.pumpWidget(builder(firstController));
    firstController.position.jumpTo(scrollOffset);
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    final initialItem = find.byKey(const ValueKey(initialIndex));
    final initialRect = tester.getRect(initialItem);
    expect(initialRect.top, moreOrLessEquals(-scrollOffset));
    await tester.pumpWidget(builder(secondController));
    expect(() => firstController.position, throwsAssertionError);
    expect(tester.getRect(initialItem), initialRect);
    secondController.jumpToIndex(targetIndex);
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    final targetItem = find.byKey(const ValueKey(targetIndex));
    final targetRect = tester.getRect(targetItem);
    expect(targetRect.top, moreOrLessEquals(0.0));
    await tester.pumpWidget(builder(null));
    expect(() => secondController.position, throwsAssertionError);
    expect(tester.getRect(targetItem), targetRect);
    await tester.pumpWidget(builder(firstController));
    expect(tester.getRect(targetItem), targetRect);
    firstController.jumpToIndex(0);
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    expect(tester.getTopLeft(find.text('0')).dy, moreOrLessEquals(0.0));
    await tester.pumpWidget(const SizedBox());
    expect(() => firstController.position, throwsAssertionError);
  });

  testWidgets('TsukuyomiInteractiveList respects a nonlinear scale curve', (WidgetTester tester) async {
    const middleScale = 2.0;
    const scaleCurve = Curves.easeInCubic;
    const scaleDuration = Duration(milliseconds: 200);
    const animationProgress = 0.5;
    final itemKeys = List.generate(20, (index) => index);
    final scales = <double>[];

    Widget builder() {
      return _buildList(
        itemKeys: itemKeys,
        middleScale: middleScale,
        scaleCurve: scaleCurve,
        scaleDuration: scaleDuration,
        onScaleUpdate: scales.add,
      );
    }

    await tester.pumpWidget(builder());
    await _doubleTap(tester, tester.getCenter(find.byType(TsukuyomiInteractiveList)));
    await tester.pump();
    await tester.pump(scaleDuration * animationProgress);
    final expectedScale = 1.0 + (middleScale - 1.0) * scaleCurve.transform(animationProgress);
    expect(scales.last, moreOrLessEquals(expectedScale));
    final viewer = tester.widget<TsukuyomiInteractiveViewer>(find.byType(TsukuyomiInteractiveViewer));
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), moreOrLessEquals(expectedScale));
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    expect(scales.last, moreOrLessEquals(middleScale));
  });

  testWidgets('TsukuyomiInteractiveList respects updated scale duration', (WidgetTester tester) async {
    const middleScale = 2.0;
    const initialDuration = Duration(milliseconds: 500);
    const updatedDuration = Duration(milliseconds: 200);
    final itemKeys = List.generate(20, (index) => index);
    final scales = <double>[];

    Widget builder(Duration duration) {
      return _buildList(
        itemKeys: itemKeys,
        middleScale: middleScale,
        scaleDuration: duration,
        onScaleUpdate: scales.add,
      );
    }

    await tester.pumpWidget(builder(initialDuration));
    await tester.pumpWidget(builder(updatedDuration));
    final center = tester.getCenter(find.byType(TsukuyomiInteractiveList));
    await _doubleTap(tester, center);
    await tester.pump();
    await tester.pump(updatedDuration ~/ 2);
    expect(scales.last, moreOrLessEquals((1.0 + middleScale) / 2.0));
    await tester.pump(updatedDuration ~/ 2);
    expect(scales.last, moreOrLessEquals(middleScale));
  });

  testWidgets('TsukuyomiInteractiveList disposes an active scale animation', (WidgetTester tester) async {
    const middleScale = 2.0;
    const scaleDuration = Duration(milliseconds: 200);
    final itemKeys = List.generate(20, (index) => index);
    final scales = <double>[];

    Widget builder() {
      return _buildList(
        itemKeys: itemKeys,
        middleScale: middleScale,
        scaleDuration: scaleDuration,
        onScaleUpdate: scales.add,
      );
    }

    await tester.pumpWidget(builder());
    await _doubleTap(tester, tester.getCenter(find.byType(TsukuyomiInteractiveList)));
    await tester.pump();
    await tester.pump(scaleDuration ~/ 2);
    expect(scales.last, inExclusiveRange(1.0, middleScale));
    final viewer = tester.widget<TsukuyomiInteractiveViewer>(find.byType(TsukuyomiInteractiveViewer));
    final transformationController = viewer.transformationController!;
    await tester.pumpWidget(const SizedBox());
    expect(() => transformationController.addListener(() {}), throwsFlutterError);
    final updateCount = scales.length;
    await tester.pump(scaleDuration);
    expect(scales.length, updateCount);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildList({
  required List<int> itemKeys,
  Axis axis = Axis.vertical,
  int initialIndex = 0,
  double itemExtent = 100.0,
  Size viewportSize = const Size.square(600.0),
  Offset viewportOffset = Offset.zero,
  double middleScale = 2.0,
  double maxScale = 5.0,
  Curve scaleCurve = Curves.linear,
  Duration scaleDuration = const Duration(milliseconds: 200),
  TsukuyomiListController? controller,
  ScrollPhysics? physics,
  ValueChanged<List<TsukuyomiListItem>>? onItemsChanged,
  ValueChanged<double>? onScaleUpdate,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: viewportOffset.dx, top: viewportOffset.dy),
        child: SizedBox(
          width: viewportSize.width,
          height: viewportSize.height,
          child: TsukuyomiInteractiveList.builder(
            itemKeys: itemKeys,
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey(itemKeys[index]),
              width: axis == Axis.horizontal ? itemExtent : null,
              height: axis == Axis.vertical ? itemExtent : null,
              child: Text('${itemKeys[index]}'),
            ),
            scrollDirection: axis,
            initialScrollIndex: initialIndex,
            middleScale: middleScale,
            maxScale: maxScale,
            scaleDuration: scaleDuration,
            scaleCurve: scaleCurve,
            controller: controller,
            physics: physics,
            onItemsChanged: onItemsChanged,
            onScaleUpdate: onScaleUpdate,
          ),
        ),
      ),
    ),
  );
}

Future<void> _doubleTap(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(kDoubleTapMinTime);
  await tester.tapAt(position);
}
