import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/providers/providers.dart';

part 'error_handler_provider.g.dart';

class ErrorHandler {
  ErrorHandler._({required this.ref});

  final ErrorHandlerRef ref;

  void show(Object error, [StackTrace? stackTrace]) {
    // TODO 优化错误处理
    debugPrint(error.toString());
    debugPrintStack(stackTrace: stackTrace);
    final snackBar = SnackBar(content: Text(error.toString()));
    ref.read(messengerProvider).showSnackBar(snackBar);
  }

  void print(Object error, [StackTrace? stackTrace]) {
    // TODO 优化错误处理
    debugPrint(error.toString());
    debugPrintStack(stackTrace: stackTrace);
  }
}

@Riverpod(keepAlive: true)
ErrorHandler errorHandler(ErrorHandlerRef ref) {
  return ErrorHandler._(ref: ref);
}
