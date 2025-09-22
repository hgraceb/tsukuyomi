import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseJumpEnd extends StatefulWidget {
  const DebugListCaseJumpEnd({super.key});

  @override
  State<DebugListCaseJumpEnd> createState() => _DebugListCaseJumpEndState();
}

class _DebugListCaseJumpEndState extends State<DebugListCaseJumpEnd> {
  int step = 0;
  final itemKeys = List.generate(10, (index) => index);
  final controller = TsukuyomiListController();

  Widget builder() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        debugMask: true,
        itemKeys: itemKeys,
        itemBuilder: (context, index) => SizedBox(height: 100.0, child: Placeholder(child: Text('${itemKeys[index]}'))),
        controller: controller,
        anchor: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Center(
        child: SizedBox(
          height: 600.0,
          child: builder(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final _ = switch (++step) {
            1 => controller.jumpToIndex(1),
            2 => controller.jumpToIndex(2),
            3 => controller.jumpToIndex(3),
            4 => controller.jumpToIndex(4),
            5 => controller.jumpToIndex(5),
            6 => controller.jumpToIndex(6),
            7 => controller.jumpToIndex(7),
            8 => controller.jumpToIndex(8),
            9 => controller.jumpToIndex(9),
            _ => --step,
          };
          setState(() {});
        },
        shape: const CircleBorder(),
        child: Text('$step'),
      ),
    );
  }
}
