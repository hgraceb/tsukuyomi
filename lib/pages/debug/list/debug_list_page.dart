import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListPage extends StatefulWidget {
  const DebugListPage({super.key});

  @override
  State<DebugListPage> createState() => _DebugListPageState();
}

class _DebugListPageState extends State<DebugListPage> {
  int id = 0;
  final random = Random(2147483647);
  late final itemKeys = List.generate(2000, (index) => id++);
  late final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + (997 <= index && index <= 1008 ? 0.0 : random.nextInt(100)));
  late final controller = TsukuyomiListController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      await controller.slideViewport(-1.0);
      await controller.slideViewport(-0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            final adding = random.nextInt(100);
            final removing = random.nextInt(100);
            itemKeys.removeRange(0, removing);
            itemHeights.removeRange(0, removing);
            itemKeys.insertAll(adding, List.generate(adding, (index) => id));
            itemHeights.insertAll(adding, List.generate(adding, (index) => 100.0 + random.nextInt(100)));
          });
        },
        child: Center(
          child: SizedBox(
            height: 600.0,
            child: TsukuyomiList.builder(
              debugMask: true,
              anchor: 0.5,
              initialScrollIndex: (itemKeys.length - 1).clamp(0, 1003),
              controller: controller,
              itemKeys: itemKeys,
              itemBuilder: (context, index) => SizedBox(
                height: itemHeights[index],
                child: Placeholder(child: Text('${itemKeys[index]} [$index]')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
