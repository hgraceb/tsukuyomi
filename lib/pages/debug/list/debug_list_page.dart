import 'package:flutter/material.dart';

import 'debug_list_when_anchor_half.dart';

class DebugListPage extends StatelessWidget {
  const DebugListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DebugListWhenAnchorHalf();
  }
}

// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:tsukuyomi/core/core.dart';
// import 'package:tsukuyomi_list/tsukuyomi_list.dart';
//
// class DebugListPage extends StatefulWidget {
//   const DebugListPage({super.key});
//
//   @override
//   State<DebugListPage> createState() => _DebugListPageState();
// }
//
// class _DebugListPageState extends State<DebugListPage> {
//   int id = 0;
//   final random = Random(2147483647);
//   late final itemKeys = List.generate(20, (index) => id++);
//   late final itemHeights = List.generate(itemKeys.length, (index) => 60.0 + random.nextInt(100));
//   late final controller = TsukuyomiListController();
//
//   @override
//   void initState() {
//     super.initState();
//     SchedulerBinding.instance.addPostFrameCallback((timeStamp)async {
//       await controller.slideViewport(-1.0);
//       await controller.slideViewport(-0.5);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return TsukuyomiScaffold(
//       body: GestureDetector(
//         onTap: () {
//           setState(() {
//             for (int i = 0; i < 8; i++) {
//               final position = itemKeys.indexOf(16);
//               itemKeys.insert(position - 1, id++);
//               itemHeights.insert(position - 1, 60.0 + random.nextInt(100));
//               itemKeys.removeRange(position, position + 1);
//               itemHeights.removeRange(position, position + 1);
//               itemKeys.insert(position, id++);
//               itemHeights.insert(position, 60.0 + random.nextInt(100));
//             }
//             print('itemKeys: ${itemKeys.length}, itemHeights: ${itemHeights.length}');
//           });
//         },
//         child: Center(
//           child: SizedBox(
//             height: 600.0,
//             child: TsukuyomiList.builder(
//               debugMask: true,
//               anchor: 0.5,
//               initialScrollIndex: (itemKeys.length - 1).clamp(0, 19),
//               controller: controller,
//               itemKeys: itemKeys,
//               itemBuilder: (context, index) => SizedBox(
//                 height: itemHeights[index],
//                 child: Placeholder(child: Text('${itemKeys[index]} [$index]: ${itemHeights[index]}')),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
