import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import 'chapter_service.dart';
import 'widgets/chapter_gesture_navigation.dart';

part 'chapter_controller.freezed.dart';

part 'chapter_controller.g.dart';

/// 章节页面控制器
@riverpod
class ChapterController extends _$ChapterController with AsyncNotifierMixin {
  @override
  Future<ChapterState> build(String chapterId) async {
    final chapter = await listenAsync(
      provider: chapterStreamByIdProvider(int.parse(chapterId)),
      update: (state, data) => state.copyWith(chapter: data),
    );
    final manga = await listenAsync(
      provider: mangaStreamByIdProvider(chapter.manga),
      update: (state, data) => state.copyWith(manga: data),
    );
    final source = await listenAsync(
      provider: sourceByIdProvider(manga.source),
      update: (state, data) => state.copyWith(source: data),
    );
    final images = await listenAsync(
      provider: chapterImagesProvider(source, manga, chapter),
      update: (state, data) => state.copyWith(images: data),
    );
    final chapterProgress = images.length == chapter.images ? chapter.progress : 0;
    final initialProgress = chapterProgress.clamp(1, images.length);
    return ChapterState(
      source: source,
      manga: manga,
      // 更新章节图片数量，最终在检测到图片列表变化时自动更新数据库数据
      chapter: chapter.copyWith(images: images.length, progress: chapterProgress),
      images: images,
      scale: 1.0,
      progress: initialProgress,
      initialProgress: initialProgress,
      isGestureVisible: false,
      isNavigationBarVisible: false,
      gestureNavigationStyle: GestureNavigationStyle.crowbar,
      listController: TsukuyomiListController(),
    );
  }

  /// 获取应用栏显示状态
  ProviderBase<bool> getChapterAppBarVisibleProvider() {
    return _chapterAppBarVisibleProvider(chapterId);
  }

  /// 切换导航栏显示状态
  void toggleNavigationBar([bool? visible]) {
    if (data == null) {
      final appBarVisibleProvider = _chapterAppBarVisibleProvider(chapterId);
      ref.read(appBarVisibleProvider.notifier).toggle(visible);
    } else {
      update((state) {
        final isNavigationBarVisible = visible ?? !state.isNavigationBarVisible;
        return state.copyWith(isNavigationBarVisible: isNavigationBarVisible);
      });
    }
  }

  /// 更新章节阅读进度 TODO 节流处理
  void updateChapterProgress(ChapterState? state, int? progress) {
    if (state == null || progress == null) return;
    // 更新当前页面章节阅读进度
    if (progress != state.progress) {
      update((state) => state.copyWith(progress: progress));
    }
    // 更新数据库的章节阅读进度
    if (progress != state.chapter.progress) {
      ref.read(chapterServiceProvider).updateChapter(state.chapter.copyWith(progress: progress));
    }
  }

  /// 处理页面跳转事件 TODO 节流处理
  void onPageChanged(int value) {
    data?.listController.jumpToIndex(value - 1);
    updateChapterProgress(data, value);
  }

  /// 处理列表缩放比例更新事件
  void onListScaleUpdate(double scale) {
    update((state) => state.copyWith(scale: scale));
  }

  /// 处理列表项更新事件
  void onListItemsChanged(List<TsukuyomiListItem> items) {
    if (data == null) return;
    // 当前阅读进度
    int? progress;
    // 可见列表项集合
    final visibleItems = <TsukuyomiListItem>{};
    // 逆序遍历所有列表项
    for (var i = items.length - 1; i >= 0; i--) {
      final item = items[i];
      // 如果当前阅读进度对应的列表项处于原点则不改变阅读进度，避免跳转时由于尺寸改变导致阅读进度来回跳动
      if (item.index == data!.progress - 1 && item.leading == 0.0) {
        progress = item.index + 1;
        break;
      }
      // 如果已经有候选阅读进度则只需要继续判断当前阅读进度对应的列表项是否处于原点即可
      if (progress != null) continue;
      // 如果列表项底部可见
      if (item.trailing > 0 && item.trailing <= 1.0) {
        // 将最后一个底部可见的列表项作为候选阅读进度
        progress = item.index + 1;
        // 如果可见列表项在当前阅读进度对应的列表项之前则不用继续遍历判断当前阅读进度对应的列表项是否处于原点
        if (item.index < data!.progress) break;
      }
      // 如果列表项任意区域可见
      if (item.leading <= 1.0 && item.trailing >= 0.0) visibleItems.add(item);
      // 如果遍历完成后只有一个列表项可见
      if (i == 0 && visibleItems.length == 1) progress = visibleItems.first.index + 1;
    }
    // 更新章节阅读进度
    updateChapterProgress(data, progress);
  }

  /// 处理菜单按钮点击事件
  void onMenu() {
    // 切换手势导航和导航栏可见状态
    update(
      (state) => state.copyWith(
        isGestureVisible: false,
        isNavigationBarVisible: !state.isNavigationBarVisible,
      ),
    );
  }

  /// 处理上一页按钮点击事件
  void onPrev() {
    // TODO 处理页面缩放时的行为，如：左上、右上
    update((state) {
      state.listController.slideViewport(-0.75 / state.scale);
      return state.copyWith(isGestureVisible: false);
    });
  }

  /// 处理下一页按钮点击事件
  void onNext() {
    // TODO 处理页面缩放时的行为，如：左下、右下
    update((state) {
      state.listController.slideViewport(0.75 / state.scale);
      return state.copyWith(isGestureVisible: false);
    });
  }
}

/// 应用栏显示状态
@riverpod
class _ChapterAppBarVisible extends _$ChapterAppBarVisible with NotifierMixin {
  @override
  bool build(String chapterId) {
    final provider = chapterControllerProvider(chapterId);
    ref.listen(provider, (previous, next) {
      next.pick(builder: (it) => state = it?.isNavigationBarVisible ?? state);
    });
    return ref.read(provider).valueOrNull?.isNavigationBarVisible ?? false;
  }

  bool toggle([bool? visible]) => state = visible ?? !state;
}

@freezed
class ChapterState with _$ChapterState {
  const factory ChapterState({
    /// 漫画源
    required Source source,

    /// 漫画信息
    required DatabaseManga manga,

    /// 漫画章节信息
    required DatabaseChapter chapter,

    /// 章节图片列表
    required List<SourceImage> images,

    /// 页面缩放比例
    required double scale,

    /// 初始阅读进度
    required int initialProgress,

    /// 当前阅读进度
    required int progress,

    /// 导航栏是否可见
    required bool isNavigationBarVisible,

    /// 手势导航是否可见
    required bool isGestureVisible,

    /// 手势导航布局类型
    required GestureNavigationStyle gestureNavigationStyle,

    /// 列表控制器
    required TsukuyomiListController listController,
  }) = _ChapterState;
}
