import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseJumpRemove extends StatefulWidget {
  const DebugListCaseJumpRemove({super.key});

  @override
  State<DebugListCaseJumpRemove> createState() => _DebugListCaseJumpRemoveState();
}

class _DebugListCaseJumpRemoveState extends State<DebugListCaseJumpRemove> {
  int step = 0;
  final random = Random(2147483647);
  final itemKeys = List.generate(20, (index) => index);
  late final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + (4 <= index && index <= 15 ? 0.0 : random.nextInt(100)));
  final controller = TsukuyomiListController();

  Widget builder() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        debugMask: true,
        itemKeys: itemKeys,
        itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Placeholder(child: Text('${itemKeys[index]}'))),
        controller: controller,
        anchor: 0.5,
        initialScrollIndex: (itemKeys.length - 1).clamp(0, 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void removeEdge() {
      itemKeys.removeAt(0);
      itemKeys.removeAt(itemKeys.length - 1);
      itemHeights.removeAt(0);
      itemHeights.removeAt(itemHeights.length - 1);
    }

    Future<void> next() async {
      final _ = switch (++step) {
        1 => await controller.slideViewport(-1.0),
        2 => removeEdge(),
        3 => removeEdge(),
        4 => removeEdge(),
        5 => removeEdge(),
        6 => await controller.slideViewport(1.0),
        _ => --step,
      };
      setState(() {});
    }

    return TsukuyomiScaffold(
      body: Center(
        child: SizedBox(
          height: 600.0,
          child: builder(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: next,
        shape: const CircleBorder(),
        child: Text('$step'),
      ),
    );
  }
}
