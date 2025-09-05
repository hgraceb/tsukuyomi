// ignore_for_file: invalid_use_of_visible_for_testing_member

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
  final itemKeys = List.generate(20, (index) => index);
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
        initialScrollIndex: (itemKeys.length - 1).clamp(0, 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void next() {
      itemKeys.removeAt(controller.anchorIndex);
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
            2 => next(),
            3 => next(),
            4 => next(),
            5 => next(),
            6 => next(),
            7 => next(),
            8 => next(),
            9 => next(),
            10 => next(),
            11 => next(),
            12 => next(),
            13 => next(),
            14 => next(),
            15 => next(),
            16 => next(),
            17 => next(),
            18 => next(),
            19 => next(),
            20 => next(),
            21 => next(),
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
