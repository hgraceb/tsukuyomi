import 'package:flutter/material.dart' hide Image, Key;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

class DebugInterpreterPage extends ConsumerStatefulWidget {
  const DebugInterpreterPage({super.key});

  @override
  ConsumerState<DebugInterpreterPage> createState() => _DebugInterpreterPageState();
}

class _DebugInterpreterPageState extends ConsumerState<DebugInterpreterPage> {
  void _eval() async {
    final string = await rootBundle.loadString(Assets.interpreterExample);
    await eval(string, libraries: evalLibraries, debug: true);
  }

  @override
  void reassemble() {
    super.reassemble();
    _eval();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      TsukuyomiScaffold(
        body: CustomScrollView(slivers: [
          SliverStack(children: const [
            TsukuyomiSliverAppBar(
              title: Text('Interpreter'),
            ),
            TsukuyomiSliverLeadingAppBar(),
          ]),
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(8.0),
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
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
      ),
    ]);
  }
}
