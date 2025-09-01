import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseAnchorHalf extends StatefulWidget {
  const DebugListCaseAnchorHalf({super.key});

  @override
  State<DebugListCaseAnchorHalf> createState() => _DebugListCaseAnchorHalfState();
}

class _DebugListCaseAnchorHalfState extends State<DebugListCaseAnchorHalf> {
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
        initialScrollIndex: 4,
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
              2 => List.generate(itemKeys.length, (index) => 150.0),
              3 => List.generate(itemKeys.length, (index) => 100.0),
              4 => List.generate(itemKeys.length, (index) => 100.0),
              5 => List.generate(itemKeys.length, (index) => 150.0),
              6 => List.generate(itemKeys.length, (index) => 100.0),
              7 => List.generate(itemKeys.length, (index) => 100.0),
              8 => List.generate(itemKeys.length, (index) => 150.0),
              9 => List.generate(itemKeys.length, (index) => 100.0),
              10 => List.generate(itemKeys.length, (index) => 100.0),
              11 => List.generate(itemKeys.length, (index) => 150.0),
              12 => List.generate(itemKeys.length, (index) => 100.0),
              _ => List.generate(itemKeys.length, (index) => 100.0),
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final _ = switch (++step) {
            1 => await controller.slideViewport(-1.0),
            2 => null,
            3 => null,
            4 => await controller.slideViewport(75 / 600),
            5 => null,
            6 => null,
            7 => await controller.slideViewport(250 / 600),
            8 => null,
            9 => null,
            10 => await controller.slideViewport(1.0),
            11 => null,
            12 => null,
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
