import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseAnchorRemoveAnchorSingle extends StatefulWidget {
  const DebugListCaseAnchorRemoveAnchorSingle({super.key});

  @override
  State<DebugListCaseAnchorRemoveAnchorSingle> createState() => _DebugListCaseAnchorRemoveAnchorSingleState();
}

class _DebugListCaseAnchorRemoveAnchorSingleState extends State<DebugListCaseAnchorRemoveAnchorSingle> {
  int step = 0;
  final random = Random(2147483647);
  final itemKeys = List.generate(20, (index) => index);
  late final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + (7 <= index && index <= 18 ? 0.0 : random.nextInt(100)));
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
        initialScrollIndex: (itemKeys.length - 1).clamp(0, 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void insertItem() {
      itemKeys.removeAt(0);
      itemKeys.removeAt(itemKeys.length - 1);
      itemHeights.removeAt(0);
      itemHeights.removeAt(itemHeights.length - 1);
    }

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
            1 => await controller.slideViewport(-1.0),
            2 => insertItem(),
            3 => insertItem(),
            4 => insertItem(),
            5 => insertItem(),
            6 => insertItem(),
            7 => insertItem(),
            8 => insertItem(),
            9 => insertItem(),
            10 => insertItem(),
            11 => insertItem(),
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
