import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

typedef SliverDataBuilder<T> = Widget Function<R>({required R Function(T state) select, required Widget Function(R value) data});

typedef SliverAppBarBuilder<T> = Widget Function<R>({required R Function(T state) select, required Widget Function(R? value) builder});

class TsukuyomiAsyncScaffold<T> extends ConsumerWidget {
  const TsukuyomiAsyncScaffold({
    super.key,
    required this.provider,
    this.sliverAppBar,
    this.sliverAppBarBuilder,
    this.sliversBody,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.scrollController,
    this.scrollPhysics,
  });

  final ProviderBase<AsyncValue<T>> provider;

  final Widget Function(SliverDataBuilder<T> builder)? sliverAppBar;

  final Widget Function(SliverAppBarBuilder<T> builder)? sliverAppBarBuilder;

  final List<Widget> Function(SliverDataBuilder<T> builder)? sliversBody;

  final Widget? floatingActionButton;

  final FloatingActionButtonLocation? floatingActionButtonLocation;

  final ScrollController? scrollController;

  final ScrollPhysics? scrollPhysics;

  SliverAppBarBuilder<T> _sliverAppBarBuilder<R>() {
    return <R>({required select, required builder}) {
      return SelectAsyncWatch<T, R>(
        provider: provider,
        select: select,
        builder: builder,
      );
    };
  }

  SliverDataBuilder<T> _sliverDataBuilder<R>() {
    return <R>({required select, required data}) {
      return SelectAsyncWatch<T, R>(
        provider: provider,
        select: select,
        data: data,
        loading: () => throw AssertionError(),
        error: (error, stackTrace) => throw AssertionError(),
      );
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TsukuyomiAsyncHandler(
      provider: provider,
      builder: (state) => TsukuyomiScaffold(
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: CustomScrollView(
          controller: scrollController,
          // 未加载成功时不允许滚动，避免应用栏滚动到屏幕外导致遮罩消失
          physics: state.requireValue ? scrollPhysics : const NeverScrollableScrollPhysics(),
          slivers: [
            SliverStack(children: [
              // 不显示导航组件的应用栏
              if (state.requireValue && sliverAppBar != null && sliverAppBarBuilder == null) sliverAppBar!(_sliverDataBuilder()),
              // 当前加载状态和渐变背景
              _SliverAsyncState(state: state, provider: provider),
              // 不显示导航组件的应用栏
              if (sliverAppBarBuilder != null) sliverAppBarBuilder!(_sliverAppBarBuilder()),
              // 只包含导航组件的应用栏
              const TsukuyomiSliverLeadingAppBar(),
            ]),
            if (state.requireValue) ...?sliversBody?.call(_sliverDataBuilder()),
          ],
        ),
      ),
    );
  }
}

class _SliverAsyncState<T> extends ConsumerWidget {
  const _SliverAsyncState({required this.state, required this.provider});

  final AsyncValue<bool> state;

  final ProviderBase<AsyncValue<T>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAsyncStateDelegate(
        state: state,
        onRetry: () => ref.invalidate(provider),
        // 未加载成功时占据整个屏幕高度使重试按钮处于可点击状态
        height: state.requireValue ? kToolbarHeight : MediaQuery.sizeOf(context).height,
      ),
    );
  }
}

class _SliverAsyncStateDelegate<T> extends SliverPersistentHeaderDelegate {
  _SliverAsyncStateDelegate({required this.state, required this.height, required this.onRetry});

  final AsyncValue<T> state;

  final double height;

  final VoidCallback onRetry;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      maxHeight: MediaQuery.sizeOf(context).height,
      child: AnimatedAsyncValueWidget(
        value: state,
        duration: const Duration(milliseconds: 500),
        loading: () => const TsukuyomiBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: kToolbarHeight),
              child: CenterLoading(),
            ),
          ),
        ),
        error: (error, stackTrace) => TsukuyomiBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: CenterRetry(onRetry: onRetry),
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(covariant _SliverAsyncStateDelegate oldDelegate) {
    return state != oldDelegate.state || height != oldDelegate.height || onRetry != oldDelegate.onRetry;
  }
}
