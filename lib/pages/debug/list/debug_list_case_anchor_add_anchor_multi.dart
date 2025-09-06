import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseAnchorAddAnchorMulti extends StatefulWidget {
  const DebugListCaseAnchorAddAnchorMulti({super.key});

  @override
  State<DebugListCaseAnchorAddAnchorMulti> createState() => _DebugListCaseAnchorAddAnchorMultiState();
}

class _DebugListCaseAnchorAddAnchorMultiState extends State<DebugListCaseAnchorAddAnchorMulti> {
  int step = 0;
  final random = Random(2147483647);
  final itemKeys = List.generate(10, (index) => index);
  final itemHeights = List.generate(10, (index) => 100.0);
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
        initialScrollIndex: 9,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void insertItem() {
      final anchorIndex = itemKeys.indexOf(5);
      itemKeys.insertAll(anchorIndex + 1, List.generate(100, (index) => itemKeys.length + index));
      itemHeights.insertAll(anchorIndex + 1, List.generate(100, (index) => 300.0 + random.nextInt(100)));
      itemKeys.insertAll(anchorIndex, List.generate(100, (index) => itemKeys.length + index));
      itemHeights.insertAll(anchorIndex, List.generate(100, (index) => 300.0 + random.nextInt(100)));
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
