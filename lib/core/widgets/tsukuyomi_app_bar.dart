import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// 导航图标和菜单图标与屏幕的边距
const _kPaddingWidth = 8.0;

extension on BuildContext {
  bool get hasDrawer {
    final scaffold = Scaffold.maybeOf(this);
    return scaffold?.hasDrawer ?? false;
  }

  bool get hasDismiss {
    final parentRoute = ModalRoute.of(this);
    return parentRoute?.impliesAppBarDismissal ?? false;
  }

  bool get hasLeading {
    return hasDrawer || hasDismiss;
  }

  bool get useCloseButton {
    final parentRoute = ModalRoute.of(this);
    return parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;
  }

  Widget get appBarLeading {
    if (hasDrawer) {
      return const DrawerButton();
    } else if (hasDismiss) {
      return useCloseButton ? const CloseButton() : const BackButton();
    } else {
      return const SizedBox.shrink();
    }
  }

  double getLeadingWidth(bool hasLeading) {
    if (hasLeading) {
      return switch (Theme.of(this).materialTapTargetSize) {
        // 移动端的导航图标宽度
        MaterialTapTargetSize.padded => kMinInteractiveDimension + _kPaddingWidth,
        // 桌面端的导航图标宽度 [_IconButtonDefaultsM3.minimumSize]
        MaterialTapTargetSize.shrinkWrap => 40.0 + _kPaddingWidth,
      };
    } else {
      return 0.0;
    }
  }

  Widget? buildLeading(bool hasLeading) {
    if (hasLeading) {
      return Row(children: [const SizedBox(width: _kPaddingWidth), appBarLeading]);
    } else {
      return null;
    }
  }

  Widget? buildTitle(bool hasLeading, Widget? title) {
    if (hasLeading || title == null) {
      // 如果有导航图标或者标题组件则不用额外设置左边距
      return title;
    } else {
      // 如果没有导航图标则为标题组件额外设置左边距以平衡与右侧菜单图标的整体页面视觉效果
      return Padding(padding: const EdgeInsets.only(left: _kPaddingWidth), child: title);
    }
  }

  List<Widget>? buildActions(List<Widget>? actions) {
    if (actions == null) {
      return actions;
    } else {
      return [...actions, const SizedBox(width: _kPaddingWidth)];
    }
  }
}

class TsukuyomiAppBar extends StatelessWidget {
  const TsukuyomiAppBar({
    super.key,
    this.title,
    this.elevation,
    this.backgroundColor,
  });

  final Widget? title;

  final double? elevation;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasLeading = context.hasLeading;
    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor,
      titleSpacing: _kPaddingWidth,
      toolbarHeight: kToolbarHeight,
      leadingWidth: context.getLeadingWidth(hasLeading),
      leading: context.buildLeading(hasLeading),
      title: context.buildTitle(hasLeading, title),
    );
  }
}

class TsukuyomiSliverAppBar extends StatelessWidget {
  const TsukuyomiSliverAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.pinned = false,
    this.shadow = true,
  });

  final Widget? title;

  final List<Widget>? actions;

  final PreferredSizeWidget? bottom;

  final bool pinned;

  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final hasLeading = context.hasLeading;
    return SliverStack(children: [
      if (shadow) const _SliverAppBarShadow(toolbarHeight: kToolbarHeight),
      SliverAppBar(
        pinned: pinned,
        floating: true,
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.transparent,
        titleSpacing: _kPaddingWidth,
        toolbarHeight: kToolbarHeight,
        leadingWidth: context.getLeadingWidth(hasLeading),
        leading: const SizedBox.shrink(),
        title: _FadeSliverAppBarTitle(title: context.buildTitle(hasLeading, title)),
        actions: context.buildActions(actions),
        bottom: bottom,
      ),
    ]);
  }
}

class TsukuyomiSliverLeadingAppBar extends StatelessWidget {
  const TsukuyomiSliverLeadingAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final hasLeading = context.hasLeading;
    // 移除右侧安全区域，避免导航图标区域被压缩
    return MediaQuery.removePadding(
      context: context,
      removeRight: true,
      child: SliverPadding(
        padding: EdgeInsets.only(
          // 只显示导航图标区域，避免拦截其他区域的点击事件
          right: MediaQuery.sizeOf(context).width - MediaQuery.paddingOf(context).left - kToolbarHeight,
        ),
        sliver: SliverAppBar(
          floating: true,
          scrolledUnderElevation: 0.0,
          backgroundColor: Colors.transparent,
          toolbarHeight: kToolbarHeight,
          leadingWidth: context.getLeadingWidth(hasLeading),
          leading: context.buildLeading(hasLeading),
        ),
      ),
    );
  }
}

