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

本次比较了运行时代码、数据生成、平台适配、异常回退、测试和构建流程，并在独立目录运行边界探针。审查版本为 `common_locale_data 2.4.0`、`intl4x 1.0.1` / `icu4x 2.3.2`、`flutter_localized_locales 2.0.5`、`locale_names 1.1.1`；旧版 `common_locale_data 2.2.1` 的兼容性和体积记录单独保留。

**当前建议：漫画语言名称显示采用应用层封装的 `common_locale_data`，暂不接入 `intl4x` 的 `DisplayNames`，不选另外两个旧库。** 这是针对当前功能的选型建议，尚未添加依赖或修改应用实现。判断依据是代码与复现结果，不是 stars，也不是仅看 SDK 是否兼容。

先明确显示需求：漫画详情优先使用“中文”“简体中文”“繁体中文”“日语”等短名称。地区只在需要区分版本时展示，存储完整代码不要求页面展开全部子标记。

Mihon 的处理已核对本地参考代码：

- 漫画源列表取 `source.lang`，由 `LocaleHelper.getSourceDisplayName` 调用 Android/Java 的 `Locale.getDisplayName`，普通语言名称使用该语言自身的写法
- `zh-CN`、`zh-TW` 在生成名称前分别转为 `zh-Hans`、`zh-Hant`，不保留其中的地区部分；并不会主动给所有语言补充地区
- 参考源 Mikagogo 在 `build.gradle.kts` 中实际配置 `lang = "zh"`，不包含文字或地区子标记
- 之前的“繁体中文（中国香港特别行政区）”来自向测试库传入 `zh-Hant-HK`，不是 Mihon 的界面实测，也不作为本应用的默认展示方案

