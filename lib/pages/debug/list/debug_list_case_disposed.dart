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
              itemBuilder: (context, index) => _TestWidget(
                key: LabeledGlobalKey('_TestWidget_$index'),
                index: index,
                child: FutureBuilder(
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
      ),
    );
  }
}

class _TestWidget extends StatefulWidget {
  const _TestWidget({super.key, required this.index, required this.child});

  final int index;

  final Widget child;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> {
  @override
  void initState() {
    super.initState();
    print('_TestWidgetState.initState: ${widget.index} ($hashCode)');
  }

  @override
  void dispose() {
    print('_TestWidgetState.dispose: ${widget.index} ($hashCode)');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
