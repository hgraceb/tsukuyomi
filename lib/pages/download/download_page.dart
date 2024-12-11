import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/download/download_repository.dart';

import 'download_controller.dart';

/// 下载页面
class DownloadPage extends ConsumerWidget {
  const DownloadPage({super.key});

  /// 下载列表项的标题
  Widget _buildTitle(DownloadWithExtra data) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 漫画标题
          Expanded(
            child: Text(
              data.manga.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 下载进度
          if (data.download.total > 0) ...[
            // 约束文本最大宽度
            ConstrainedBox(
              constraints: constraints.copyWith(minWidth: 0),
              child: Text(
                '${data.download.progress} / ${data.download.total}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  // 设置数字等宽避免跳动显示 TODO (#00) 判断是否需要优化文本跳动处理
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 下载列表项的副标题
  Widget _buildSubTitle(ThemeData theme, DownloadWithExtra data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 章节标题
        Flexible(
          flex: 1,
          child: Text(data.chapter.title, overflow: TextOverflow.ellipsis),
        ),
        // 错误信息 TODO 优化包含换行符的错误文本显示，如：(OS Error: 系统找不到指定的路径。\n, errno = 3)
        if (data.download.error?.isNotEmpty == true) ...[
          Flexible(
            flex: 2,
            child: Text(
              data.download.error ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  /// 下载列表项的末尾组件 TODO 使用设置图标和弹窗替换只能进行单个操作的图标
  _buildTrailing(DownloadController controller, DatabaseDownload download) {
    if (download.error?.isNotEmpty == true) {
      return IconButton(
        icon: const Icon(Icons.refresh_outlined),
        onPressed: () => controller.resumeDownload(download),
      );
    }
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => controller.deleteDownload(download),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final controller = ref.read(downloadControllerProvider.notifier);

    return TsukuyomiAsyncScaffold(
      provider: downloadControllerProvider,
      sliverAppBarBuilder: (builder) => TsukuyomiSliverAppBar(
        title: Text(l10n.downloadTitle),
      ),
      sliversBody: (builder) => [
        builder(
          select: (state) => state.downloads,
          data: (downloads) => SliverPrototypeExtentList.builder(
            prototypeItem: const ListTile(title: Text(''), subtitle: Text('')),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final data = downloads[index];
              final theme = Theme.of(context);
              return InkWell(
                onTap: () {},
                child: ListTile(
                  title: _buildTitle(data),
                  subtitle: _buildSubTitle(theme, data),
                  trailing: _buildTrailing(controller, data.download),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
