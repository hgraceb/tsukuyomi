import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/debug/scaffold/debug_scaffold_service.dart';

part 'debug_scaffold_controller.freezed.dart';
part 'debug_scaffold_controller.g.dart';

@riverpod
class DebugScaffoldController extends _$DebugScaffoldController with AsyncNotifierMixin {
  int _controllerBuildCount = 0;

  @override
  Future<DebugScaffoldState> build() async {
    final buildCount = ++_controllerBuildCount;
    await Future.delayed(const Duration(seconds: 1));
    if (buildCount == 1) {
      ref.read(debugScaffoldServiceProvider).reset();
    }
    if (buildCount.isEven) {
      throw "Test: controller build count '$buildCount' is even.";
    }
    final serviceCount = await listenAsync(
      provider: debugServiceCountProvider,
      update: (state, data) => state.copyWith(serviceCount: data),
    );
    return DebugScaffoldState(
      buildCount: buildCount,
      customCount: 0,
      serviceCount: serviceCount,
    );
  }

  void incrementCustomCount() {
    update((state) => state.copyWith(customCount: state.customCount + 1));
  }

  void decrementCustomCount() {
    update((state) => state.copyWith(customCount: state.customCount - 1));
  }
}

@freezed
class DebugScaffoldState with _$DebugScaffoldState {
  const factory DebugScaffoldState({
    required int buildCount,
    required int customCount,
    required int serviceCount,
  }) = _DebugScaffoldState;
}
