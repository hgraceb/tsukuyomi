## 参考项目

### 核心参考

- 修改应用的核心逻辑和页面布局前，若存在 `packages/tsukuyomi_sources/AGENTS.md`，先读取其中的参考项目说明并按需请求
- 修改 `packages/tsukuyomi_sources/` 前先完整读取并遵守其中的 `AGENTS.md`，通过 `assets/sources` 关联目录修改时同样适用

## 文档格式

### HTML 文档

- 单文件模式、使用夜间模式显示、侧边栏显示可交互的文档目录、高亮显示代码块
- 如果有不同段落需要交叉引用，可以在鼠标悬浮时添加预览窗口，不要求全部显示，但尽可能地显示关联的核心内容
- 多用可视化的说明方式，如图表、图片、卡片、标签、流程图、树状图、预览图、可交互区域等等方式，不要一味地堆砌文本
- 如果涉及前端页面的改动或者影响可以显示页面预览图，不要求完全一比一还原，但是尽量和实际的布局还有颜色的处理差不多
- 按照不同的重要程度安排整体段落，比较次要的内容可以放后面或者适当用小字或者次要颜色显示，特殊显示不同进度相关内容

### AGENTS 文档

- 行内代码一般只放英文标识符、路径或代码，中文说明使用普通文本或中文引号，如：

```markdown
// Bad
`内容语言`使用`语言代码`

// Good
内容语言使用 `languageCode`
```

- 每一条规则都尽量配套单独的 Bad / Good 示例，不同的规则不要共用同一段示例，如：

```markdown
// Bad
- 第一条示例规则
- 第二条示例规则

// Good
- 第一条示例规则
​```dart
// Bad
// 第一条示例规则的错误示例

// Good
// 第一条示例规则的正确示例
​```
- 第二条示例规则
​```dart
// Bad
// 第二条示例规则的错误示例

// Good
// 第二条示例规则的正确示例
​```
```

## 代码评审

### 数据迁移

- 当前开发阶段由维护者整体替换数据库，除非遇到以下命令无法覆盖的情况，否则不必考虑数据库迁移，如：

```dart
final migrator = createMigrator();
for (final table in allTables) {
  await migrator.deleteTable(table.actualTableName);
  await migrator.createTable(table);
}
```

```markdown
// Bad
内置作品改用首话 URL 时，要求编写迁移来合并旧库里的搜索记录并转移阅读进度

// Good
检查新库导入书目后，从搜索打开同一作品会命中已有记录；若此时仍产生重复记录，应当处理
```

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

- 函数签名使用三引号字符串单独成行，与 `DartClass` 保持一致，如：

```dart
// Bad
List<DartDeclaration> get $mangaDetails {
  return [
    DartFunction('normalizeMangaLanguages', normalizeMangaLanguages, 'external List<String> normalizeMangaLanguages(Iterable<String> values);'),
  ];
}

// Good
DartFunction get _$normalizeMangaLanguages => DartFunction('normalizeMangaLanguages', normalizeMangaLanguages, '''
external List<String> normalizeMangaLanguages(Iterable<String> values);
''');

List<DartDeclaration> get $mangaDetails {
  return [
    _$normalizeMangaLanguages,
  ];
}
```

### 文档注释

- 文档注释只写一行简短说明，优先遵循代码即文档的风格，尽量不分段或者补充示例，也不把长说明压成一行，如：

```dart
// Bad
/// 内容语言
///
/// 当前漫画在该源中已知的正文语言代码，例如 `ja`、`zh-Hans`
/// 代码格式由 [normalizeMangaLanguages] 校验
final List<String>? languages;

// Good
/// 内容语言
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

- 链式调用的末尾方法需要多行参数时，优先提取接收对象或参数，避免链式调用和参数同时展开，如：

```dart
// Bad
final id = await container
    .read(mangaServiceProvider)
    .insertSourceManga(
      source,
      const HttpSourceManga(url: 'url', name: 'title', cover: 'cover'),
    );

// Good
final service = container.read(mangaServiceProvider);
final id = await service.insertSourceManga(source, const HttpSourceManga(url: 'url', name: 'title', cover: 'cover'));
```
