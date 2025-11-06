import 'package:flutter/material.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi_pixel_snap/widgets.dart';

/// 手势导航布局类型
enum GestureNavigationStyle {
  /// 菜单布局
  /// * +------+------+------+
  /// * | Menu | Menu | Menu |
  /// * +------+------+------+
  /// * | Menu | Menu | Menu |
  /// * +------+------+------+
  /// * | Menu | Menu | Menu |
  /// * +------+------+------+
  menu,

  /// 撬棍布局（スタイリッシュ暴漢スレイヤー！！？）
  /// * +------+------+------+
  /// * | Prev | Prev | Next |
  /// * +------+------+------+
  /// * | Prev | Menu | Next |
  /// * +------+------+------+
  /// * | Prev | Next | Next |
  /// * +------+------+------+
  crowbar,
}

enum _Action {
  /// 上页
  prev,

  /// 菜单
  menu,

  /// 下页
  next,
}

/// 手势导航页面
class ChapterGestureNavigation extends StatefulWidget {
  final Curve curve;
  final bool visible;
  final Duration duration;
  final VoidCallback? onPrev;
  final VoidCallback? onMenu;
  final VoidCallback? onNext;
  final GestureNavigationStyle gestureNavigationStyle;

  const ChapterGestureNavigation({
    super.key,
    this.onPrev,
    this.onMenu,
    this.onNext,
    this.visible = false,
    this.curve = Curves.easeInOutCubic,
    this.duration = const Duration(milliseconds: 300),
    this.gestureNavigationStyle = GestureNavigationStyle.crowbar,
  });

  @override
  State<ChapterGestureNavigation> createState() {
    return _ChapterGestureNavigationState();
  }
}

class _ChapterGestureNavigationState extends State<ChapterGestureNavigation> {
  final _config = {
    GestureNavigationStyle.menu: [
      _Action.menu, _Action.menu, _Action.menu, // 菜单 菜单 菜单
      _Action.menu, _Action.menu, _Action.menu, // 菜单 菜单 菜单
      _Action.menu, _Action.menu, _Action.menu, // 菜单 菜单 菜单
    ],
    GestureNavigationStyle.crowbar: [
      _Action.prev, _Action.prev, _Action.next, // 上页 上页 下页
      _Action.prev, _Action.menu, _Action.next, // 上页 菜单 下页
      _Action.prev, _Action.next, _Action.next, // 上页 下页 下页
    ],
  };

  _Action _action(int column, int row) {
    final action = _config[widget.gestureNavigationStyle]?[column * 3 + row];
    return action ?? _Action.menu;
  }

  String _text(_Action action, TsukuyomiLocalizations l10n) {
    return switch (action) {
      _Action.prev => l10n.navigationPrev,
      _Action.menu => l10n.navigationMenu,
      _Action.next => l10n.navigationNext,
    };
  }

  Color _color(_Action action) {
    return switch (action) {
      _Action.prev => Colors.red,
      _Action.menu => Colors.blue,
      _Action.next => Colors.indigo,
    };
  }

  VoidCallback? _onTap(_Action action) {
    return switch (action) {
      _Action.prev => widget.onPrev,
      _Action.menu => widget.onMenu,
      _Action.next => widget.onNext,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;

    return AnimatedOpacity(
      curve: widget.curve,
      duration: widget.duration,
      opacity: widget.visible ? 1.0 : 0.0,
      child: TsukuyomiPixelColumn(
        children: List.generate(3, (column) {
          return Expanded(
            child: TsukuyomiPixelRow(
              children: List.generate(3, (row) {
                final action = _action(column, row);
                return Expanded(
                  child: _GestureRegion(
                    visible: widget.visible,
                    text: _text(action, l10n),
                    color: _color(action),
                    onTap: _onTap(action),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// 手势导航区域
class _GestureRegion extends StatelessWidget {
  /// 文本
  final String text;

  /// 颜色
  final Color color;

  /// 是否可见
  final bool visible;

  /// 单击事件回调
  final VoidCallback? onTap;

  const _GestureRegion({
    required this.onTap,
    required this.text,
    required this.color,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      IgnorePointer(
        // 组件不可见时忽略手势事件，避免拦截非单击事件
        ignoring: !visible,
        child: Container(
          color: color.withOpacity(0.8),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      // 只检测单击事件
      GestureDetector(onTap: onTap),
    ]);
  }
}
