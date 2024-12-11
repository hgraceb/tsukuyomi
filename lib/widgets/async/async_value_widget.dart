import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/extension/extension.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    this.builder,
    this.loading,
    this.data,
    this.error,
  });

  final AsyncValue<T> value;

  final Widget Function(T? value)? builder;

  final Widget Function()? loading;

  final Widget Function(T value)? data;

  final Widget Function(Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context) {
    return value.pick(
      builder: builder,
      data: data,
      loading: loading,
      error: error,
    );
  }
}

class AnimatedAsyncValueWidget<T> extends StatelessWidget {
  const AnimatedAsyncValueWidget({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 300),
    this.builder,
    this.loading,
    this.data,
    this.error,
  });

  final AsyncValue<T> value;

  final Duration duration;

  final Widget Function(T? value)? builder;

  final Widget Function()? loading;

  final Widget Function(T value)? data;

  final Widget Function(Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context) {
    return AsyncValueWidget(
      value: value,
      data: (value) {
        return TsukuyomiAnimatedSwitcher(
          duration: duration,
          child: KeyedSubtree(
            key: const ValueKey('data'),
            child: builder?.call(value) ?? data?.call(value) ?? const SizedBox.shrink(),
          ),
        );
      },
      loading: () {
        return TsukuyomiAnimatedSwitcher(
          duration: duration,
          child: KeyedSubtree(
            key: const ValueKey('loading'),
            child: builder?.call(null) ?? loading?.call() ?? const SizedBox.shrink(),
          ),
        );
      },
      error: (e, s) {
        return TsukuyomiAnimatedSwitcher(
          duration: duration,
          child: KeyedSubtree(
            key: const ValueKey('error'),
            child: builder?.call(null) ?? error?.call(e, s) ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
