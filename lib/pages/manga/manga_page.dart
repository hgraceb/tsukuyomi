import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

import 'manga_controller.dart';

/// 漫画详情页面
class MangaPage extends ConsumerStatefulWidget {
  const MangaPage({super.key, required this.mangaId});

  final String mangaId;

  @override
  ConsumerState<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends ConsumerState<MangaPage> {
  @override
  Widget build(BuildContext context) {
    final provider = mangaControllerProvider(widget.mangaId);
    final controller = ref.read(provider.notifier);

    return _MangaPageRefreshIndicator(
      provider: provider,
      controller: controller,
      builder: (scrollController) => TsukuyomiAsyncScaffold(
        provider: provider,
        scrollController: scrollController,
        scrollPhysics: const CustomBouncingScrollPhysics(start: false),
        sliverAppBar: (builder) => _MangaPageSliverAppBar(controller: controller, builder: builder),
        sliversBody: (builder) => [
          _MangaPageSliverBody(mangaId: widget.mangaId, controller: controller, builder: builder),
        ],
      ),
    );
  }
}

class _MangaPageRefreshIndicator extends ConsumerStatefulWidget {
  const _MangaPageRefreshIndicator({required this.controller, required this.builder, required this.provider});

  final MangaController controller;

  final TsukuyomiRefreshIndicatorBuilder builder;

  final ProviderBase<AsyncValue<MangaState>> provider;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MangaPageRefreshIndicatorState();
}

class _MangaPageRefreshIndicatorState extends ConsumerState<_MangaPageRefreshIndicator> {
  Future<void>? _refreshIndicatorFuture;
  final _refreshIndicatorKey = GlobalKey<TsukuyomiRefreshIndicatorState>();

  Future<void> _refresh() async {
    if (_refreshIndicatorFuture != null) return _refreshIndicatorFuture;
    final completer = Completer<void>();
    _refreshIndicatorFuture = completer.future;
    _refreshIndicatorKey.currentState?.show();
    await widget.controller.refreshChapters();
    _refreshIndicatorFuture = null;
    completer.complete();
  }

  @override
  void initState() {
    super.initState();
    // 如果章节数据列表为空则尝试自动刷新一次
    late final ProviderSubscription<AsyncValue<MangaState>> subscription;
    subscription = ref.listenManual(widget.provider, (previous, next) {
      final chapters = next.valueOrNull?.chapters;
      if (chapters == null) return;
      if (chapters.isEmpty) _refresh();
      subscription.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiRefreshIndicator(
      key: _refreshIndicatorKey,
      builder: widget.builder,
      onRefresh: _refresh,
    );
  }
}

class _MangaPageSliverAppBar extends StatelessWidget {
  const _MangaPageSliverAppBar({required this.controller, required this.builder});

  final MangaController controller;

  final SliverDataBuilder<MangaState> builder;

  @override
  Widget build(BuildContext context) {
    return builder(
      select: (state) => (
        manga: state.manga,
        source: state.source,
      ),
      data: (state) => SliverStack(children: [
        SliverToBoxAdapter(
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
              stops: [0.5, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: MediaQuery.paddingOf(context).top + 260,
              child: Opacity(
                opacity: 0.2,
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: state.manga.cover,
                  httpHeaders: state.source.headers,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        SliverPositioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, kToolbarHeight + 16.0, 16.0, 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Card(
                    margin: EdgeInsets.zero,
                    borderOnForeground: false,
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: state.manga.cover,
                      errorWidget: (_, __, ___) => const ErrorImageWidget(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        TsukuyomiSliverAppBar(
          title: Text(state.manga.title),
          actions: [
            IconButton(
              onPressed: () => controller.toggleFavorite(state.manga),
              icon: Icon(
                color: state.manga.favorite ? Colors.red : null,
                state.manga.favorite ? Icons.favorite : Icons.favorite_outline,
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class _MangaPageSliverBody extends StatefulWidget {
  const _MangaPageSliverBody({required this.mangaId, required this.controller, required this.builder});

  final String mangaId;

  final MangaController controller;

  final SliverDataBuilder<MangaState> builder;

  @override
  State<StatefulWidget> createState() => _MangaPageSliverBodyState();
}

class _MangaPageSliverBodyState extends State<_MangaPageSliverBody> with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: false);
    _iconAnimation = Tween(begin: 0.0, end: 1.0).animate(_iconController);
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  /// 获取章节副标题
  Widget _getChapterSubtitle(ThemeData theme, MangaChapter chapter) {
    final date = chapter.chapter.date, images = chapter.chapter.images, progress = chapter.chapter.progress;

    return Row(children: [
      if (date.isNotEmpty) Flexible(flex: 2, child: Text(date, overflow: TextOverflow.ellipsis)),
      if (chapter.enabled && images > 0 && progress > 0) ...[
        Flexible(
          flex: 1,
          child: Text(
            '${date.isNotEmpty ? ' · ' : ''}${progress.clamp(1, images)} / $images',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.disabledColor),
          ),
        ),
      ],
    ]);
  }

  /// 获取章节列表项末尾显示的图标
  Widget _getChapterTrailing(MangaChapter chapter) {
    // 下载完成
    if (chapter.downloaded == true) {
      return IconButton(
        icon: const Icon(Icons.check_circle_outline),
        onPressed: () {
          // TODO 显示删除下载的菜单选项
        },
      );
    }
    // 章节下载信息
    final download = chapter.download;
    if (download == null) {
      // 公开章节
      if (chapter.chapter.public) {
        return IconButton(
          icon: const DownloadCircleIcon(),
          onPressed: () => widget.controller.insertDownload(chapter.chapter),
        );
      }
      // 未公开章节
      return const IconButton(
        onPressed: null,
        icon: Icon(Icons.not_interested_outlined),
      );
    }
    // 章节下载进度
    final downloadPercent = chapter.downloadPercent;
    if (downloadPercent == null) {
      // 下载出错
      if (download.error != null) {
        return IconButton(
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => widget.controller.resumeDownload(download),
        );
      }
      // 等待下载
      return IconButton(
        icon: AnimatedWaitingDownloadIcon(animation: _iconAnimation),
        onPressed: () => widget.controller.deleteDownload(download),
      );
    }
    // 正在下载
    return IconButton(
      icon: AnimatedProgressCircleIcon(progress: downloadPercent),
      onPressed: () => widget.controller.deleteDownload(download),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      select: (state) => state.chapters,
      data: (chapters) => SliverPrototypeExtentList.builder(
        prototypeItem: const ListTile(title: Text(''), subtitle: Text('')),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final data = chapters[index];
          final chapter = data.chapter;
          final theme = Theme.of(context);

          return InkWell(
            onTap: () {},
            child: ListTile(
              enabled: data.enabled,
              textColor: 0 < chapter.images && chapter.images <= chapter.progress ? theme.disabledColor : null,
              title: Text(chapter.title, overflow: TextOverflow.ellipsis),
              subtitle: _getChapterSubtitle(theme, data),
              trailing: _getChapterTrailing(data),
              onTap: () => context.pushNamed(TsukuyomiRouter.chapter.name, params: {
                'mangaId': widget.mangaId,
                'chapterId': '${chapter.id}',
              }),
            ),
          );
        },
      ),
    );
  }
}
