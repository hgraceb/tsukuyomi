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
  late final itemKeys = List.generate(2000, (index) => id++);
  late final itemHeights = List.generate(itemKeys.length, (index) => 100.0);
  late final controller = TsukuyomiListController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) => controller.slideViewport(-1.0));
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            const count = 100;
            itemKeys.removeRange(0, count);
            itemKeys.removeRange(itemKeys.length - count, itemKeys.length);
            itemHeights.removeRange(0, count);
            itemHeights.removeRange(itemHeights.length - count, itemHeights.length);
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
