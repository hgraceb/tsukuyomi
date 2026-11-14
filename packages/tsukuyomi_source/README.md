# Source APIs and utilities for Tsukuyomi

## 生成代码

在本包目录执行：

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

首次构建应用时，先生成本包代码，再在工程根目录生成应用代码。生成文件沿用工程规则，不提交到 Git。

## 漫画详情

```dart
final manga = HttpSourceManga(
  url: 'https://example.com/manga/1',
  name: '示例漫画',
  cover: 'https://example.com/covers/1.jpg',
  status: SourceMangaStatus.ongoing,
  description: '第一段简介。\n\n第二段简介。',
  creators: [SourceMangaCreator(name: '示例作者')],
  tags: [SourceMangaTag(name: '冒险', type: SourceMangaTagType.genre)],
  languages: normalizeMangaLanguages(['ja', 'zh-hant']),
);
```

- 状态使用 `SourceMangaStatus`，标签分类使用 `SourceMangaTagType`；源站的文字或数字由各漫画源映射
- 状态编码为 `unknown`、`ongoing`、`completed`、`hiatus`、`cancelled`，分别表示未知、连载、完结、休刊、中止
- 标签分类编码为 `genre`、`theme`、`format`、`demographic`、`content`、`tag`，无法判断分类时使用 `tag`
- 内容语言使用 `List<String>`，保留语言、文字和地区信息，例如 `ja`、`zh-Hant`、`pt-BR`
- 可选详情为 `null` 表示未提供；空文本、空列表和 `SourceMangaStatus.unknown` 表示明确提供的值

状态、标签分类和作者的 JSON 转换使用 `json_serializable` 生成的映射或转换函数，JSON 中的枚举仍是字符串：

```dart
SourceMangaStatus.completed.toJson(); // 'completed'
SourceMangaStatus.fromJson('completed'); // SourceMangaStatus.completed
SourceMangaTag(name: '冒险', type: SourceMangaTagType.genre).toJson();
// {'name': '冒险', 'type': 'genre'}
SourceMangaCreator(name: '示例作者').toJson(); // {'name': '示例作者'}
```

未知枚举编码直接报错。源站的未知状态应由适配代码明确映射为 `SourceMangaStatus.unknown`，不在 JSON 解码时吞掉拼写错误。

漫画源脚本当前使用 `if/else` 进行状态映射；解释器尚未支持 `switch`，遇到该语法会明确报错。

## 内容语言的边界

源站标记由漫画源转换为标准语言代码，共享的 `normalizeMangaLanguages` 只负责格式校验、大小写、去重与排序：

```dart
// 源站使用 chinese 表示中文，且未提供文字或地区信息
final language = rawLanguage == 'chinese' ? 'zh' : rawLanguage;
final languages = normalizeMangaLanguages([language]);
```

标准化不会把 `zh-TW` 改写成 `zh-Hant`，也不会把不明确的中文补成简体中文。它校验常用代码结构，不校验完整语言注册表，暂不接受扩展或私用标记。

显示名称由应用层按界面语言处理，不写入漫画源数据。后续可使用 CLDR 的语言、文字和地区名称组合显示，未收录的代码保留原值；本包不依赖界面语言或展示组件。
