## 参考项目

### 核心参考

- 修改应用的核心逻辑和页面布局前，若存在 `packages/tsukuyomi_sources/AGENTS.md`，先读取其中的参考项目说明并按需请求
- 修改 `packages/tsukuyomi_sources/` 前先完整读取并遵守其中的 `AGENTS.md`，通过 `assets/sources` 关联目录修改时同样适用

## 文档格式

### AGENTS 文档

- 行内代码一般只放英文标识符、路径或代码，中文说明使用普通文本或中文引号，如：

```markdown
Bad: `内容语言`使用`语言代码`
Good: 内容语言使用 `languageCode`
```

- 每条规则尽量配套 Bad / Good 示例，紧密相关的规则可以共用一组示例，如：

```text
Bad: 只写“遵守现有声明风格”
Good: 说明使用独立 getter，并展示内联声明与独立声明的对照
```

- 一条规则只说一件事，视觉长度参考相邻短规则，以常用 Typora 宽度下不折行为目标
- 不设固定字符数；过长时先删赘述，再拆分独立规则，不为凑宽度硬换行，如：

```markdown
Bad: 字段注释需要首先概括字段的含义，然后在后面补充说明，共同的规则可以放在类注释里，引用标识符时还需要使用对应格式
Good:
- 字段注释先概括含义，补充说明另起一段
- 共同规则写在类注释中，标识符使用 [identifier] 引用
```

### HTML 文档

- 单文件模式、使用夜间模式显示、侧边栏显示可交互的文档目录、高亮显示代码块
- 如果有不同段落需要交叉引用，可以在鼠标悬浮时添加预览窗口，不要求全部显示，但尽可能地显示关联的核心内容
- 多用可视化的说明方式，如图表、图片、卡片、标签、流程图、树状图、预览图、可交互区域等等方式，不要一味地堆砌文本
- 如果涉及前端页面的改动或者影响可以显示页面预览图，不要求完全一比一还原，但是尽量和实际的布局还有颜色的处理差不多
- 按照不同的重要程度安排整体段落，比较次要的内容可以放后面或者适当用小字或者次要颜色显示，特殊显示不同进度相关内容

## 代码风格

### 核心规则

- 保持代码一致性，优先参考相近层级下的代码风格，遵守没有明文规定但是从现有代码可以推测出的默认代码风格，如：

```dart
// Bad
// 中文代码注释，末尾添加中文句号。

// Good
// 中文代码注释，默认不加末尾句号
```

```dart
// Bad: 在 eval 子目录的单元测试中使用 isNull 进行测试
await expectLater(() => eval(source), isNull);

// Good: 在 eval 子目录的单元测试中优先使用 println 进行测试，isNull 在此子目录一般不用于直接验证中间结果
await expectLater(() => eval(source), println([null]));
```

```dart
// Bad: 随机放置 class、riverpod、freezed 等定义的顺序
@freezed
class DownloadEnqueueResult with _$DownloadEnqueueResult {
  const factory DownloadEnqueueResult({
    @Default(0) int count,
  }) = _DownloadEnqueueResult;
}

@riverpod
DownloadService downloadService(DownloadServiceRef ref) {
  return DownloadService._(ref: ref);
}

class DownloadService {
  DownloadService._({required this.ref});

  final DownloadServiceRef ref;
}

// Good: 参考现有 class、riverpod、freezed 相关文件的定义顺序
class DownloadService {
  DownloadService._({required this.ref});

  final DownloadServiceRef ref;
}

@riverpod
DownloadService downloadService(DownloadServiceRef ref) {
  return DownloadService._(ref: ref);
}

@freezed
class DownloadEnqueueResult with _$DownloadEnqueueResult {
  const factory DownloadEnqueueResult({
    @Default(0) int count,
  }) = _DownloadEnqueueResult;
}
```

### 桥接声明

- `DartFunction` 使用独立 getter，命名为 `_$functionName`，声明列表只引用 getter
- 函数签名使用三引号字符串单独成行，与 `DartClass` 保持一致，如：

