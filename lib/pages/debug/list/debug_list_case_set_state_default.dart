import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';

class DebugListCaseSetStateDefault extends StatefulWidget {
  const DebugListCaseSetStateDefault({super.key});

  @override
  State<DebugListCaseSetStateDefault> createState() => _DebugListCaseSetStateDefaultState();
}

class _DebugListCaseSetStateDefaultState extends State<DebugListCaseSetStateDefault> {
  final itemHeights = List.generate(10, (index) => 100.0);
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
              future: Future.delayed(const Duration(seconds: 2), () => this),
              builder: (context, snapshot) {
                if (snapshot.hasData && index == 1) {
                  return Card(
                    child: SizedBox(
                      height: itemHeights[index] * 1.5,
                      child: Center(child: Text('Item $index')),
                    ),
                  );
                }
                return Card(
                  child: SizedBox(
                    height: itemHeights[index],
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
            ),
          ),
        ),
      ),
    );
  }
}