[名称处理源码](https://github.com/mihonapp/mihon/blob/master/app/src/main/java/eu/kanade/tachiyomi/util/system/LocaleHelper.kt) · [源列表显示源码](https://github.com/mihonapp/mihon/blob/master/app/src/main/java/eu/kanade/presentation/browse/components/BaseSourceItem.kt)

#### 代码质量比较

| 候选 | 实现与工程保障 | 当前判断 |
| --- | --- | --- |
| [common_locale_data](https://github.com/xvrh/common_locale_data) | 生成数据与手写算法分离；常量表、按语言拆分、继承复用；有 CLDR 标准样例和分析、测试 CI | 实现有章法，当前显示功能首选；要接受个人维护、数据版本和体积的代价 |
| [intl4x](https://github.com/dart-lang/i18n/tree/main/pkgs/intl4x) | 原生使用 ICU4X，Web 使用平台 `Intl`；FFI 生命周期管理、二进制校验、多系统和 Web/Wasm CI 较完整 | 基础架构更完整，但实测 `DisplayNames` 的空值、回退和平台一致性仍有缺口 |
| [flutter_localized_locales](https://github.com/guidezpl/flutter-localized-locales) | 小型 JSON 查表封装，职责简单；资源加载走 Flutter 缓存；有 9 个基础测试 | 固定语言菜单可以使用；组合名称、资源体积和配置重载不适合当前需求 |
| [locale_names](https://github.com/Firelands128/locale_names) | 大量生成表加少量扩展方法；查找时反复复制、合并表；公开可变全局数据；只有 3 个测试块 | 封装和边界处理较弱，不推荐作为语言显示基础库 |

以上评价针对代码体现的工程质量，不据此判断作者其他项目的水平，也不表示已经排除所有隐藏缺陷。

#### common_locale_data：可以使用，但要守住调用边界

值得肯定的是数据与逻辑分层清楚，生成器固定上游版本，语言区域数据使用继承减少重复，并提供按语言导入和静态访问入口。手写部分实现解析、规范化和名称组合；测试包含来自 Unicode CLDR 的输入与期望值，而不只是几个正常示例。[生成配置](https://github.com/xvrh/common_locale_data/blob/master/tool/config.dart) · [名称格式化](https://github.com/xvrh/common_locale_data/blob/master/lib/src/locale_display_name.dart) · [标准样例测试](https://github.com/xvrh/common_locale_data/blob/master/test/locale_display_name_file_test.dart)

本次复制发布包中的三个测试文件到独立工程运行：`locale_test.dart`、`locale_display_name_test.dart`、`locale_display_name_file_test.dart`。结果为 **2267 项通过、17 项按上游说明跳过**；跳过原因是 16 项 `root` 不支持、1 项泰语名称大小写差异。这不是整个库的测试总数，也不等于完整标准符合性认证。

需要承担的限制：

- **解析成功不等于输入合法**：`LanguageId.parse('en--US')` 不抛异常，`isWellFormed` 为 `false`，但直接格式化仍得到 `English`。解析器保留无法解析的尾部，规范化会丢弃它，这是有说明的宽松设计；不能把名称格式化当作漫画源输入校验
- **新包版本不代表新数据**：2.4.0 仍使用 CLDR 46；当前更新增加了其他功能，没有同步把语言数据升级到最新 CLDR
- **体积需要控制**：只导入实际支持的界面语言，避免 `common_locale_data_all.dart`；动态名称组合仍会保留相关表。此前 2.2.1 的中英文独立 AOT 探针较基线约增加 1.78 MiB，这不是 2.4.0 或 Flutter 安装包的测量结果
- **维护与验证范围有限**：主要是个人维护；已查看的主 CI 使用 Ubuntu 和 stable SDK，耗时测试默认有跳过设置，没有 `intl4x` 那样的多系统验证矩阵

[解析实现](https://github.com/xvrh/common_locale_data/blob/master/lib/src/locale_id/base_language_id.dart) · [CI](https://github.com/xvrh/common_locale_data/blob/master/.github/workflows/analyze-and-test.yaml) · [长测试配置](https://github.com/xvrh/common_locale_data/blob/master/dart_test.yaml)

#### intl4x：工程基础较强，DisplayNames 仍未成熟

设计上没有另造一套完整国际化算法：原生桥接 ICU4X，Web 桥接 `Intl.DisplayNames`。原生绑定使用 `NativeFinalizer` 和存活引用管理资源，下载的二进制与缓存均校验固定 SHA-256；官方 CI 覆盖 Windows、macOS、Linux，以及 Chrome、Wasm、编译运行和产物体积。它们说明团队重视工程保障，但不能替代具体 API 的正确性检查。[平台适配](https://github.com/dart-lang/i18n/blob/main/pkgs/intl4x/lib/src/display_names/display_names_4x.dart) · [CI](https://github.com/dart-lang/i18n/blob/main/.github/workflows/intl4x.yml)

独立探针对相同 API 在 Windows 原生和 Dart 编译的 JavaScript 中各运行 61 个用例。下表的 Web 结果来自 Node 24.10.0 / ICU 77.1 / CLDR 47.0，不代表所有浏览器版本：

| 输入与设置 | Windows / ICU4X | JavaScript / Intl | 判断 |
| --- | --- | --- | --- |
| 英文界面，`qaa`，`Fallback.none` | 返回 `qaa` | 抛 `TypeError`，空值不能转成 `String` | 已复现的契约与平台差异 |
| 英文界面，地区 `XY`，默认 `Fallback.code` | 返回空字符串 | 返回 `XY` | 原生回退不符合返回代码的 API 说明 |
| 界面语言 `dsb`，显示 `ja` | 创建格式化器时抛 `DataError.identifierNotFound` | 返回 `japańšćina` | 支持数据与回退路径不同，需要显式处理 |
| 中文界面，`zh-Hant`，默认选项 | 现代标准汉语（繁体） | 繁体中文 | 命名数据差异，不应直接作为统一界面文案 |

第一个问题能直接定位到代码：Web 桥接将 `.of()` 声明为非空 `String`，而 ECMA 规范规定无名称且 `fallback = none` 时返回 `undefined`；公开的 Dart `ofLocale()` 也返回非空 `String`，与 `Fallback.none` 的“返回 null”注释相冲突。这里是可以复现的接口设计缺口，不是根据 issue 猜测。[Web 实现](https://github.com/dart-lang/i18n/blob/main/pkgs/intl4x/lib/src/display_names/display_names_ecma.dart) · [选项定义](https://github.com/dart-lang/i18n/blob/main/pkgs/intl4x/lib/src/display_names/display_names_options.dart) · [ECMA 规范](https://tc39.es/ecma402/#sec-intl.displaynames.prototype.of)

另外有三个需要注意的设计点：

- Web 每次查名称都会新建一个底层 `Intl.DisplayNames`，原生则复用格式化器；这是可避免的重复工作，本次没有测量它对页面帧率的影响
- 普通测试环境默认返回 `ja//en` 这样的占位字符串，须用 `intl4x.brittle_i18n_testing=true` 或指定 Zone 开启真实格式化。上游测试已经主动开启，本次运行其 12 项显示名称测试全部通过；这些测试没有覆盖上述未知值回退问题
- ICU4X 构建 hook 首次需要下载原生库。本机在默认下载处停滞，源码中没有显式代理或超时配置；使用现有代理下载同一官方文件、核对固定 SHA-256 并放入构建缓存后，探针正常运行。此结果说明本环境有接入成本，不代表所有环境都会失败

[测试模式](https://github.com/dart-lang/i18n/blob/main/pkgs/intl4x/lib/src/test_checker.dart) · [显示名称测试](https://github.com/dart-lang/i18n/blob/main/pkgs/intl4x/test/display_names_test.dart)

包整体已进入 preview，`DisplayNames` 仍明确标记 experimental。因此当前不选它的主要原因是上述实测问题；Dart 3.12 的要求只是接入条件，不能作为质量差的证据。[发布说明](https://pub.dev/packages/intl4x/changelog)

#### 两个旧库：区分简单设计与实际缺陷

`flutter_localized_locales` 的约百行运行时封装本身容易理解：按界面语言加载 JSON，然后做精确查表。它适合列出预先已知的语言，而不是组合任意合法语言代码。`nameOf()` 不规范化参数，调用方要处理下划线键名；未收录的组合返回 `null`。包声明打包整个数据目录，本次统计为 563 个 JSON、约 15.1 MiB 未压缩数据，不能据此直接推算安装包增量。

已复现的缺陷是 `shouldReload()` 恒为 `false`：同一个界面语言下把 delegate 的 `bundle` 换成另一份名称数据，Widget 仍显示旧名称；`fallbackLocale` 变化也不会要求重载。测试用例实际执行了两次 `pumpWidget` 验证。这不是切换正常界面语言必然失效，问题仅针对 delegate 配置变化。[实现](https://github.com/guidezpl/flutter-localized-locales/blob/main/lib/flutter_localized_locales.dart)

`locale_names` 的主要问题集中在封装：

- 查询自名或指定显示语言时，`_load()` 每次都复制英文表，并递归合并目标语言表，没有缓存；默认英文名称查询直接读表，不经过这个复制过程
- `tables` 是公开、可替换的 `Map<String, dynamic>`；外部修改会影响后续使用该表的查询，类型约束和状态隔离较弱
- 实测 `en` 的默认语言名称为 `English`，但 `en-Latn` 的 `defaultDisplayLanguageScript` 返回空字符串，没有退回已知基础语言
- 3 个测试块只验证少量正常名称，没有覆盖这些组合、未知值和状态边界

[查表和回退实现](https://github.com/Firelands128/locale_names/blob/master/lib/locale_names.dart) · [测试](https://github.com/Firelands128/locale_names/blob/master/test/locale_names_test.dart)

两个库的最新发布仍分别是 2023 年的 2.0.5、1.1.1。版本较老不直接说明代码差；这里不选它们，是因为实现边界、复现结果和当前需求不匹配。

#### 应用接入建议与验证边界

1. 漫画源继续输出经过现有规则校验的语言代码，显示库只放在应用层，不把库的类型写进漫画模型或数据库
2. 使用 `common_locale_data` 提供基础名称，只加载应用实际支持的界面语言；输入校验继续由现有标准化入口负责
3. 短名称由产品规则确定：`zh` 显示“中文”，`zh-Hans` 显示“简体中文”，`zh-Hant` 显示“繁体中文”；完整的 `zh-Hant-HK` 仍保存在数据中，只有需要区分版本时才额外展示地区，不能因显示简称而合并不同原始代码
4. 未收录语言回退到原始代码；显示查询按界面语言和内容代码缓存，语言切换后使用对应缓存结果，不把格式化结果持久化
5. 锁定依赖版本，升级时验证短名称、未知值、界面语言切换和目标平台；不把第三方格式化器的任意输出直接当作最终产品文案

`common_locale_data 2.4.0` 和 `intl4x 1.0.1` 都要求 Dart 3.12。本次使用本机已有的 Dart 3.13.1 在临时目录测试；工程仍使用原 SDK，依赖与锁文件未改。后续接入 2.4.0 需安排 SDK 升级，不建议仅为避开升级就长期停留在旧版本。

本次实际验证包括 Windows Dart VM、JavaScript/Node 探针、4 项旧库行为复现、上述上游相关测试；未做 Android/iOS 安装、浏览器/Wasm 实机验收，也未测量新版本在完整 Flutter 应用中的体积与渲染性能。源代码审查和测试能够定位具体风险，不能保证整个库不存在隐藏缺陷。
