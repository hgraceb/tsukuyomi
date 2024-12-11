import 'dart:async';

import 'package:flutter/cupertino.dart';

typedef ThrottleWidgetBuilder = Widget Function(
  BuildContext context,
  Function(VoidCallback) throttle,
);

class ThrottleBuilder extends StatefulWidget {
  const ThrottleBuilder({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
  });

  final Duration duration;

  final ThrottleWidgetBuilder builder;

  @override
  State<ThrottleBuilder> createState() => _ThrottleBuilderState();
}

class _ThrottleBuilderState extends State<ThrottleBuilder> {
  Timer? _timer;

  void _throttle(VoidCallback callback) {
    if (_timer == null) {
      callback();
      _timer = Timer(widget.duration, () => _timer = null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _throttle);
}
