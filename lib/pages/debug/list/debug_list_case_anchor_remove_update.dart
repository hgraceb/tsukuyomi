// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseAnchorRemoveUpdate extends StatefulWidget {
  const DebugListCaseAnchorRemoveUpdate({super.key});

  @override
  State<DebugListCaseAnchorRemoveUpdate> createState() => _DebugListCaseAnchorRemoveUpdateState();
}

class _DebugListCaseAnchorRemoveUpdateState extends State<DebugListCaseAnchorRemoveUpdate> {
  static const itemCount = 30;
  static const itemHeight = 100.0;
  static const initialScrollIndex = 10;

  int step = 0;
  int anchorKey = initialScrollIndex;
  Key listKey = UniqueKey();
  final itemKeys = List.generate(itemCount, (index) => index);
  final controller = TsukuyomiListController();

  Widget builder() {
    return TsukuyomiList.builder(
      key: listKey,
      debugMask: true,
      itemKeys: itemKeys,
      itemBuilder: (context, index) => SizedBox(
        height: itemHeight,
        child: ColoredBox(
          color: itemKeys[index] == anchorKey ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
          child: Placeholder(child: Text('key ${itemKeys[index]} · index $index')),
        ),
      ),
      controller: controller,
      initialScrollIndex: initialScrollIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    void removeAnchor() {
      final anchorIndex = controller.anchorIndex;
      itemKeys.removeAt(anchorIndex);
      anchorKey = itemKeys[anchorIndex.clamp(0, itemKeys.length - 1)];
    }

    void reset() {
      setState(() {
        step = 0;
        anchorKey = initialScrollIndex;
        listKey = UniqueKey();
        itemKeys.clear();
        itemKeys.addAll(List.generate(itemCount, (index) => index));
      });
    }

    void next() {
      setState(() {
        final _ = switch (++step) {
          1 => removeAnchor(),
          2 => itemKeys.insert(0, itemCount),
          3 => removeAnchor(),
          4 => itemKeys.insert(0, itemKeys.removeLast()),
          _ => null,
        };
      });
    }

    final description = switch (step) {
      0 => '初始列表',
      1 => '已删除当前锚点',
      2 => '已在头部添加一项',
      3 => '已再次删除当前锚点',
      _ => '已将末项移到头部',
    };
    final action = switch (step) {
      0 => '删除当前锚点',
      1 => '向头部添加一项',
      2 => '再次删除当前锚点',
      3 => '将末项移到头部',
      _ => '已完成',
    };

    return TsukuyomiScaffold(
      appBar: AppBar(
        title: const Text('删除锚点后更新列表'),
        actions: [
          IconButton(onPressed: reset, tooltip: '重置', icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('第 $step / 4 步：$description\n观察着色的 key $anchorKey，头插和重排后应保持原来的屏幕位置'),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 600.0,
                  child: builder(),
                ),
              ),
            ),
            const SizedBox(height: 80.0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: step < 4 ? next : null,
        icon: const Icon(Icons.arrow_forward),
        label: Text(action),
      ),
    );
  }
}
