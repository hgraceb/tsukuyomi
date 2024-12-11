import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/pages/chapter/chapter_controller.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class ChapterAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChapterAppBar({
    super.key,
    required this.provider,
    required this.elevation,
    required this.backgroundColor,
    this.curve = Curves.easeInOutCubic,
  });

  final Curve curve;

  final double elevation;

  final Color backgroundColor;

  final ChapterControllerProvider provider;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WatchSelect(
      provider: ref.read(provider.notifier).getChapterAppBarVisibleProvider(),
      select: (initial, current) => current,
      builder: (visible) => SelectAsyncWatch(
        provider: provider,
        select: (state) => (manga: state.manga, chapter: state.chapter),
        builder: (state) => _SlideAppBar(
          curve: curve,
          color: backgroundColor,
          elevation: elevation,
          visible: visible,
          loading: state == null,
          // 移除默认的水平安全边距
          title: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: ListTile(
              // 移除默认的文本内容边距
              contentPadding: EdgeInsets.zero,
              title: Text(
                state?.manga.title ?? '',
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                state?.chapter.title ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideAppBar extends StatelessWidget {
  const _SlideAppBar({
    required this.loading,
    required this.visible,
    required this.curve,
    required this.color,
    required this.title,
    required this.elevation,
  });

  final bool loading;

  final bool visible;

  final Curve curve;

  final Color color;

  final Widget title;

  final double elevation;

  @override
  Widget build(BuildContext context) {
    return TsukuyomiAnimatedSwitcher(
      duration: Animate.defaultDuration,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      child: TsukuyomiAppBar(
        title: title,
        elevation: loading ? 0.0 : elevation,
        backgroundColor: loading ? Colors.transparent : color,
      )
          .animate(
            // 页面加载状态发生变化时动态切换顶部应用栏
            key: ValueKey(loading),
            target: visible ? 1.0 : 0.0,
          )
          .fade(begin: 0.0, end: 1.0, curve: curve)
          .slideY(begin: -1.0, end: 0.0),
    );
  }
}
