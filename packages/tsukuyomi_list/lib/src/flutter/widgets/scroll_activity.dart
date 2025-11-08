// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'package:tsukuyomi_list/src/tsukuyomi/widgets/scroll_activity.dart';

/// An activity that drives a scroll view through a given animation.
///
/// For example, a [DrivenScrollActivity] is used to implement
/// [ScrollController.animateTo].
///
/// The scrolling will be driven by the given animation parameters
/// or the given [Simulation].
///
/// Unlike a [BallisticScrollActivity], if a [DrivenScrollActivity] is
/// in progress when the scroll metrics change, the activity will continue
/// with its original animation.
///
/// See also:
///
///  * [BallisticScrollActivity], which sets into motion a scroll view.
class DrivenScrollActivity extends ScrollActivity {
  /// Creates an activity that drives a scroll view through an animation
  /// given by animation parameters.
  DrivenScrollActivity(
    super.delegate, {
    required double from,
    required double to,
    required Duration duration,
    required Curve curve,
    required TickerProvider vsync,
  }) : assert(duration > Duration.zero) {
    _completer = Completer<void>();
    _controller =
        AnimationController.unbounded(
            value: from,
            debugLabel: objectRuntimeType(this, 'DrivenScrollActivity'),
            vsync: vsync,
          )
          ..addListener(_tick)
          ..animateTo(
            to,
            duration: duration,
            curve: curve,
          ).whenComplete(_end); // won't trigger if we dispose _controller before it completes.
  }

  /// Creates an activity that drives a scroll view through an animation
  /// given by a [Simulation].
  DrivenScrollActivity.simulation(
    super.delegate,
    Simulation simulation, {
    required TickerProvider vsync,
  }) {
    _completer = Completer<void>();
    _controller =
        AnimationController.unbounded(
            debugLabel: objectRuntimeType(this, 'DrivenScrollActivity'),
            vsync: vsync,
          )
          ..addListener(_tick)
          ..animateWith(
            simulation,
          ).whenComplete(_end); // won't trigger if we dispose _controller before it completes.
  }

  bool _isDisposed = false;
  late final Completer<void> _completer;
  late final AnimationController _controller;

  /// A [Future] that completes when the activity stops.
  ///
  /// For example, this [Future] will complete if the animation reaches the end
  /// or if the user interacts with the scroll view in way that causes the
  /// animation to stop before it reaches the end.
  Future<void> get done => _completer.future;

  void _tick() {
    if (!applyMoveTo(_controller.value)) {
      delegate.goIdle();
    }
  }

  /// Move the position to the given location.
  ///
  /// If the new position was fully applied, returns true. If there was any
  /// overflow, returns false.
  ///
  /// The default implementation calls [ScrollActivityDelegate.setPixels]
  /// and returns true if the overflow was zero.
  @protected
  bool applyMoveTo(double value) {
    return delegate.setPixels(value).abs() < precisionErrorTolerance;
  }

  void _end() {
    // Check if the activity was disposed before going ballistic because _end might be called
    // if _controller is disposed just after completion.
    if (!_isDisposed) {
      delegate.goBallistic(velocity);
    }
  }

  @override
  void dispatchOverscrollNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double overscroll,
  ) {
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: overscroll,
      velocity: velocity,
    ).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _controller.velocity;

  @override
  void dispose() {
    _isDisposed = true;
    _completer.complete();
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($_controller)';
  }
}