```dart
// Bad
List<DartDeclaration> get $mangaDetails {
  return [
    DartFunction('normalizeMangaStatus', normalizeMangaStatus, 'external String normalizeMangaStatus(String value);'),
  ];
}

// Good
DartFunction get _$normalizeMangaStatus => DartFunction('normalizeMangaStatus', normalizeMangaStatus, '''
external String normalizeMangaStatus(String value);
''');

List<DartDeclaration> get $mangaDetails {
  return [
    _$normalizeMangaStatus,
  ];
}
```

### 文档注释

- 字段注释先概括含义，如“内容语言”，补充说明前留一个空的 `///` 行
- 共同规则写在类注释中，各字段只补充自身语义
- 字面量使用反引号，代码标识符使用 `[identifier]` 引用，如：

```dart
// Bad
/// 当前源中该漫画已知的内容语言，null 表示未提供，空列表表示未知
final List<String>? languages;

// Good: 共同的 null 与空值规则已在类注释中说明
/// 内容语言
///
/// 当前漫画在该源中已知的正文语言代码，例如 `ja`、`zh-Hans`
/// 代码格式由 [normalizeMangaLanguages] 统一规范
final List<String>? languages;
```

### 数字格式

- 类型为 `double` 且数值为整数时，优先使用 `.0` 表示浮点数，如：

```dart
// Bad
const EdgeInsets.all(20);

// Good
const EdgeInsets.all(20.0);
```

### 代码换行

- 单行代码的 `// ignore:` 注释统一放在对应代码行末尾，不单独换行，避免打断连续的 `import` 等语句，如：

```dart
// Bad
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

// Good
import 'package:sqlite3/open.dart'; // ignore: depend_on_referenced_packages
```

- 定义 Widget 字段时优先使用换行进行分割，增强代码的可阅读性，如：

```dart
// Bad
class Foo {
  Foo({required this.bar, required this.baz});

  final int bar;
  final String baz;
}

// Good
class Foo {
  Foo({required this.bar, required this.baz});

  final int bar;

  final String baz;
}
```

- 优先使用 ...[] 语法与组件内部的 if 进行配合使用对齐代码，增强代码的可阅读性，如：

```dart
// Bad
Row(
  children: [
    if (title case final title?)
      Text(title),
  ],
);

// Good
Row(
  children: [
    if (title case final title?) ...[
      Text(title),
    ],
  ],
);
```

- 优先使用 ...{} 语法与代码内部的 if 进行配合使用对齐代码，增强代码的可阅读性，如：

```dart
// Bad: for 和 if 的层级不易于阅读
return (
  positionalCallbacks: {
    for (var i = 0; i < positional.length; i++)
      if (positional[i].type is FunctionType) i,
  },
);

// Bad: 没有触发换行规则的时候为 i 添加了多余的 ...{} 层级显示
return (
  positionalCallbacks: {
    for (var i = 0; i < positional.length; i++) ...{
      if (positional[i].type is FunctionType) ...{
        i,
      },
    },
  },
);

// Good: 使用 ...{} 语法显示正确的层级
return (
  positionalCallbacks: {
    for (var i = 0; i < positional.length; i++) ...{
      if (positional[i].type is FunctionType) i,
    },
  },
);
```

- 在使用 ?: 表达式的时候尽量避免内联过长的判断或者处理导致多余的格式化换行，如：

```dart
// Bad
final catching = handler.start <= ip && ip < handler.end
    ? handler.catchings.firstWhereOrNull((catching) => catching.match(exit.error))
    : null;

// Good
final isInTryBody = handler.start <= ip && ip < handler.end;
final catching = isInTryBody ? handler.catchings.firstWhereOrNull((catching) => catching.match(exit.error)) : null;
```

- 在使用链式表达式的时候尽量避免内联过长的判断或者处理导致多余的格式化换行，如：

```dart
// Bad
final unsupportedClasses = declarations
    .where((e) => e.hasUnsupportedTypeRelations || hasUnsupportedSuperclassAlias(e))
    .map((e) => e.declaredElement)
    .toSet();

// Good
final unsupportedDeclarations = declarations.where((e) => e.hasUnsupportedTypeRelations || hasUnsupportedSuperclassAlias(e));
final unsupportedClasses = unsupportedDeclarations.map((e) => e.declaredElement).toSet();
```
