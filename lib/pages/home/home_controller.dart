import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_controller.freezed.dart';

part 'home_controller.g.dart';

/// 首页控制器
@riverpod
class HomeController extends _$HomeController {
  @override
  HomeState build() {
    final pageController = PageController(initialPage: 0);
    ref.onDispose(() => pageController.dispose());
    return HomeState(
      selectedIndex: pageController.initialPage,
      pageController: pageController,
    );
  }

  /// 选择标签页
  void onDestinationSelected(int value) {
    state.pageController.jumpToPage(value);
    state = state.copyWith(selectedIndex: value);
  }
}

/// 首页配置
@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    /// 当前页面索引
    required int selectedIndex,

    /// 页面控制器
    required PageController pageController,
  }) = _HomeState;
}
