import 'package:flutter/material.dart';

/// TODO 优化组件
class ErrorImageWidget extends StatelessWidget {
  const ErrorImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image),
    );
  }
}
