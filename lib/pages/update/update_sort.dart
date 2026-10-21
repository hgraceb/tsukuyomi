import 'package:tsukuyomi/providers/update/update_state.dart';

/// 更新列表按漫画源、漫画名排序，同名时用 ID 确定顺序
int compareUpdateItems(UpdateReportItem a, UpdateReportItem b) {
  final sourceOrder = a.sourceName.compareTo(b.sourceName);
  if (sourceOrder != 0) return sourceOrder;
  final titleOrder = a.mangaTitle.compareTo(b.mangaTitle);
  if (titleOrder != 0) return titleOrder;
  final sourceIdOrder = a.sourceId.compareTo(b.sourceId);
  return sourceIdOrder != 0 ? sourceIdOrder : a.mangaId.compareTo(b.mangaId);
}
