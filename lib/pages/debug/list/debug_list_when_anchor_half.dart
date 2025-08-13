import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_list/tsukuyomi_list.dart';

class DebugListWhenAnchorHalf extends StatefulWidget {
  const DebugListWhenAnchorHalf({super.key});

  @override
  State<DebugListWhenAnchorHalf> createState() => _DebugListWhenAnchorHalfState();
}

class _DebugListWhenAnchorHalfState extends State<DebugListWhenAnchorHalf> {
  final itemKeys = List.generate(10, (index) => index);
  final controller = TsukuyomiListController();

  Widget builder({required List<double> itemHeights}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TsukuyomiList.builder(
        itemKeys: itemKeys,
        itemBuilder: (context, index) => SizedBox(height: itemHeights[index], child: Placeholder(child: Text('${itemKeys[index]}'))),
        controller: controller,
        anchor: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            // for (int i = 0; i < 8; i++) {
            //   final position = itemKeys.indexOf(16);
            //   itemKeys.insert(position - 1, id++);
            //   itemHeights.insert(position - 1, 60.0 + random.nextInt(100));
            //   itemKeys.removeRange(position, position + 1);
            //   itemHeights.removeRange(position, position + 1);
            //   itemKeys.insert(position, id++);
            //   itemHeights.insert(position, 60.0 + random.nextInt(100));
            // }
            // print('itemKeys: ${itemKeys.length}, itemHeights: ${itemHeights.length}');
          });
        },
        child: Center(
          child: SizedBox(
            height: 600.0,
            child: builder(itemHeights: List.generate(itemKeys.length, (index) => 100.0)),
          ),
        ),
      ),
    );
  }
}
