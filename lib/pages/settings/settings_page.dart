import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;

    return TsukuyomiScaffold(
      body: CustomScrollView(
        slivers: [
          TsukuyomiSliverAppBar(
            title: Text(l10n.settingsTitle),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                onTap: () => context.pushNamed(TsukuyomiRouter.themePreview.name),
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.themePreviewTitle),
              ),
              ListTile(
                onTap: () => context.pushNamed(TsukuyomiRouter.debug.name),
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.debugTitle),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
