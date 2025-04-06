import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/widgets/widgets.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';
import 'package:tsukuyomi_pixel_snap/widgets.dart';

import 'chapter_controller.dart';
import 'widgets/chapter_app_bar.dart';
import 'widgets/chapter_bottom_navigation_bar.dart';
import 'widgets/chapter_gesture_navigation.dart';
import 'widgets/chapter_scaffold.dart';

/// 章节阅读页面
class ChapterPage extends ConsumerStatefulWidget {
  const ChapterPage({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChapterPageState();
}

class _ChapterPageState extends ConsumerState<ChapterPage> {
  @override
  void initState() {
    super.initState();
    final notifier = chapterControllerProvider(widget.chapterId).notifier;
    final provider = ref.read(notifier).getChapterAppBarVisibleProvider();
    // 首次进入时重置应用栏显示状态
    SchedulerBinding.instance.addPostFrameCallback((_) => ref.invalidate(provider));
    // 切换系统状态栏和导航栏的状态
    ref.listenManual(
      fireImmediately: true,
      provider.select((visible) => visible),
      (previous, visible) => SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: visible ? SystemUiOverlay.values : []),
    );
  }

  @override
  void dispose() {
    // 重新显示系统状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = TsukuyomiLocalizations.of(context)!;
    final provider = chapterControllerProvider(widget.chapterId);
    final notifier = ref.read(provider.notifier);
    final backgroundColor = theme.colorScheme.surface.withOpacity(0.9);
    const elevation = 3.0;

    return ChapterScaffold(
      provider: provider,
      appBar: ChapterAppBar(
        provider: provider,
        elevation: elevation,
        backgroundColor: backgroundColor,
      ),
      body: AnimatedSelectAsyncWatch(
        provider: provider,
        select: (state) => state.images,
        data: (images) => Stack(children: [
          SelectAsyncWatch(
            provider: provider,
            select: (state) => (
              listController: state.listController,
              initialIndex: state.initialProgress - 1,
            ),
            builder: (state) => const SizedBox.shrink(),
            data: (state) => TsukuyomiInteractiveList.builder(
              controller: state.listController,
              initialScrollIndex: state.initialIndex,
              onScaleUpdate: notifier.onListScaleUpdate,
              onItemsChanged: notifier.onListItemsChanged,
              itemKeys: List.generate(images.length, (index) => index),
              itemBuilder: (context, index) => SelectAsyncWatch(
                provider: provider,
                select: (state) => (
                  scale: state.scale,
                  source: state.source,
                ),
                builder: (state) => const SizedBox.shrink(),
                data: (state) => TsukuyomiSourceImage(
                  source: state.source,
                  image: images[index],
                  imageBuilder: (context, child) => TsukuyomiPixelFittedBox(
                    scale: state.scale,
                    child: child,
                  ),
                  errorBuilder: (context, url, error) => const SizedBox(
                    width: 300,
                    height: 300,
                    child: ErrorImageWidget(),
                  ),
                  placeholderBuilder: (context) => const SizedBox(
                    width: 300,
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),
          SelectAsyncWatch(
            provider: provider,
            select: (state) => (
              isGestureVisible: state.isGestureVisible,
              gestureNavigationStyle: state.gestureNavigationStyle,
            ),
            builder: (state) => const SizedBox.shrink(),
            data: (state) => ChapterGestureNavigation(
              onMenu: notifier.onMenu,
              onPrev: notifier.onPrev,
              onNext: notifier.onNext,
              visible: state.isGestureVisible,
              gestureNavigationStyle: state.gestureNavigationStyle,
            ),
          ),
          // 在 body 中直接绘制底部导航栏避免影响 SafeArea 的边距范围
          SelectAsyncWatch(
            provider: provider,
            select: (state) => (
              progress: state.progress,
              isNavigationBarVisible: state.isNavigationBarVisible,
            ),
            // TODO 修改所有相关组件的优先级为 builder 优先级最低
            builder: (state) => const SizedBox.shrink(),
            data: (state) => ChapterBottomNavigationBar(
              elevation: elevation,
              progress: state.progress,
              min: images.isNotEmpty ? 1 : 0,
              max: images.isNotEmpty ? images.length : 0,
              backgroundColor: backgroundColor,
              visible: state.isNavigationBarVisible,
              onChanged: (value) => notifier.onPageChanged(value.toInt()),
            ),
          ),
        ]),
        loading: () => GestureDetector(
          onTap: notifier.toggleNavigationBar,
          // 扩展点击事件响应区域
          behavior: HitTestBehavior.opaque,
          // 直接全屏居中显示组件
          child: const CenterLoading(),
        ),
        error: (error, stackTrace) => GestureDetector(
          onTap: notifier.toggleNavigationBar,
          behavior: HitTestBehavior.opaque,
          child: CenterRetry(
            message: l10n.imagesLoadError,
            onRetry: () => ref.invalidate(provider),
          ),
        ),
      ),
    );
  }
}
