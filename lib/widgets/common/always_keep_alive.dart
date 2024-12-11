import 'package:flutter/widgets.dart';

class AlwaysKeepAlive extends StatefulWidget {
  const AlwaysKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<AlwaysKeepAlive> createState() => _AlwaysKeepAliveState();
}

class _AlwaysKeepAliveState extends State<AlwaysKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
