import 'package:flutter/material.dart';
import 'package:tsukuyomi_patch/material.dart';

typedef TsukuyomiRefreshIndicatorBuilder = Widget Function(ScrollController scrollController);

class TsukuyomiRefreshIndicator extends StatefulWidget {
  const TsukuyomiRefreshIndicator({super.key, required this.onRefresh, required this.builder});

  final RefreshCallback onRefresh;

  final TsukuyomiRefreshIndicatorBuilder builder;

  @override
  State<StatefulWidget> createState() => TsukuyomiRefreshIndicatorState();
}

class TsukuyomiRefreshIndicatorState extends State<TsukuyomiRefreshIndicator> {
  final _scrollController = ScrollController();
  final _refreshIndicatorKey = GlobalKey<PatchedRefreshIndicatorState>();

  void show() {
    _refreshIndicatorKey.currentState?.show();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) {
          // 取消越界滚动效果
          notification.disallowIndicator();
        }
        return true;
      },
      child: PatchedRefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: widget.onRefresh,
        scrollController: _scrollController,
        displacement: kToolbarHeight + MediaQuery.paddingOf(context).top, // 修改默认位移距离
        child: widget.builder(_scrollController), // 使用默认滚动控制器以解决与可滚动组件一起使用时的视差问题
      ),
    );
  }
}
