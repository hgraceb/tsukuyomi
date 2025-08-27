// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseDisposed extends StatefulWidget {
  const DebugListCaseDisposed({super.key});

  @override
  State<DebugListCaseDisposed> createState() => _DebugListCaseDisposedState();
}

class _DebugListCaseDisposedState extends State<DebugListCaseDisposed> {
  double heightFactor = 2.0;
  final itemKeys = List.generate(20, (index) => index);
  final itemHeights = List.generate(20, (index) => 100.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          itemHeights.clear();
          itemHeights.addAll(List.generate(itemKeys.length, (index) => 150.0));
        });
      },
      child: TsukuyomiScaffold(
        body: Center(
          child: SizedBox(
            height: 600.0,
            child: TsukuyomiList.builder(
              anchor: 0.5,
              debugMask: true,
              trailing: false,
              itemKeys: itemKeys,
              itemBuilder: (context, index) => FutureBuilder(
                future: index == 4 ? Future.delayed(const Duration(milliseconds: 200), () => itemHeights[index] * heightFactor) : null,
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
      ),
    );
  }
}
