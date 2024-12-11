import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/pages.dart';
import 'package:tsukuyomi/widgets/common/always_keep_alive.dart';

import 'home_controller.dart';

/// 首页
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final provider = ref.watch(homeControllerProvider);
    final controller = ref.watch(homeControllerProvider.notifier);

    return Scaffold(
      body: PageView(
        controller: provider.pageController,
        // TODO 启用页面嵌套滚动并处理底部导航栏动画切换
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          AlwaysKeepAlive(child: LibraryPage()),
          AlwaysKeepAlive(child: DownloadPage()),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: provider.selectedIndex,
        destinations: [
          NavigationDestination(
            tooltip: '',
            label: l10n.libraryTitle,
            icon: const Icon(Icons.collections_bookmark_outlined),
            selectedIcon: const Icon(Icons.collections_bookmark),
          ),
          NavigationDestination(
            tooltip: '',
            label: l10n.downloadTitle,
            icon: const Icon(Icons.download_outlined),
            selectedIcon: const Icon(Icons.download),
          ),
          NavigationDestination(
            tooltip: '',
            label: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
          ),
        ],
        onDestinationSelected: (value) => controller.onDestinationSelected(value),
      ),
    );
  }
}