/// 应用栏渐变标题
class _FadeSliverAppBarTitle extends StatelessWidget {
  const _FadeSliverAppBarTitle({required this.title});

  final Widget? title;

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return const SizedBox.shrink();
    } else {
      // 获取 SliverAppBar 为文本设置的透明度
      final opacity = DefaultTextStyle.of(context).style.color?.opacity ?? 1.0;
      return Opacity(opacity: opacity, child: title);
    }
  }
}

class _SliverAppBarShadow extends StatefulWidget {
  const _SliverAppBarShadow({required this.toolbarHeight});

  final double toolbarHeight;

  @override
  State<_SliverAppBarShadow> createState() => _SliverAppBarShadowState();
}

class _SliverAppBarShadowState extends State<_SliverAppBarShadow> {
  double _topPadding = 0.0;
  double _appBarOpacity = 0.0;
  double _appBarShrinkOffset = 0.0;

  /// 获取应用栏的高度
  double _getAppBarHeight(double maxHeight, double shrinkOffset) {
    // 根据滚动偏移量计算应用栏显示高度
    if (shrinkOffset < widget.toolbarHeight) {
      return (maxHeight - shrinkOffset).clamp(0.0, maxHeight);
    }
    // 将应用栏最小高度限制为状态栏高度
    return _topPadding.clamp(0.0, maxHeight);
  }

  /// 获取应用栏的不透明度
  double _getAppBarOpacity(double maxHeight, double scrollOffset) {
    // 如果应用栏滚动到了起始位置
    if (scrollOffset <= 0.0) {
      return _appBarOpacity = 0.0;
    }
    // 如果应用栏滚动到安全范围外
    if (scrollOffset > maxHeight - _topPadding) {
      return _appBarOpacity = 1.0;
    }
    // 如果应用栏曾经滚动到安全范围外
    if (_appBarOpacity > 0.0) {
      final percent = (scrollOffset / maxHeight).clamp(0.0, 1.0);
      return _appBarOpacity = Curves.easeOutQuint.transform(percent);
    }
    // 返回应用栏之前显示的的不透明度
    return _appBarOpacity;
  }

  @override
  Widget build(BuildContext context) {
    _topPadding = MediaQuery.paddingOf(context).top;
    final maxHeight = _topPadding + widget.toolbarHeight;

    // 屏蔽背景遮罩点击事件
    return SliverIgnorePointer(
      sliver: SliverStack(children: [
        // 应用栏的背景遮罩控件
        SliverLayoutBuilder(
          builder: (context, constraints) => SliverAnimatedOpacity(
            opacity: _getAppBarOpacity(maxHeight, constraints.scrollOffset),
            duration: const Duration(milliseconds: 300),
            sliver: SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarMaskDelegate(
                height: _getAppBarHeight(maxHeight, _appBarShrinkOffset),
              ),
            ),
          ),
        ),
        // 应用栏的位置检测控件
        SliverPersistentHeader(
          floating: true,
          delegate: _SliverAppBarMaskDelegate(
            height: maxHeight,
            onBuild: (shrinkOffset) {
              if (_appBarShrinkOffset == shrinkOffset) return;
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _appBarShrinkOffset = shrinkOffset);
              });
            },
          ),
        ),
      ]),
    );
  }
}

/// 应用栏的背景遮罩
class _SliverAppBarMaskDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarMaskDelegate({required this.height, this.onBuild});

  final double height;

  final void Function(double shrinkOffset)? onBuild;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    // 不显示控件只处理回调
    if (onBuild != null) {
      onBuild!(shrinkOffset);
      return const SizedBox.shrink();
    }
    // 绘制应用栏的背景遮罩
    return ShaderMask(
      blendMode: BlendMode.dstOut,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // 遮罩渐变透明度列表，在 20 之后继续增加数组长度没有明显优化
        colors: List.generate(20, (index) {
          return Colors.black.withOpacity(
            Curves.easeInQuint.transform(index / (20 - 1)),
          );
        }),
      ).createShader(rect),
      // TODO 动态获取背景颜色
      child: Container(
        color: const Color.fromARGB(255, 30, 32, 60),
      ),
    );
  }

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(covariant _SliverAppBarMaskDelegate oldDelegate) {
    return height != oldDelegate.height || onBuild != oldDelegate.onBuild;
  }
}
