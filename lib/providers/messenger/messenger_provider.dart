import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/providers/providers.dart';

part 'messenger_provider.g.dart';

class Messenger {
  Messenger._({required this.ref});

  final MessengerRef ref;

  void showSnackBar(SnackBar snackBar) {
    final context = ref.read(routerNavigatorKeyProvider).currentContext;
    assert(context != null && context.mounted);
    if (context == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    assert(messenger != null && messenger.mounted);
    if (messenger == null) return;

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      messenger.showSnackBar(snackBar);
    });
  }
}

@Riverpod(keepAlive: true)
Messenger messenger(MessengerRef ref) {
  return Messenger._(ref: ref);
}
