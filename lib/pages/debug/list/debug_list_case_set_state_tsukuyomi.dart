import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseSetStateTsukuyomi extends StatefulWidget {
  const DebugListCaseSetStateTsukuyomi({super.key});

  @override
  State<DebugListCaseSetStateTsukuyomi> createState() => _DebugListCaseSetStateTsukuyomiState();
}

class _DebugListCaseSetStateTsukuyomiState extends State<DebugListCaseSetStateTsukuyomi> {
  int step = 0;
  final itemKeys = List.generate(20, (index) => index);
  final itemHeights = List.generate(20, (index) => 100.0);
  final controller = TsukuyomiListController();

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Center(
        child: SizedBox(
          height: 600.0,
          child: TsukuyomiList.builder(
            controller: controller,
            itemKeys: itemKeys,
            itemBuilder: (context, index) => FutureBuilder(
              future: index == 0 ? Future.delayed(const Duration(seconds: 1), () => itemHeights[index] * (step == 2 ? 1.0 : 2.0)) : null,
              builder: (context, snapshot) => SizedBox(
                height: snapshot.data ?? itemHeights[index],
                child: Placeholder(child: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final _ = switch (++step) {
            1 => await controller.slideViewport(1.0, duration: const Duration(seconds: 5)),
            2 => await controller.slideViewport(-5 / 6, duration: const Duration(seconds: 5)),
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
