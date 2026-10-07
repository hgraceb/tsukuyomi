# 代码风格

## 核心规则

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

## 数字格式

- 类型为 `double` 且数值为整数时，优先使用 `.0` 表示浮点数，如：

```dart
// Bad
const EdgeInsets.all(20);

// Good
const EdgeInsets.all(20.0);
```

## 代码换行

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

- 尽量在使用 ?: 表达式的时候内联过长的判断或者处理导致多余的格式化换行，如：

```dart
// Bad
final catching = handler.start <= ip && ip < handler.end
    ? handler.catchings.firstWhereOrNull((catching) => catching.match(exit.error))
    : null;

// Good
final isInTryBody = handler.start <= ip && ip < handler.end;
final catching = isInTryBody ? handler.catchings.firstWhereOrNull((catching) => catching.match(exit.error)) : null;
```

