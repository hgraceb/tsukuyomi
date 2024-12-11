import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class WatchAsync<T, S, R> extends ConsumerWidget {
  const WatchAsync({
    super.key,
    required this.provider,
    required this.value,
    this.select,
    this.builder,
    this.loading,
    this.data,
    this.error,
  });

  final ProviderBase<T> provider;

  final AsyncValue<R> Function(T state) value;

  final S Function(T initial, T current)? select;

  final Widget Function(S select, R? value)? builder;

  final Widget Function(S select)? loading;

  final Widget Function(S select, R value)? data;

  final Widget Function(S select, Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WatchSelect<T, S>(
      provider: provider,
      select: (initial, current) => select?.call(initial, current) as S,
      builder: (select) => ref.watch(provider.select(value)).pick(
            data: (v) =>
                builder?.call(select, v) ??
                data?.call(select, v) ??
                const SizedBox.shrink(),
            loading: () =>
                builder?.call(select, null) ??
                loading?.call(select) ??
                const SizedBox.shrink(),
            error: (e, s) =>
                builder?.call(select, null) ??
                error?.call(select, e, s) ??
                const SizedBox.shrink(),
          ),
    );
  }
}
