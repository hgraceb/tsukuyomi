import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/pages/debug/scaffold/debug_scaffold_controller.dart';

class DebugScaffoldPage extends ConsumerStatefulWidget {
  const DebugScaffoldPage({super.key});

  @override
  ConsumerState<DebugScaffoldPage> createState() => _DebugScaffoldPageState();
}

class _DebugScaffoldPageState extends ConsumerState<DebugScaffoldPage> {
  int _appBarBuildCount = 0;
  int _bodyBuildCount = 0;

  Widget _buildItem(String leading, String trailing) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(leading, overflow: TextOverflow.ellipsis),
          ),
          ConstrainedBox(
            // 约束文本最大宽度
            constraints: constraints.copyWith(minWidth: 0),
            child: Text(trailing, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = debugScaffoldControllerProvider;
    final notifier = ref.read(provider.notifier);

    return Stack(children: [
      TsukuyomiAsyncScaffold(
        provider: provider,
        sliverAppBarBuilder: (builder) => TsukuyomiSliverAppBar(
          title: MediaQuery(
            // 移除移动端横屏时出现的边距
            data: const MediaQueryData(padding: EdgeInsets.zero),
            child: LayoutBuilder(
              builder: (context, constraints) => ListTile(
                // 移除默认的文本内容边距
                contentPadding: EdgeInsets.zero,
                // 继承应用栏的文本透明度
                textColor: DefaultTextStyle.of(context).style.color,
                title: const Text('Scaffold', overflow: TextOverflow.ellipsis),
                subtitle: _buildItem(
                  'AppBar build count: ',
                  '${++_appBarBuildCount}',
                ),
              ),
            ),
          ),
        ),
        sliversBody: (builder) => [
          SliverToBoxAdapter(
            child: ListTile(
              onTap: () {},
              title: _buildItem('Body build count: ', '${++_bodyBuildCount}'),
            ),
          ),
          builder(
            select: (state) => state.serviceCount,
            data: (value) => SliverToBoxAdapter(
              child: ListTile(
                onTap: () {},
                title: _buildItem('Service build count:', '$value'),
              ),
            ),
          ),
          builder(
            select: (state) => state.buildCount,
            data: (value) => SliverToBoxAdapter(
              child: ListTile(
                onTap: () {},
                title: _buildItem('Controller build count:', '$value'),
              ),
            ),
          ),
          builder(
            select: (state) => state.customCount,
            data: (value) => SliverToBoxAdapter(
              child: ListTile(
                onTap: () {},
                title: _buildItem('Controller custom count:', '$value'),
              ),
            ),
          ),
        ],
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
                onPressed: notifier.incrementCustomCount,
                child: const Icon(Icons.add),
              ),
            ),
            const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
            Flexible(
              child: FloatingActionButton(
                mini: true,
                heroTag: null,
                onPressed: notifier.decrementCustomCount,
                child: const Icon(Icons.remove_outlined),
              ),
            ),
            const Flexible(child: Padding(padding: EdgeInsets.only(top: 8.0))),
            Flexible(
              child: FloatingActionButton(
                mini: true,
                heroTag: null,
                onPressed: () => ref.refresh(provider),
                child: const Icon(Icons.refresh),
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
      ),
    ]);
  }
}
