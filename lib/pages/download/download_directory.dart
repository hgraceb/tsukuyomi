import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 生成不超过 240 个 UTF-8 字节的下载目录名
String downloadDirectoryName(String title) {
  const maxBytes = 240;
  // 每个 UTF-16 码元最多占 3 个 UTF-8 字节，短标题可以直接返回
  if (title.length * 3 <= maxBytes) return title;
  final bytes = utf8.encode(title);
  if (bytes.length <= maxBytes) return title;

  final suffix = '...${sha256.convert(bytes).toString().substring(0, 12)}';
  var end = maxBytes - suffix.length;
  // 如果截断位置位于 UTF-8 字符内部，退回到该字符的起点
  while ((bytes[end] & 0xc0) == 0x80) {
    end--;
  }
  return '${utf8.decoder.convert(bytes, 0, end)}$suffix';
}
