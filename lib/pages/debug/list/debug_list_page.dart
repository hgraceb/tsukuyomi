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
  final _itemCount = 100;
  final _listController = TsukuyomiListController();
  late final List<double> _itemExtents;

  @override
  void initState() {
    super.initState();
    final heightGenerator = math.Random(2147483647);
    _itemExtents = List.generate(_itemCount, (index) {
      return 80.0 + heightGenerator.nextInt(120);
    });
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
              itemCount: _itemCount,
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
        if (snapshot.hasData) {
          return Card(
            child: SizedBox(
              width: snapshot.data!,
              height: snapshot.data!,
              child: Center(child: Text('Item $index')),
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
                  child: Text('Item $index'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FloatingActions extends StatelessWidget {
  const _FloatingActions({
    required this.onUp,
    required this.onDown,
    required this.onDoubleUp,
    required this.onDoubleDown,
    required this.onToggleCompare,
  });

  final VoidCallback onUp;

  final VoidCallback onDown;

  final VoidCallback onDoubleUp;

  final VoidCallback onDoubleDown;

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
