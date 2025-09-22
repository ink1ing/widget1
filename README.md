# Widget1 小组件设计与实现说明

本文档整理了当前课表小组件的整体设计、交互细节与核心实现，便于后续维护与扩展。

## 设计总览

- **支持尺寸**：systemSmall / systemMedium / systemLarge，三种尺寸共用一套数据源与标题组件。
- **统一头部**：`headerInfoView` 输出两行信息——第一行加粗显示“第3周”（若无数据默认第3周），第二行展示动态日期 `M.d` + “·” + 当天中文星期，三种尺寸均左对齐显示。
- **功能按钮**：提供“充值 / 付款 / 刷新”三项操作。前两项使用 `Link` 对接校园 APP URL Scheme，刷新在 iOS 17+ 下走 `RefreshScheduleIntent`，并通过 `WidgetPressableButtonStyle` 实现按压变暗 1 秒的反馈，低版本回退到 URL。
- **数据来源**：课表定义在 `Shared/ScheduleModels.swift`，主应用和 Widget Extension 通过 App Group 共享，缺失或版本不一致时自动写入示例数据。

## 数据模型与共享

- `Course`
  - 记录课程简称、教室、周几、节次 (`order`) 与时段 (`TimeSlot`)，方便不同尺寸按节次或时段排序。
  - `location` 会在 Widget 内格式化，提取首个字母并保留后三位数字，形如“E308”。
- `WeekSchedule`
  - 提供 `courses(for:)`、`course(for:period:)` 等方法，支持 Large 尺寸按节次查找课程，中尺寸按当天聚合课程。
- `SharedDataManager`
  - 使用 `UserDefaults(suiteName: "group.cn.henau.app")` 保存课表，并维护 `currentScheduleVersion`，确保示例数据自动更新。
  - 写入数据后调用 `WidgetCenter.shared.reloadAllTimelines()` 触发刷新。
- **示例课表**：按照需求构造第三周周一至周五 1~6 节课程（上午两节、下午两节、晚上两节），如“社组 D309”“习概 C106”“企业 C310”等，覆盖 13 节并留出空档用于占位。

## 三种尺寸的布局

- **Small（`SmallWidgetView`）**
  - 仅包含头部信息与三枚功能按钮，按钮垂直排列并整体靠左，适合作为快捷入口。
- **Medium（`MediumWidgetView`）**
  - 头部信息下方按需展示今日课程：若当日有课，以横向卡片列表显示课程名、教室、时段；若无课显示提示文案。
  - 底部保留一行按钮，与 Small/Large 共享样式，并通过 `Spacer` 将卡片区域与功能按钮自然分隔。
- **Large（`LargeWidgetView`）**
  - 顶部沿用统一头部，下方用五列呈现周一至周五，每列包含 1~6 节。
  - 若有课，则两行文字呈现（第一行课程简称，第二行教室代码）；无课时渲染透明度 0.3 的“—”与空行作为占位，保持列高一致。
  - 底部按钮行包含 `Spacer()`，并将上方间距压缩到 `.padding(.top, 4)`，实现最紧凑布局，同时追加日期信息由头部统一负责。

## 交互与视觉细节

- `actionLabel` 统一按钮尺寸、圆角与字体，确保三枚按钮宽度一致、文字横向排列。
- `WidgetPressableButtonStyle` 仅在支持 App Intent 的环境下生效，使用 `configuration.isPressed` 调整透明度并添加 1 秒缓动动画，营造按压再回弹的视觉效果。
- Large 与 Medium 共享 `courseLines(for:)` 和 `formattedRoom(for:)`，保证教室缩写、无课占位的逻辑一致。
- `currentWeekday()` 将 iOS 默认的周日=1 转换为“周一=1…周日=7”，保证标题与课程匹配。

## 构建与验证

```bash
xcodebuild -scheme Widget1 -project Widget1.xcodeproj -destination 'generic/platform=iOS' build
```

以上命令用于本地验证主 App 与 Widget Extension 能正常编译；刷新 Intent 需在真机或支持 App Intents 的模拟器上测试。

## 后续扩展建议

- 接入真实课表时，可通过 `SharedDataManager.save(schedule:)` 写入最新数据，Widget 将自动刷新。
- 若需更多功能按钮，可扩展 `WidgetActionDestination`，或在 Intent 中增加参数以支持快捷操作。
- 可继续优化视觉（如引入配色/图标、动态背景），或为 ExtraLarge / Lock Screen 等尺寸扩展布局。
