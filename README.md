# Tsukuyomi

## 项目简介

基于 Flutter 开发构建的多平台开源漫画阅读器。

## 注意事项

项目处于快速开发期，任何接口和功能随时都可能出现破坏性更改，如有重要数据请自行备份。

## 运行截图

| 应用首页 | 书架页面 | 搜索页面 |
| ------ | ------ | ------ |
| ![应用首页](https://github.com/user-attachments/assets/51a172ed-0567-44a7-83c7-0b151ef46129) | ![书架页面](https://github.com/user-attachments/assets/8b984a54-bb95-4ff7-8d5f-4257aea82790) | ![搜索页面](https://github.com/user-attachments/assets/d34e8521-9101-4053-adc9-d9b68affef67) |

| 搜索结果 | 漫画详情 | 漫画操作 |
| ------ | ------ | ------ |
| ![搜索结果](https://github.com/user-attachments/assets/378c0746-dc1d-4a95-944c-2a39853906a6) | ![漫画详情](https://github.com/user-attachments/assets/c9ce4430-6fba-4e39-bf36-4230b4ce6e2d) | ![漫画操作](https://github.com/user-attachments/assets/58c7a877-b779-4395-aa28-148670ea5ac1) |

| 阅读页面 | 下载页面 | 设置页面 |
| ------ | ------ | ------ |
| ![阅读页面](https://github.com/user-attachments/assets/4cc5034d-842b-4bc3-8615-23831d3238a4) | ![下载页面](https://github.com/user-attachments/assets/13e13808-0c03-4ad4-be5c-7d5d3576f768) | ![设置页面](https://github.com/user-attachments/assets/bc3260d7-df15-42fa-8074-211a6bee3829) |

| 主题预览 | 开发调试 | 列表测试 |
| ------ | ------ | ------ |
| ![主题预览](https://github.com/user-attachments/assets/7a1386c5-dc4d-4675-bde0-d53de8456541) | ![开发调试](https://github.com/user-attachments/assets/52196c74-929b-4fc6-bc34-89e5bba4a0fd) | ![列表测试](https://github.com/user-attachments/assets/1e514ac1-f44c-4032-a645-740fa23d6373) |

| 列表对比 | 页面测试 | 错误测试 |
| ------ | ------ | ------ |
|  ![列表对比](https://github.com/user-attachments/assets/53ee0ff6-d126-4434-a37b-96fe2da1eeb2) | ![页面测试](https://github.com/user-attachments/assets/63fc23f2-4232-43da-9c8a-3aca630d3910) | ![错误测试](https://github.com/user-attachments/assets/28d765a3-193b-4b89-a80e-0a0b40dc0af0) |

## 本地构建

- 生成本地化语言配置

```sh
# Flutter 3.13.9 • channel stable
flutter gen-l10n
```

- 生成本地基础代码

```sh
# Dart SDK version: 3.1.5 (stable)
dart run build_runner build --delete-conflicting-outputs
```

## 免责声明

- 本项目仅用于个人学习和交流，请勿用于任何商业用途，否则后果自负。
- 本项目不托管任何第三方数据，请自行承担访问任何第三方网站的安全和法律风险。
