// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/providers/providers.dart';

extension AsyncValueExtension<T> on AsyncValue<T> {
  R pick<R>({
    R Function(T? data)? builder,
    R Function()? loading,
    R Function(T data)? data,
    R Function(Object error, StackTrace stackTrace)? error,
  }) {
    assert(builder != null || loading != null && data != null && error != null);
    return when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      skipError: false,
      data: (v) => data?.call(v) ?? builder?.call(v) as R,
      error: (e, s) => error?.call(e, s) ?? builder?.call(null) as R,
      loading: () => loading?.call() ?? builder?.call(null) as R,
    );
  }
}

extension AsyncProviderExtension<T> on ProviderBase<AsyncValue<T>> {
  @protected
  Refreshable<Future<T>> get future {
    return switch (this) {
      AutoDisposeFutureProvider<T> provider => provider.future,
      AutoDisposeStreamProvider<T> provider => provider.future,
      _ => throw UnimplementedError("Assess 'provider.future': $this"),
    };
  }

  ProviderListenable<AsyncValue<R>> asyncSelect<R>(R Function(T state) select) {
    return this.select(
      (value) => value.pick<AsyncValue<R>>(
        loading: () => const AsyncLoading(),
        data: (data) => AsyncData(select(data)),
        error: (error, stackTrace) => AsyncError(error, stackTrace),
      ),
    );
  }
}

mixin NotifierMixin<T> on BuildlessAutoDisposeNotifier<T> {
  @protected
  bool get mounted => (ref as ProviderElementBase).mounted;

  @override
  set state(T value) {
    if (mounted) {
      super.state = value;
    }
  }
}

mixin AsyncNotifierMixin<T> on BuildlessAutoDisposeAsyncNotifier<T> {
  @protected
  T? get data => state.asData?.value;

  @protected
  bool get mounted => (ref as ProviderElementBase).mounted;

  @override
  set state(AsyncValue<T> newState) {
    if (mounted) {
      super.state = newState;
    }
  }

  @protected
  void handlerError(Object error, [StackTrace? stackTrace]) {
    if (mounted) {
      ref.read(errorHandlerProvider).show(error, stackTrace);
    } else {
      ref.read(errorHandlerProvider).print(error, stackTrace);
    }
  }

  @protected
  R listenSync<R>({
    required ProviderBase<R> provider,
    required T? Function(T state, R data) update,
  }) {
    bool? error;
    final exists = ref.exists(provider);
    // 使用 select 过滤未发生变化的值
    ref.listen(provider.select((value) => value), (previous, next) {
      if (error == null) {
        error = false;
        return;
      }
      final oldValue = this.data;
      if (oldValue == null) return;
      final newValue = update(oldValue, next);
      if (newValue == null) return;
      state = AsyncData(newValue);
    }, fireImmediately: true, onError: (_, __) => error = exists);
    // 如果初始值加载失败则需要进行刷新
    assert(error != null);
    return error == true ? ref.refresh(provider) : ref.read(provider);
  }

  @protected
  Future<R> listenAsync<R>({
    required ProviderBase<AsyncValue<R>> provider,
    required T? Function(T state, R data) update,
  }) async {
    bool? error;
    final exists = ref.exists(provider);
    // 使用 select 过滤未发生变化的值
    ref.listen(provider.select((value) => value), (previous, next) {
      if (error == null) {
        error = exists && next is AsyncError;
        return;
      }
      next.whenOrNull(
        skipError: false,
        skipLoadingOnReload: false,
        skipLoadingOnRefresh: false,
        data: (data) {
          final oldValue = this.data;
          if (oldValue == null) return;
          final newValue = update(oldValue, data);
          if (newValue == null) return;
          state = AsyncData(newValue);
        },
      );
    }, fireImmediately: true);
    // 如果初始值加载失败则需要进行刷新
    assert(error != null);
    return error == true ? await ref.refresh(provider.future) : await ref.read(provider.future);
  }
}
