import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';

class DebugListCaseSetStateDefault extends StatefulWidget {
  const DebugListCaseSetStateDefault({super.key});

  @override
  State<DebugListCaseSetStateDefault> createState() => _DebugListCaseSetStateDefaultState();
}

class _DebugListCaseSetStateDefaultState extends State<DebugListCaseSetStateDefault> {
  int step = 0;
  final itemHeights = List.generate(20, (index) => 100.0);
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
              future: index == 1 ? Future.delayed(const Duration(seconds: 1), () => itemHeights[index] * (step == 2 ? 1.0 : 2.0)) : null,
              builder: (context, snapshot) => SizedBox(
                height: snapshot.data ?? itemHeights[index],
                child: Placeholder(child: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final _ = switch (++step) {
            1 => await scrollController.animateTo(600.0, duration: const Duration(milliseconds: 5000), curve: Curves.linear),
            2 => await scrollController.animateTo(0.0, duration: const Duration(milliseconds: 5000), curve: Curves.linear),
            _ => --step,
          };
          setState(() {});
        },
        shape: const CircleBorder(),
        child: Text('$step'),
      ),
    );
  }
}
