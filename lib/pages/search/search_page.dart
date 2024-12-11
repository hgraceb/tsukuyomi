import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/widgets/widgets.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import 'search_controller.dart';

/// 搜索页面
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final provider = searchControllerProvider;
    final controller = ref.watch(provider.notifier);

    return TsukuyomiAsyncScaffold(
      provider: provider,
      sliverAppBar: (builder) => builder(
        select: (state) => (
          focusNode: state.focusNode,
          textController: state.textController,
          searchable: state.searchable,
        ),
        data: (state) => TsukuyomiSliverAppBar(
          title: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: controller.onTextChanged,
            onEditingComplete: controller.onSearch,
            focusNode: state.focusNode,
            controller: state.textController,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: state.searchable ? controller.onSearch : null,
            ),
          ],
        ),
      ),
      sliversBody: (builder) => [
        builder(
          select: (state) => state.sources,
          data: (sources) => SliverList.builder(
            itemCount: sources.length,
            itemBuilder: (context, index) => Column(children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                title: Text(
                  maxLines: 1,
                  sources[index].name,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  maxLines: 1,
                  sources[index].name.split('\n').last,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 160,
                child: _SearchPageResult(
                  controller: controller,
                  source: sources[index],
                  builder: builder,
                  padding: 16.0,
                ),
              ),
              if (index == sources.length - 1) const SizedBox(height: 16.0),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SearchPageResult extends StatelessWidget {
  const _SearchPageResult({required this.controller, required this.source, required this.builder, required this.padding});

  final SearchController controller;

  final DatabaseSource source;

  final SliverDataBuilder<SearchState> builder;

  final double padding;

  @override
  Widget build(BuildContext context) {
    return builder(
      select: (state) => (
        error: state.errors[source.id],
        result: state.results[source.id],
        isLoading: state.loadings.contains(source.id),
        source: state.cachedSources[source.id],
        headers: state.cachedSources[source.id]?.headers,
      ),
      data: (state) => TsukuyomiAnimatedSwitcher(
        child: Card(
          key: ValueKey(state.result == null),
          color: Colors.transparent,
          margin: state.result == null ? EdgeInsets.symmetric(horizontal: padding) : EdgeInsets.zero,
          shape: state.result == null ? null : const RoundedRectangleBorder(),
          child: Builder(builder: (context) {
            if (state.result?.data case List<SourceManga> mangas) {
              return TsukuyomiAnimatedSwitcher(
                child: ListView.separated(
                  key: const ValueKey('results'),
                  scrollDirection: Axis.horizontal,
                  itemCount: mangas.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: 12.0),
                  // 还有下一页内容时禁用列表末尾越界滚动，避免在快速滚动时到末尾时触发滚动回弹导致滚动行为异常
                  physics: state.result?.next == true ? const CustomBouncingScrollPhysics(end: false) : null,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? padding : 0.0,
                      right: index == mangas.length ? padding : 0.0,
                    ),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Builder(builder: (context) {
                        if (index < mangas.length) {
                          return GestureDetector(
                            onTap: () => controller.pushMangaPage(context, source, mangas.elementAt(index)),
                            child: Card(
                              borderOnForeground: false,
                              clipBehavior: Clip.antiAlias,
                              margin: EdgeInsets.zero,
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                httpHeaders: state.headers,
                                imageUrl: mangas.elementAt(index).cover,
                                errorWidget: (_, __, ___) => const ErrorImageWidget(),
                              ),
                            ),
                          );
                        } else if (state.result?.next == true) {
                          controller.onNext(state.source, state.result);
                          return const Center(
                            child: SizedBox.square(
                              dimension: 24.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                              ),
                            ),
                          );
                        } else {
                          return const Card(
                            margin: EdgeInsets.zero,
                            color: Colors.transparent,
                            child: Center(
                              child: IconButton(
                                onPressed: null,
                                icon: Icon(Icons.done_all_outlined),
                              ),
                            ),
                          );
                        }
                      }),
                    ),
                  ),
                ),
              );
            }
            if (state.error case String error) {
              return TsukuyomiAnimatedSwitcher(
                child: Container(
                  key: const ValueKey('error'),
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const IconButton(
                        onPressed: null,
                        icon: Icon(Icons.search_off_outlined),
                      ),
                      Text(
                        '$error\n\n',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state.isLoading) {
              return TsukuyomiAnimatedSwitcher(
                child: const Center(
                  key: ValueKey('loading'),
                  child: SizedBox.square(
                    dimension: 24.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                    ),
                  ),
                ),
              );
            }
            return TsukuyomiAnimatedSwitcher(
              child: const Center(
                key: ValueKey('default'),
                child: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.image_search_rounded),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
