import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'platform_metadata_provider.g.dart';

/// 当前平台状态栏高度
@Riverpod(keepAlive: true)
int statusBarHeight(StatusBarHeightRef ref) => throw UnimplementedError();

/// 当前平台的软键盘是否正在显示
///
/// #### [Flutter Keyboard Visibility 6.0.0](https://pub.dev/packages/flutter_keyboard_visibility/versions/6.0.0) 插件已知问题
/// - 需要最少调用一次对 [KeyboardVisibilityController.onChange] 的监听，直接调用 [KeyboardVisibilityController.isVisible] 可能不会返回正确的值
/// - 应用热重启时即使先调用 [KeyboardVisibilityController.onChange] 再调用 [KeyboardVisibilityController.isVisible] 也可能不会返回正确的值
@Riverpod(keepAlive: true)
bool keyboardVisible(KeyboardVisibleRef ref) {
  bool visible = false;
  final controller = KeyboardVisibilityController();
  final subscription = controller.onChange.listen((isVisible) {
    if (visible != isVisible) ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());
  return visible = controller.isVisible;
}
