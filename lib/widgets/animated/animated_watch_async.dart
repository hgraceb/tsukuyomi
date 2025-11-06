import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class AnimatedWatchAsync<T, S, R> extends ConsumerWidget {
  const AnimatedWatchAsync({
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
      builder: (select) => TsukuyomiAnimatedSwitcher(
        child: ref.watch(provider.select(value)).pick(
              data: (v) => KeyedSubtree(
                key: const ValueKey('data'),
                child: builder?.call(select, v) ?? data?.call(select, v) ?? const SizedBox.shrink(),
              ),
              loading: () => KeyedSubtree(
                key: const ValueKey('loading'),
                child: builder?.call(select, null) ?? loading?.call(select) ?? const SizedBox.shrink(),
              ),
              error: (e, s) => KeyedSubtree(
                key: const ValueKey('error'),
                child: builder?.call(select, null) ?? error?.call(select, e, s) ?? const SizedBox.shrink(),
              ),
            ),
      ),
    );
  }
}
