import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';

class DebugListCaseSetStateDefault extends StatefulWidget {
  const DebugListCaseSetStateDefault({super.key});

  @override
  State<DebugListCaseSetStateDefault> createState() => _DebugListCaseSetStateDefaultState();
}

class _DebugListCaseSetStateDefaultState extends State<DebugListCaseSetStateDefault> {
  final itemHeights = List.generate(10, (index) => 120.0);
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: Center(
        child: SizedBox(
          height: 600.0,
          child: ListView.builder(
            controller: scrollController,
            itemCount: itemHeights.length,
            itemBuilder: (context, index) => FutureBuilder(
              future: index == 1 ? Future.delayed(const Duration(seconds: 1), () => itemHeights[index] * 2) : null,
              builder: (context, snapshot) => SizedBox(
                height: snapshot.data ?? itemHeights[index],
                child: Placeholder(child: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
