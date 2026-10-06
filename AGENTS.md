# 代码风格

## Widget 集合中的条件分支

- 在 `children`、`actions`、`slivers` 等 Widget 列表中，条件分支需要换行时，使用 `if (...) ...[...]` 包裹，即使分支只有一个 Widget。有 `else` 时，两侧统一使用 `...[]`。
- 可以清楚地写在一行的分支，保留 `if (condition) Widget(...)` 简写。
- 此规则只适用于集合中的条件元素；普通 `if` 语句和 Widget 属性的条件表达式沿用原有写法。
- 新增或修改相关代码时遵守此规则，不为统一格式批量修改无关文件。修改后运行 `dart format`。

```dart
children: [
  if (running) ...[
    IconButton(
      icon: const Icon(Icons.stop_outlined),
      onPressed: onStop,
    ),
  ] else ...[
    IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: onScan),
  ],
],
```
