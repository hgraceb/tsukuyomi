import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/providers/providers.dart';

class TsukuyomiMediaQuery extends ConsumerWidget {
  const TsukuyomiMediaQuery({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQueryData = MediaQuery.of(context);
    final statusBarHeight = ref.watch(statusBarHeightProvider);

    return MediaQuery(
      data: mediaQueryData.copyWith(
        padding: mediaQueryData.padding.copyWith(
          // 设置顶部最小边距，避免部分页面切换顶部状态栏显示状态导致页面布局错位
          top: statusBarHeight / mediaQueryData.devicePixelRatio,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
