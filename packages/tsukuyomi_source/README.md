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

当前尚未选定或接入显示库。此前仅根据兼容性与格式化探针就将 `common_locale_data 2.2.1` 列为首选，依据不足，撤回该推荐；已验证的输出仅证明对应输入可以运行，不能替代维护情况与真实页面需求的评估。

先明确显示需求：漫画详情优先使用“中文”“简体中文”“繁体中文”“日语”等短名称。地区只在需要区分版本时展示，存储完整代码不要求页面展开全部子标记。

Mihon 的处理已核对本地参考代码：

- 漫画源列表取 `source.lang`，由 `LocaleHelper.getSourceDisplayName` 调用 Android/Java 的 `Locale.getDisplayName`，普通语言名称使用该语言自身的写法
- `zh-CN`、`zh-TW` 在生成名称前分别转为 `zh-Hans`、`zh-Hant`，不保留其中的地区部分；并不会主动给所有语言补充地区
- 参考源 Mikagogo 在 `build.gradle.kts` 中实际配置 `lang = "zh"`，不包含文字或地区子标记
- 之前的“繁体中文（中国香港特别行政区）”来自向测试库传入 `zh-Hant-HK`，不是 Mihon 的界面实测，也不作为本应用的默认展示方案

[名称处理源码](https://github.com/mihonapp/mihon/blob/master/app/src/main/java/eu/kanade/tachiyomi/util/system/LocaleHelper.kt) · [源列表显示源码](https://github.com/mihonapp/mihon/blob/master/app/src/main/java/eu/kanade/presentation/browse/components/BaseSourceItem.kt)

候选的维护背景与限制：

| 候选 | 核对结果 | 当前判断 |
| --- | --- | --- |
| [common_locale_data](https://github.com/xvrh/common_locale_data) | 个人仓库，4 stars；2.2.1 已在当前 SDK 运行，最新版 2.4.0 要求 Dart 3.12 | 保留技术验证结果，不再列为首选 |
| [flutter_localized_locales](https://github.com/guidezpl/flutter-localized-locales) | 个人仓库，18 stars；最新发布仍为 2023 年的 2.0.5；完整代码查表，实测部分组合缺失 | 不优先引入 |
| [locale_names](https://github.com/Firelands128/locale_names) | 个人仓库，7 stars；最新发布仍为 2023 年的 1.1.1；需要自行组合名称 | 不优先引入 |
| [intl4x](https://github.com/dart-lang/i18n/tree/main/pkgs/intl4x) | Dart 官方组织仓库，发布者 labs.dart.dev；1.0.1 要求 Dart 3.12，DisplayNames 仍标记 experimental | 后续优先评估官方库与系统接口 |

stars 为 2026-11-14 查询值，只描述项目规模，不作为质量结论。`intl4x` 所在的 `dart-lang/i18n` 仓库有 85 stars，这是整个仓库的数量，不是单个包的数量。

Dart 3.12 是相对当前工程的 SDK 兼容性要求，不是该库不可靠的证据。后续接入时一并评估 SDK 升级、DisplayNames 的实验状态、原生构建依赖和各目标平台；不能仅为避开升级就改选维护基础更弱的包。[版本要求](https://pub.dev/packages/intl4x/versions) · [DisplayNames 状态](https://pub.dev/packages/intl4x/changelog)

此前独立探针的事实仍保留：三个非官方库可在当前 SDK 运行；`common_locale_data 2.2.1` 支持组合名称，但中英文独立 AOT 探针相对基线增加约 1.78 MiB，未知代码还需处理回退。这些均不代表已测得 Flutter 应用体积或已通过页面验收。
