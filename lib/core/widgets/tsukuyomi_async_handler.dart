import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class TsukuyomiAsyncHandler<T> extends ConsumerStatefulWidget {
  const TsukuyomiAsyncHandler({
    super.key,
    required this.provider,
    required this.builder,
  });

  final ProviderBase<AsyncValue<T>> provider;

  final Widget Function(AsyncValue<bool> state) builder;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TsukuyomiAsyncHandlerState();
}

class _TsukuyomiAsyncHandlerState extends ConsumerState<TsukuyomiAsyncHandler> {
  Type? _lastAsyncState;

  void _handleAsyncError(BuildContext context, Object error, StackTrace stackTrace) {
    // 判断是否已经处理过
    if (_lastAsyncState == AsyncError) return;
    // 显示或打印错误信息
    if (context.mounted) {
      ref.read(errorHandlerProvider).show(error, stackTrace);
    } else {
      ref.read(errorHandlerProvider).print(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectAsyncWatch(
      provider: widget.provider,
      select: (state) => null,
      data: (data) {
        _lastAsyncState = AsyncData;
        return widget.builder(const AsyncData(true));
      },
      loading: () {
        _lastAsyncState = AsyncLoading;
        return widget.builder(const AsyncLoading<bool>().copyWithPrevious(const AsyncData(false), isRefresh: false));
      },
      error: (error, stackTrace) {
        _handleAsyncError(context, error, stackTrace);
        _lastAsyncState = AsyncError;
        return widget.builder(AsyncError<bool>(error, stackTrace).copyWithPrevious(const AsyncData(false), isRefresh: false));
      },
    );
  }
}
