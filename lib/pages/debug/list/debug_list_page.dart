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
  late final itemKeys = List.generate(10, (index) => index);
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
            itemKeys.insert(itemKeys.length - 5, itemKeys.length);
            itemHeights.insert(itemHeights.length - 5, 300);
          });
        },
        child: Center(
          child: SizedBox(
            height: 600.0,
            child: TsukuyomiList.builder(
              itemKeys: itemKeys,
              itemBuilder: (context, index) => Placeholder(child: SizedBox(height: itemHeights[index], child: Text('${itemKeys[index]}'))),
              controller: controller,
              debugMask: true,
              anchor: 0.5,
              initialScrollIndex: 9,
            ),
          ),
        ),
      ),
    );
  }
}
