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

  Widget builder({required List<double> itemHeights}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        debugMask: true,
        itemKeys: itemKeys,
        itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Placeholder(child: Text('${itemKeys[index]}'))),
        controller: controller,
        anchor: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: GestureDetector(
        onTap: () async {
          if (step == 0) {
            await controller.slideViewport(0.5);
            setState(() => step++);
          } else {
            setState(() {});
          }
        },
        child: Center(
          child: SizedBox(
            height: 600.0,
            child: builder(
              itemHeights: switch (step) {
                0 => List.generate(itemKeys.length, (index) => 100.0),
                1 => List.generate(itemKeys.length, (index) => 200.0),
                _ => throw AssertionError(step),
              },
            ),
          ),
        ),
      ),
    );
  }
}
