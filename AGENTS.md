# 代码风格

## 数字格式

- 类型为 `double` 且数值为整数时，优先使用 `.0` 表示浮点数，如：

```dart
// Bad
const EdgeInsets.all(20);

// Good
const EdgeInsets.all(20.0);
```

## 条件分支

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
