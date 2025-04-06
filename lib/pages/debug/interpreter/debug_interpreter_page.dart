import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';

class DebugInterpreterPage extends StatefulWidget {
  const DebugInterpreterPage({super.key});

  @override
  State<DebugInterpreterPage> createState() => _DebugInterpreterPageState();
}

class _DebugInterpreterPageState extends State<DebugInterpreterPage> {
  int _centerIndex = 10;
  final _centerKey = UniqueKey();

  int _itemKey = 0;
  int _itemCount = 10000;
  final _random = math.Random(2147483647);
  late final List<Object> _itemKeys;
  late final List<double> _itemExtents;
  final _scrollController = ScrollController(initialScrollOffset: 100000);

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(_itemCount, (index) => _itemKey++);
    _itemExtents = List.generate(_itemCount, (index) => 80.0 + _random.nextInt(120) ?? 92.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Stack(
        children: [
          CustomScrollView(
            center: _centerKey,
            controller: _scrollController,
            slivers: [
              SliverList.builder(
                itemCount: _centerIndex > 0 ? _centerIndex : 0,
                itemBuilder: (context, index) => _buildItem(_centerIndex - index - 1),
              ),
              SliverList.builder(
                key: _centerKey,
                itemCount: _itemKeys.length - _centerIndex,
                itemBuilder: (context, index) => _buildItem(_centerIndex + index),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        heroTag: null,
        onPressed: () => _onAddItems(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItem(int index) {
    print('_buildItem: index = $index, _itemKeys[index] = ${_itemKeys[index]}');
    return Card(
      key: ValueKey(_itemKeys[index]),
      child: SizedBox(
        width: _itemExtents[index].toDouble(),
        height: _itemExtents[index].toDouble(),
        child: Center(child: Text('Item ${_itemKeys[index]}')),
      ),
    );
  }

  void _onAddItems() {
    final position = 11;
    double offset = 80.0 + _random.nextInt(120) ?? 92.0;
    if(_itemKey == 22) offset+=5.0;
    print('_itemKey = $_itemKey, offset = $offset');
    _itemCount++;
    _itemKeys.insert(position, _itemKey++);
    _itemExtents.insert(position, offset);
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1000), () {
      final to = _itemKey == 24 ? _scrollController.offset + 96.0 + 5.0 + 8.0 : _scrollController.offset + offset + 8.0;
      _scrollController.animateTo(to, duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
    });
  }
}
