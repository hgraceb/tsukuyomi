import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseAnchorAddEdgeSingle extends StatefulWidget {
  const DebugListCaseAnchorAddEdgeSingle({super.key});

  @override
  State<DebugListCaseAnchorAddEdgeSingle> createState() => _DebugListCaseAnchorAddEdgeSingleState();
}

class _DebugListCaseAnchorAddEdgeSingleState extends State<DebugListCaseAnchorAddEdgeSingle> {
  int step = 0;
  final itemKeys = List.generate(10, (index) => index);
  final controller = TsukuyomiListController();

  Widget builder({required List<double> itemHeights}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        debugMask: true,
        trailing: false,
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
      body: Center(
        child: SizedBox(
          height: 600.0,
          child: builder(
            itemHeights: switch (step) {
              1 => List.generate(itemKeys.length, (index) => 100.0),
              2 => List.generate(itemKeys.length, (index) => 200.0),
              3 => List.generate(itemKeys.length, (index) => 100.0),
              4 => List.generate(itemKeys.length, (index) => 100.0),
              _ => List.generate(itemKeys.length, (index) => 100.0),
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final _ = switch (++step) {
            1 => controller.slideViewport(0.5),
            2 => null,
            3 => null,
            4 => await controller.slideViewport(-0.5),
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
