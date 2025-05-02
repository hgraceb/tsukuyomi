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
  late final itemKeys = List.generate(20, (index) => id++);
  late final itemHeights = List.generate(itemKeys.length, (index) => 100.0 + random.nextInt(100));
  late final controller = TsukuyomiListController();

  @override
  void initState() {
    super.initState();
    itemHeights[15] = 600 - itemHeights[16] - itemHeights[17] - itemHeights[18];
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) => controller.slideViewport(-1.0));
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            itemKeys.removeRange(0, 5);
            itemHeights.removeRange(0, 5);
          });
        },
        child: Center(
          child: SizedBox(
            height: 600.0,
            child: TsukuyomiList.builder(
              debugMask: true,
              anchor: 0.5,
              initialScrollIndex: (itemKeys.length - 1).clamp(0, 19),
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
