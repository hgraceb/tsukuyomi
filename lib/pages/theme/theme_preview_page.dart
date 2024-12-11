import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/providers/providers.dart';

/// 主题预览页面
class ThemePreviewPage extends ConsumerStatefulWidget {
  const ThemePreviewPage({super.key});

  @override
  ConsumerState createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends ConsumerState<ThemePreviewPage> {
  @override
  void reassemble() {
    super.reassemble();
    ref.invalidate(themePredefinedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;

    return TsukuyomiScaffold(
      body: CustomScrollView(
        slivers: [
          SliverStack(children: [
            TsukuyomiSliverAppBar(
              title: Text(l10n.themePreviewTitle),
            ),
            const TsukuyomiSliverLeadingAppBar(),
          ]),
          const _SliverComponentDecoration(
            child: _ButtonStyleButton(),
          ),
          const _SliverComponentDecoration(
            child: _SegmentedButton(),
          ),
        ],
      ),
      bottomNavigationBar: _NavigationBar(),
    );
  }
}

class _NavigationBar extends StatefulWidget {
  @override
  State<_NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<_NavigationBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (value) => setState(() => _selectedIndex = value),
      destinations: [
        const NavigationDestination(
          tooltip: '',
          label: 'Chat',
          icon: Badge(child: Icon(Icons.chat_bubble_outlined)),
          selectedIcon: Badge(child: Icon(Icons.chat_bubble)),
        ),
        NavigationDestination(
          tooltip: '',
          label: 'Mail',
          icon: Badge.count(
            count: 99,
            child: const Icon(Icons.mail_outlined),
          ),
          selectedIcon: Badge.count(
            count: 99,
            child: const Icon(Icons.mail_rounded),
          ),
        ),
        NavigationDestination(
          tooltip: '',
          label: 'Group',
          icon: Badge.count(
            count: 9999,
            child: const Icon(Icons.group_outlined),
          ),
          selectedIcon: Badge.count(
            count: 9999,
            child: const Icon(Icons.group_rounded),
          ),
        ),
      ],
    );
  }
}

class _SliverComponentDecoration extends StatelessWidget {
  const _SliverComponentDecoration({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: const BoxConstraints.tightFor(width: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonStyleButton extends StatelessWidget {
  const _ButtonStyleButton();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints.tightFor(width: 120),
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => {},
                  child: const Text('Filled'),
                ),
                const SizedBox(height: 10.0),
                FilledButton.tonal(
                  onPressed: () => {},
                  child: const Text('Filled'),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: Container(
            constraints: const BoxConstraints.tightFor(width: 120),
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => {},
                  child: const Text('Elevated'),
                ),
                const SizedBox(height: 10.0),
                const ElevatedButton(
                  onPressed: null,
                  child: Text('Elevated'),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: Container(
            constraints: const BoxConstraints.tightFor(width: 120),
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () => {},
                  child: const Text('Outlined'),
                ),
                const SizedBox(height: 10.0),
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Outlined'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentedButton extends StatefulWidget {
  const _SegmentedButton();

  @override
  State<_SegmentedButton> createState() => _SegmentedButtonState();
}

class _SegmentedButtonState extends State<_SegmentedButton> {
  Set<IconData> _selected = {Icons.elderly};

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSelectedIcon = width > 250;
    final showLabel = width > 350;

    return SegmentedButton(
      showSelectedIcon: showSelectedIcon,
      segments: [
        ButtonSegment(
          value: Icons.elderly,
          label: showLabel ? const Text('cane') : null,
          icon: const Icon(Icons.elderly),
        ),
        ButtonSegment(
          value: Icons.directions_walk,
          label: showLabel ? const Text('walk') : null,
          icon: const Icon(Icons.directions_walk),
        ),
        ButtonSegment(
          value: Icons.directions_run,
          label: showLabel ? const Text('run') : null,
          icon: const Icon(Icons.directions_run),
        ),
        ButtonSegment(
          value: Icons.directions_bike,
          label: showLabel ? const Text('bike') : null,
          icon: const Icon(Icons.directions_bike),
        ),
      ],
      selected: _selected,
      multiSelectionEnabled: true,
      emptySelectionAllowed: false,
      onSelectionChanged: (selected) => setState(() => _selected = selected),
    );
  }
}
