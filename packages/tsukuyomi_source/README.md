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

显示名称由应用层按界面语言处理，不写入漫画源数据。本包不依赖界面语言或展示组件，语言显示库尚未接入。

### 语言显示库调研（2026-11-14）

建议后续采用 `common_locale_data`，当前 SDK 使用 `2.2.1`。它已有组合名称格式化接口，不需要自己实现 CLDR 规则或维护全部翻译。

以下核对了发布包源码、版本约束和更新记录；前三个库在工程当前的 Dart 3.10 SDK 中建立独立临时项目验证，未改变应用依赖。

| 候选 | 核对结果 | 结论 |
| --- | --- | --- |
| [common_locale_data 2.2.1](https://pub.dev/packages/common_locale_data/versions/2.2.1) | 纯 Dart，使用 CLDR 46；支持语言、文字、地区和变体的组合名称，中文和英文显示已实测 | 当前首选 |
| [flutter_localized_locales 2.0.5](https://pub.dev/packages/flutter_localized_locales/versions/2.0.5) | 最后发布于 2023-09-21；按完整代码查表，需将连字符改为下划线；实测 `es-419`、`fr-JP`、`de-1901` 均无结果 | 更适合固定语言选择列表 |
| [locale_names 1.1.1](https://pub.dev/packages/locale_names/versions/1.1.1) | 最后发布于 2023-07-31；分别返回语言与文字、地区名称，需要自行组合；Flutter Locale 不承载变体 | 当前需求下需要额外维护展示规则 |
| [intl4x 1.0.1](https://pub.dev/packages/intl4x/versions/1.0.1) | 发布于 2026-09-23；原生端使用 ICU4X，Web 使用浏览器 Intl；要求 Dart 3.12，DisplayNames 仍标记 experimental | 当前 SDK 不选，后续升级时可重新评估 |

`common_locale_data` 最新版 `2.4.0` 发布于 2026-10-07，仍有更新；但 `2.3.0` 起要求 Dart 3.12。`2.2.1` 发布于 2025-01-25，最低要求 Dart 3.5，已在当前 SDK 验证。[版本与 SDK 要求](https://pub.dev/packages/common_locale_data/versions)

推荐调用方式：仅导入应用支持的 `zh`、`en` 显示数据，使用 `localeDisplayName.format(LanguageId.parse(code))`；无需导入所有正文语言对应的数据文件。普通语言显示不调用处理扩展字段的 `formatWithExtensions`。

```dart
import 'package:common_locale_data/zh.dart';

final names = CommonLocaleDataZh().localeDisplayName;
final label = names.format(LanguageId.parse('sr-Latn-RS'));
// 塞尔维亚语（拉丁文，塞尔维亚）
```

`2.2.1` 默认格式化的实际输出：

| 代码 | 中文界面 | 英文界面 |
| --- | --- | --- |
| ja | 日语 | Japanese |
| zh-Hant | 繁体中文 | Traditional Chinese |
| zh-Hant-HK | 繁体中文（中国香港特别行政区） | Traditional Chinese (Hong Kong SAR China) |
| pt-BR | 巴西葡萄牙语 | Brazilian Portuguese |
| es-419 | 拉丁美洲西班牙语 | Latin American Spanish |
| sr-Latn-RS | 塞尔维亚语（拉丁文，塞尔维亚） | Serbian (Latin, Serbia) |
| de-1901 | 德语（传统德文拼字） | German (Traditional German orthography) |

该库默认优先使用约定名称，例如“巴西葡萄牙语”；若希望统一显示“葡萄牙语（巴西）”，可以通过 `preferComposition: true` 配置，无需自己拼接名称。[格式化接口](https://pub.dev/documentation/common_locale_data/2.2.1/common_locale_data/LocaleDisplayName/format.html)

需要在应用封装中明确的边界：

- 源数据仍由源映射并经过现有规范化；库的解析器较宽松，不能替代源数据校验，也不将显示时的代码规范化结果写回数据库
- 未收录代码默认带说明，例如 `qaa` 显示为“未知语言［qaa］”；应用若采用原代码回退，应在调用前检查名称数据是否存在
- 按界面语言导入数据可以控制体积。Windows 独立 Dart AOT 探针中，中英文格式化程序相对基础 JSON 输出程序增加 1,864,192 字节（约 1.78 MiB）；这不是 Flutter 应用安装包增量
- 作为对照，`flutter_localized_locales 2.0.5` 声明打包整个 data 目录，发布包中的 563 个 JSON 文件合计 15,866,180 字节（未压缩）；不能直接与 AOT 增量比较
- 本次验证包含桌面运行、14 个语言代码的中英文输出、未知子标记和独立 AOT 编译；正式接入后仍需核对实际 Flutter 包体积与页面效果
