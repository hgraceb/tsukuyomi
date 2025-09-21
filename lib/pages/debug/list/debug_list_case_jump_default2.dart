// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseJumpDefault2 extends StatefulWidget {
  const DebugListCaseJumpDefault2({super.key});

  @override
  State<DebugListCaseJumpDefault2> createState() => _DebugListCaseJumpDefault2State();
}

class _DebugListCaseJumpDefault2State extends State<DebugListCaseJumpDefault2> {
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
        anchor: 2 / 6,
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
          if (step == 1) {
            SchedulerBinding.instance.addPostFrameCallback((timeStamp) => controller.position.jumpTo(controller.position.pixels - 100.0));
          }
          final _ = switch (++step) {
            1 => controller.jumpToIndex(5),
            2 => controller.jumpToIndex(9),
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
