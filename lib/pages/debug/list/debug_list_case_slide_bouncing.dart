// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseSlideBouncing extends StatefulWidget {
  const DebugListCaseSlideBouncing({super.key});

  @override
  State<DebugListCaseSlideBouncing> createState() => _DebugListCaseSlideBouncingState();
}

class _DebugListCaseSlideBouncingState extends State<DebugListCaseSlideBouncing> {
  int step = 0;
  final itemKeys = List.generate(10, (index) => index);
  final controller = TsukuyomiListController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      assert(controller.position.outOfRange == false);
    });
  }

  Future<void> next() async {
    final _ = switch (++step) {
      1 => controller.slideViewport(1.0),
      2 => controller.slideViewport(-1.0),
      _ => null,
    };
    setState(() {});
  }

  Widget builder() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        debugMask: true,
        itemKeys: itemKeys,
        itemBuilder: (context, index) => SizedBox(height: 100.0, child: Placeholder(child: Text('${itemKeys[index]}'))),
        controller: controller,
        initialScrollIndex: 3,
        physics: const BouncingScrollPhysics(),
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
        onPressed: next,
        shape: const CircleBorder(),
        child: Text('$step'),
      ),
    );
  }
}
