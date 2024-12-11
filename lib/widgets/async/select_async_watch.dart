import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class SelectAsyncWatch<T, R> extends ConsumerWidget {
  const SelectAsyncWatch({
    super.key,
    required this.provider,
    required this.select,
    this.builder,
    this.loading,
    this.data,
    this.error,
  });

  final ProviderBase<AsyncValue<T>> provider;

  final R Function(T state) select;

  final Widget Function(R? value)? builder;

  final Widget Function()? loading;

  final Widget Function(R value)? data;

  final Widget Function(Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueWidget(
      value: ref.watch(provider.asyncSelect(select)),
      builder: builder,
      loading: loading,
      data: data,
      error: error,
    );
  }
}

class AnimatedSelectAsyncWatch<T, R> extends ConsumerWidget {
  const AnimatedSelectAsyncWatch({
    super.key,
    required this.provider,
    required this.select,
    this.duration = const Duration(milliseconds: 300),
    this.builder,
    this.loading,
    this.data,
    this.error,
  });

  final ProviderBase<AsyncValue<T>> provider;

  final R Function(T state) select;

  final Duration duration;

  final Widget Function(R? value)? builder;

  final Widget Function()? loading;

  final Widget Function(R value)? data;

  final Widget Function(Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedAsyncValueWidget(
      value: ref.watch(provider.asyncSelect(select)),
      duration: duration,
      builder: builder,
      loading: loading,
      data: data,
      error: error,
    );
  }
}
