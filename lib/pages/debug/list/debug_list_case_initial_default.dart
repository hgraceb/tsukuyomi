import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseInitialDefault extends StatefulWidget {
  const DebugListCaseInitialDefault({super.key});

  @override
  State<DebugListCaseInitialDefault> createState() => _DebugListCaseInitialDefaultState();
}

class _DebugListCaseInitialDefaultState extends State<DebugListCaseInitialDefault> {
  int step = 0;
  final itemKeys = List.generate(10, (index) => index);
  final controller = TsukuyomiListController();

  Widget builder(index) {
    return Directionality(
      key: ValueKey(index),
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        debugMask: true,
        itemKeys: itemKeys,
        itemBuilder: (context, index) => SizedBox(height: 100.0, child: Placeholder(child: Text('${itemKeys[index]}'))),
        controller: controller,
        initialScrollIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Center(
        child: SizedBox(
          height: 600.0,
          child: builder(step),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final _ = switch (++step) {
            1 => null,
            2 => null,
            3 => null,
            4 => null,
            5 => null,
            6 => null,
            7 => null,
            8 => null,
            9 => null,
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
