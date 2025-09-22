// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseDecreaseExtent extends StatefulWidget {
  const DebugListCaseDecreaseExtent({super.key});

  @override
  State<DebugListCaseDecreaseExtent> createState() => _DebugListCaseDecreaseExtentState();
}

class _DebugListCaseDecreaseExtentState extends State<DebugListCaseDecreaseExtent> {
  double heightFactor = 2.0;
  final itemKeys = List.generate(20, (index) => index);
  final itemHeights = List.generate(20, (index) => 100.0);
  final controller = TsukuyomiListController();

  ScrollPosition get position {
    return controller.position;
  }

  void onScroll() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      position.addListener(onScroll);
      await Future.delayed(const Duration(seconds: 1));
      await controller.slideViewport(1.0);
      heightFactor = 1.0;
      await controller.slideViewport(-1.0, curve: Curves.linear, duration: const Duration(seconds: 10));
    });
  }

  @override
  void dispose() {
    position.removeListener(onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Center(
        child: SizedBox(
          height: 600.0,
          child: TsukuyomiList.builder(
            anchor: 0.5,
            debugMask: true,
            controller: controller,
            itemKeys: itemKeys,
            itemBuilder: (context, index) => FutureBuilder(
              future: index == 1 ? Future.delayed(const Duration(milliseconds: 200), () => itemHeights[index] * heightFactor) : null,
              builder: (context, snapshot) => SizedBox(
                height: snapshot.data ?? itemHeights[index],
                child: Placeholder(
                  child: Text('${itemKeys[index]} [${snapshot.data ?? itemHeights[index]}]'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
