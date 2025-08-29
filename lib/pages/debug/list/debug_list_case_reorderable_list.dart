import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListCaseReorderableList extends StatefulWidget {
  const DebugListCaseReorderableList({super.key});

  @override
  State<DebugListCaseReorderableList> createState() => _DebugListCaseReorderableListState();
}

class _DebugListCaseReorderableListState extends State<DebugListCaseReorderableList> {
  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Row(
        children: [
          Expanded(
            child: _DefaultList(),
          ),
          Expanded(
            child: _TsukuyomiList(),
          ),
          Expanded(
            child: _ReorderableList(),
          ),
        ],
      ),
    );
  }
}

class _DefaultList extends StatefulWidget {
  @override
  State<_DefaultList> createState() => _DefaultListState();
}

class _DefaultListState extends State<_DefaultList> {
  double heightFactor = 2.0;
  final itemKeys = List.generate(20, (index) => index);
  final itemHeights = List.generate(20, (index) => 100.0);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemKeys.length,
      itemBuilder: (context, index) => KeyedSubtree(
        key: _ReorderableListViewChildGlobalKey(ValueKey(itemKeys[index]), this),
        child: FutureBuilder(
          key: ValueKey(itemKeys[index]),
          future: itemKeys[index] == 3 ? Future.delayed(const Duration(seconds: 1), () => itemHeights[index] * heightFactor) : null,
          builder: (context, snapshot) => GestureDetector(
            onTap: () {
              if (itemKeys[index] == 2 || itemKeys[index] == 3) {
                itemKeys.insert(3, itemKeys.removeAt(2));
              } else {
                final itemHeight = itemHeights.first == 100.0 ? 80.0 : 100.0;
                itemHeights.clear();
                itemHeights.addAll(List.generate(itemKeys.length, (index) => itemHeight));
              }
              setState(() {});
            },
            child: SizedBox(
              width: double.infinity,
              height: snapshot.data ?? itemHeights[index],
              child: Placeholder(
                child: Text('${itemKeys[index]} [${snapshot.data ?? itemHeights[index]}]'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TsukuyomiList extends StatefulWidget {
  @override
  State<_TsukuyomiList> createState() => _TsukuyomiListState();
}

class _TsukuyomiListState extends State<_TsukuyomiList> {
  double heightFactor = 2.0;
  final itemKeys = List.generate(20, (index) => index);
  final itemHeights = List.generate(20, (index) => 100.0);

  @override
  Widget build(BuildContext context) {
    return TsukuyomiList.builder(
      debugMask: true,
      trailing: false,
      anchor: 0.5,
      itemKeys: itemKeys,
      itemBuilder: (context, index) => KeyedSubtree(
        key: _ReorderableListViewChildGlobalKey(ValueKey(itemKeys[index]), this),
        child: FutureBuilder(
          key: ValueKey(itemKeys[index]),
          future: itemKeys[index] == 3 ? Future.delayed(const Duration(seconds: 1), () => itemHeights[index] * heightFactor) : null,
          builder: (context, snapshot) => GestureDetector(
            onTap: () {
              if (itemKeys[index] == 2 || itemKeys[index] == 3) {
                itemKeys.insert(3, itemKeys.removeAt(2));
              } else {
                final itemHeight = itemHeights.first == 100.0 ? 80.0 : 100.0;
                itemHeights.clear();
                itemHeights.addAll(List.generate(itemKeys.length, (index) => itemHeight));
              }
              setState(() {});
            },
            child: SizedBox(
              width: double.infinity,
              height: snapshot.data ?? itemHeights[index],
              child: Placeholder(
                child: Text('${itemKeys[index]} [${snapshot.data ?? itemHeights[index]}]'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReorderableList extends StatefulWidget {
  @override
  State<_ReorderableList> createState() => _ReorderableListState();
}

class _ReorderableListState extends State<_ReorderableList> {
  double heightFactor = 2.0;
  final itemKeys = List.generate(20, (index) => index);
  final itemHeights = List.generate(20, (index) => 100.0);

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      children: List.generate(
        10,
        (index) => FutureBuilder(
          key: ValueKey(itemKeys[index]),
          future: itemKeys[index] == 3 ? Future.delayed(const Duration(seconds: 1), () => itemHeights[index] * heightFactor) : null,
          builder: (context, snapshot) => GestureDetector(
            onTap: () {
              if (itemKeys[index] == 2 || itemKeys[index] == 3) {
                itemKeys.insert(3, itemKeys.removeAt(2));
              } else {
                final itemHeight = itemHeights.first == 100.0 ? 80.0 : 100.0;
                itemHeights.clear();
                itemHeights.addAll(List.generate(itemKeys.length, (index) => itemHeight));
              }
              setState(() {});
            },
            child: SizedBox(
              width: double.infinity,
              height: snapshot.data ?? itemHeights[index],
              child: Placeholder(
                child: Text('${itemKeys[index]} [${snapshot.data ?? itemHeights[index]}]'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReorderableListView extends StatefulWidget {
  ReorderableListView({
    super.key,
    required List<Widget> children,
  })  : itemBuilder = ((BuildContext context, int index) => children[index]),
        itemCount = children.length;

  final IndexedWidgetBuilder itemBuilder;

  final int itemCount;

  @override
  State<ReorderableListView> createState() => _ReorderableListViewState();
}

class _ReorderableListViewState extends State<ReorderableListView> {
  Widget _itemBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);
    assert(item.key != null);

    final Key itemGlobalKey = _ReorderableListViewChildGlobalKey(item.key!, this);

    return KeyedSubtree(
      key: itemGlobalKey,
      child: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            _itemBuilder,
            childCount: widget.itemCount,
          ),
        ),
      ],
    );
  }
}

@optionalTypeArgs
class _ReorderableListViewChildGlobalKey extends GlobalObjectKey {
  const _ReorderableListViewChildGlobalKey(this.subKey, this.state) : super(subKey);

  final Key subKey;
  final State state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableListViewChildGlobalKey && other.subKey == subKey && other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}
