extension StringExtension on String {
  /// 去除首尾空白字符并转换为合法的文件夹名称
  String get toValidDirectoryName {
    // 非法字符映射替换
    final map = {'\\': '⧵', '/': 'Ⳇ', ':': '꞉', '*': '⁎', '?': '？', '"': '″', '<': '˂', '>': '˃', '|': 'ǀ'};
    // 去除首尾空白字符
    final trimmed = trim();
    // 替换非法半角字符
    final validFullWidth = trimmed.replaceAllMapped(RegExp(r'[\\/:*?"<>|]'), (m) => map[m[0]!] ?? m[0]!);
    // 替换末尾连点字符
    return validFullWidth.replaceAllMapped(RegExp(r'[. ]+$'), (m) => m[0]!.replaceAll('.', '․'));
  }
}
