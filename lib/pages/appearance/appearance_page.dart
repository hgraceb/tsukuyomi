import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/providers/providers.dart';

/// 外观设置页面
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;

    return TsukuyomiScaffold(
      body: CustomScrollView(
        slivers: [
          SliverStack(children: [
            TsukuyomiSliverAppBar(
              title: Text(l10n.appearanceTitle),
            ),
            const TsukuyomiSliverLeadingAppBar(),
          ]),
          const SliverToBoxAdapter(
            child: Column(
              children: <Widget>[
                _AppearanceTheme(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 主题设置
class _AppearanceTheme extends ConsumerWidget {
  const _AppearanceTheme();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final provider = ref.watch(themePreferenceProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.appearanceThemeTitle),
          ),
          ListTile(
            title: Text(l10n.appearanceThemeDarkMode),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            trailing: Switch(
              value: provider.themeMode == ThemeMode.dark,
              onChanged: (value) => ref.read(themePreferenceProvider.notifier).setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
        ],
      ),
    );
  }
}
