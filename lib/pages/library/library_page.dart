import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/widgets/widgets.dart';
import 'package:tsukuyomi_patch/material.dart';

import 'library_controller.dart';
import 'widgets/library_scroll_controller.dart';

/// 书架页面
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final provider = libraryControllerProvider;

    return TsukuyomiAsyncHandler(
      provider: provider,
      builder: (state) => TsukuyomiScaffold(
        body: SelectAsyncWatch(
          provider: provider,
          select: (state) => (
            sources: state.mangas.keys.toList(),
            mangas: state.mangas.values.toList(),
          ),
          loading: () => const CenterLoading(),
          error: (error, stackTrace) => CenterRetry(onRetry: () => ref.invalidate(provider)),
          data: (state) => DefaultTabController(
            length: state.sources.length,
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: TsukuyomiSliverAppBar(
                    pinned: true,
                    shadow: false,
                    title: Text(l10n.libraryTitle),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => context.pushNamed(TsukuyomiRouter.search.name),
                      ),
                    ],
                    bottom: PatchedTabBar(
                      isScrollable: true,
                      dividerColor: Colors.transparent,
                      tabAlignment:  TabAlignment.center,
                      // TODO 限制最大文本宽度
                      tabs: state.sources.map((source) => Tab(text: source.name)).toList(),
                    ),
                  ),
                ),
              ],
              body: Builder(
                builder: (context) => LibraryScrollBuilder(
                  ids: state.sources.map((source) => source.id),
                  tabController: DefaultTabController.of(context),
                  scrollController: PrimaryScrollController.of(context),
                  builder: (context, controllers) => TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: List.generate(
                      state.sources.length,
                      (index) => _LibraryMangaList(
                        controller: controllers[state.sources[index].id]!,
                        mangas: state.mangas[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryMangaList extends StatefulWidget {
  const _LibraryMangaList({required this.controller, required this.mangas});

  final ScrollController controller;

  final List<DatabaseManga> mangas;

  @override
  State<StatefulWidget> createState() => _LibraryMangaListState();
}

class _LibraryMangaListState extends State<_LibraryMangaList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: EdgeInsets.only(top: NestedScrollView.sliverOverlapAbsorberHandleFor(context).layoutExtent!),
      child: CustomScrollView(
        physics: const CustomBouncingScrollPhysics(start: false), // 禁用顶部越界滚动，避免快速滑动到嵌套滚动组件顶部时出现卡顿
        scrollBehavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // 禁用滚动条，避免拖动滚动条时出现页面位置跳动
        controller: widget.controller,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                childAspectRatio: 0.66,
                maxCrossAxisExtent: 200.0,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: widget.mangas.length,
                (context, index) => GestureDetector(
                  onTap: () => context.pushNamed(TsukuyomiRouter.manga.name, params: {
                    'mangaId': '${widget.mangas[index].id}',
                  }),
                  child: Card(
                    borderOnForeground: false,
                    clipBehavior: Clip.antiAlias,
                    // TODO 添加请求头和加载动画
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: widget.mangas[index].cover,
                      errorWidget: (_, __, ___) => const ErrorImageWidget(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
