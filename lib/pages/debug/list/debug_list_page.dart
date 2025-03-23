import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListPage extends StatefulWidget {
  const DebugListPage({super.key});

  @override
  State<DebugListPage> createState() => _DebugListPageState();
}

class _DebugListPageState extends State<DebugListPage> {
  bool _compare = false;
  int _itemKey = 0;
  int _itemCount = 100;
  final _random = math.Random(2147483647);
  final _listController = TsukuyomiListController();
  late final List<Object> _itemKeys;
  late final List<double> _itemExtents;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(_itemCount, (index) => _itemKey++);
    _itemExtents = List.generate(_itemCount, (index) => 80.0 + _random.nextInt(120));
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Row(children: [
        Offstage(
          offstage: !_compare,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width / 2,
            child: ListView.builder(
              itemCount: _itemCount,
              itemBuilder: (context, index) => _buildItem(index),
              scrollDirection: Axis.vertical,
            ),
          ),
        ),
        Flexible(
          child: Stack(children: [
            TsukuyomiInteractiveList.builder(
              itemKeys: _itemKeys,
              itemBuilder: (context, index) => _buildItem(index),
              controller: _listController,
              debugMask: true,
              initialScrollIndex: _itemCount - 1,
              scrollDirection: Axis.vertical,
            ),
            _FloatingActions(
              onUp: () => _listController.slideViewport(-0.75),
              onDown: () => _listController.slideViewport(0.75),
              onDoubleUp: () => _listController.jumpToIndex(0),
              onDoubleDown: () => _listController.jumpToIndex(_itemCount - 1),
              onAdd: _onAddItems,
              onRemove: _onRemoveItems,
              onToggleCompare: () => setState(() => _compare = !_compare),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildItem(int index) {
    return FutureBuilder(
      future: Future.delayed(
        Duration(milliseconds: 1000 + _itemExtents[index].toInt() * 5),
        () => _itemExtents[index].toDouble(),
      ),
      builder: (context, snapshot) {
        final itemKey = _itemKeys[index];
        if (snapshot.hasData) {
          return Card(
            child: SizedBox(
              width: snapshot.data!,
              height: snapshot.data!,
              child: Center(child: Text('Item $itemKey')),
            ),
          );
        }
        return Card(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const Flexible(
                  child: SizedBox(width: 10),
                ),
                Flexible(
                  flex: 10,
                  child: Text('Item $itemKey'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onAddItems() {
    for (var i = 0; i <= _random.nextInt(10); i++) {
      final position = _random.nextInt(_itemCount++);
      _itemKeys.insert(position, _itemKey++);
      _itemExtents.insert(position, 80.0 + _random.nextInt(120));
    }
    setState(() {});
  }

  void _onRemoveItems() {
    // TODO
  }
}

class _FloatingActions extends StatelessWidget {
  const _FloatingActions({
    required this.onUp,
    required this.onDown,
    required this.onDoubleUp,
    required this.onDoubleDown,
    required this.onAdd,
    required this.onRemove,
    required this.onToggleCompare,
  });

  final VoidCallback onUp;

  final VoidCallback onDown;

  final VoidCallback onDoubleUp;

  final VoidCallback onDoubleDown;

  final VoidCallback onAdd;

  final VoidCallback onRemove;

  final VoidCallback onToggleCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => onDoubleUp(),
              child: const Icon(Icons.keyboard_double_arrow_up),
            ),
          ),
          const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => onUp(),
              child: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
          const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => onDown(),
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
          const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => onDoubleDown(),
              child: const Icon(Icons.keyboard_double_arrow_down),
            ),
          ),
          const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => onAdd(),
              child: const Icon(Icons.add),
            ),
          ),
          const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => onRemove(),
              child: const Icon(Icons.remove),
            ),
          ),
          const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => onToggleCompare(),
              child: const Icon(Icons.compare),
            ),
          ),
          const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
          Flexible(
            child: FloatingActionButton(
              mini: true,
              heroTag: null,
              onPressed: () => context.canPop() ? context.pop() : null,
              child: const Icon(Icons.exit_to_app_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
