import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';

export 'interpreter/debug_interpreter_page.dart';
export 'list/debug_list_page.dart';
export 'scaffold/debug_scaffold_page.dart';

/// 代码调试页面
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final _pageConfigs = <_PageConfig>[
    _PageConfig(title: 'List', router: TsukuyomiRouter.debugList),
    _PageConfig(title: 'Scaffold', router: TsukuyomiRouter.debugScaffold),
  ];

  Widget _buildItem(int index, _PageConfig config) {
    return ListTile(
      onTap: () => context.pushNamed(config.router.name),
      title: Text('${(index + 1).toString().padLeft(2, '0')}. ${config.title}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;

    return TsukuyomiScaffold(
      body: CustomScrollView(slivers: [
        SliverStack(children: [
          TsukuyomiSliverAppBar(
            title: Text(l10n.debugTitle),
          ),
          const TsukuyomiSliverLeadingAppBar(),
        ]),
        SliverList.builder(
          itemCount: _pageConfigs.length,
          itemBuilder: (context, index) {
            return _buildItem(index, _pageConfigs[index]);
          },
        ),
      ]),
    );
  }
}

class _PageConfig {
  const _PageConfig({required this.title, required this.router});

  final String title;

  final TsukuyomiRouter router;
}
