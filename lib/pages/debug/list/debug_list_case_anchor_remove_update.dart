// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseAnchorRemoveUpdate extends StatefulWidget {
  const DebugListCaseAnchorRemoveUpdate({super.key});

  @override
  State<DebugListCaseAnchorRemoveUpdate> createState() => _DebugListCaseAnchorRemoveUpdateState();
}

class _DebugListCaseAnchorRemoveUpdateState extends State<DebugListCaseAnchorRemoveUpdate> {
  int step = 0;
  final itemKeys = List.generate(30, (index) => index);
  final controller = TsukuyomiListController();

  Widget builder() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        debugMask: true,
        itemKeys: itemKeys,
        itemBuilder: (context, index) => SizedBox(height: 100.0, child: Placeholder(child: Text('${itemKeys[index]}'))),
        controller: controller,
        initialScrollIndex: 10,
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
        onPressed: () {
          final _ = switch (++step) {
            1 => itemKeys.removeAt(controller.anchorIndex),
            2 => itemKeys.insert(0, itemKeys.last + 1),
            3 => itemKeys.removeAt(controller.anchorIndex),
            4 => itemKeys.insert(0, itemKeys.removeLast()),
            _ => --step,
          };
          setState(() {});
        },
        child: Text('$step'),
      ),
    );
  }
}
