import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseSlideDefault extends StatefulWidget {
  const DebugListCaseSlideDefault({super.key});

  @override
  State<DebugListCaseSlideDefault> createState() => _DebugListCaseSlideDefaultState();
}

class _DebugListCaseSlideDefaultState extends State<DebugListCaseSlideDefault> {
  int step = 0;
  final itemKeys = List.generate(20, (index) => index);
  final controller = TsukuyomiListController();

  Future<void> next() async {
    final _ = switch (++step) {
      1 => await controller.slideViewport(0.0),
      2 => await controller.slideViewport(0.5),
      3 => await controller.slideViewport(1.0),
      4 => await controller.slideViewport(1.0),
      5 => await controller.slideViewport(-1.0),
      6 => await controller.slideViewport(-0.5),
      7 => await controller.slideViewport(-1.0),
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
