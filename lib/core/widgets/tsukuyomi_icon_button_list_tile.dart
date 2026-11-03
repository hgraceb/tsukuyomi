import 'package:flutter/material.dart';

/// 包含标准图标按钮的列表项
class TsukuyomiIconButtonListTile extends StatelessWidget {
  const TsukuyomiIconButtonListTile({
    super.key,
    this.enabled = true,
    this.textColor,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final bool enabled;

  final Color? textColor;

  final IconButton? leading;

  final Widget? title;

  final Widget? subtitle;

  final IconButton? trailing;

  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visualDensity = ListTileTheme.of(context).visualDensity ?? Theme.of(context).visualDensity;
    return ListTile(
      enabled: enabled,
      textColor: textColor,
      // 标准按钮内部有 12dp 留白，额外保留 4dp 形成 16dp 可见间距
      contentPadding: EdgeInsetsDirectional.only(start: leading == null ? 16.0 : 4.0, end: trailing == null ? 16.0 : 4.0),
      horizontalTitleGap: 4.0,
      // 固定水平间距，保留原有垂直密度
      visualDensity: visualDensity.copyWith(horizontal: 0.0),
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
