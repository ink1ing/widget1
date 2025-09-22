//
//  AppIntent.swift
//  widget-classschedule
//
//  Created by INKLING on 9/19/25.
//

#if canImport(AppIntents)
import WidgetKit
import AppIntents

// MARK: - 刷新课表Intent
@available(iOS 17.0, *)
struct RefreshScheduleIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新课表"
    static var description = IntentDescription("刷新小组件课表数据")
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - 打开饭卡二维码快捷指令
@available(iOS 17.0, *)
struct OpenCardQRIntent: AppIntent {
    static var title: LocalizedStringResource = "饭卡二维码"
    static var description = IntentDescription("打开饭卡二维码页面")
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        if #available(iOS 18.0, *) {
            return .result(opensIntent: OpenURLIntent(URL(string: "henau://card/qr")!))
        } else {
            return .result()
        }
    }
}

#if APP_INTENTS_TARGET
@available(iOS 17.0, *)
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCardQRIntent(),
            phrases: [
                "在\(.applicationName)中打开饭卡二维码",
                "\(.applicationName) 打开饭卡二维码",
                "\(.applicationName) 显示饭卡二维码"
            ],
            shortTitle: "饭卡二维码",
            systemImageName: "qrcode"
        )
    }
}
#endif
#endif
