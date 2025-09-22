//
//  widget_classschedule.swift
//  widget-classschedule
//
//  Created by INKLING on 9/19/25.
//

import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - Widget Entry
struct ClassScheduleEntry: TimelineEntry {
    let date: Date
    let schedule: WeekSchedule?
}

// MARK: - Widget Provider
struct ClassScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClassScheduleEntry {
        ClassScheduleEntry(date: Date(), schedule: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ClassScheduleEntry) -> Void) {
        let entry = ClassScheduleEntry(
            date: Date(),
            schedule: SharedDataManager.shared.loadSchedule()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassScheduleEntry>) -> Void) {
        let currentDate = Date()
        let schedule = SharedDataManager.shared.loadSchedule()
        
        let entry = ClassScheduleEntry(
            date: currentDate,
            schedule: schedule
        )
        
        let nextUpdate = nextWidgetRefreshDate(after: currentDate)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}

// 计算下一个刷新时间，确保上午/下午/晚上切换即时生效
private func nextWidgetRefreshDate(after date: Date) -> Date {
    let calendar = Calendar.current
    let boundaryHours = [12, 18, 22]

    let nextBoundary = boundaryHours
        .compactMap { hour -> Date? in
            calendar.nextDate(after: date, matching: DateComponents(hour: hour, minute: 0), matchingPolicy: .nextTime, direction: .forward)
        }
        .min()

    if let nextBoundary {
        return nextBoundary
    }

    // 回退到次日零点，至少每日刷新一次
    return calendar.nextDate(after: date, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime, direction: .forward) ?? date.addingTimeInterval(3600)
}

// MARK: - Widget View
struct ClassScheduleWidgetView: View {
    var entry: ClassScheduleProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - 小尺寸Widget
struct SmallWidgetView: View {
    let entry: ClassScheduleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerInfoView(weekNumber: entry.schedule?.weekNumber ?? 0)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                actionButton(title: "充值", icon: "creditcard", tint: .blue, action: .url("henau://card/recharge"))
                actionButton(title: "付款", icon: "qrcode", tint: .green, action: .url("henau://card/qr"))
                actionButton(title: "刷新", icon: "arrow.clockwise", tint: .orange, action: .refresh)
            }
        }
        .padding()
    }
}

// MARK: - 中等尺寸Widget
struct MediumWidgetView: View {
    let entry: ClassScheduleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let schedule = entry.schedule {
                let todayWeekday = currentWeekday()
                let dayCourses = schedule.courses(for: todayWeekday)
                let periodText = dayPeriod(for: Date())

                headerInfoView(weekNumber: schedule.weekNumber, period: periodText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !dayCourses.isEmpty {
                    let limitedCourses = Array(dayCourses.prefix(2))

                    let columns = [
                        GridItem(.flexible(minimum: 120), spacing: 12, alignment: .top),
                        GridItem(.flexible(minimum: 120), spacing: 12, alignment: .top)
                    ]

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ForEach(limitedCourses) { course in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(course.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Text("\(formattedRoom(for: course.location)) · \(course.timeDescription)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                } else {
                    Text("今日无课程安排")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("暂无课表数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                actionButton(title: "充值", icon: "creditcard", tint: .blue, action: .url("henau://card/recharge"))
                actionButton(title: "付款", icon: "qrcode", tint: .green, action: .url("henau://card/qr"))
                actionButton(title: "刷新", icon: "arrow.clockwise", tint: .orange, action: .refresh)
            }
            .padding(.top, 0)
        }
        .padding()
    }
}

// MARK: - 大尺寸Widget
struct LargeWidgetView: View {
    let entry: ClassScheduleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerInfoView(weekNumber: entry.schedule?.weekNumber ?? 0)

            if let schedule = entry.schedule {
                let weekdays = Array(1...5)

                let periods = Array(1...6)

                HStack(alignment: .top, spacing: 16) {
                    ForEach(weekdays, id: \.self) { weekday in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(weekdayDisplayName(weekday))
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            ForEach(periods, id: \.self) { period in
                                if let course = schedule.course(for: weekday, period: period) {
                                    let lines = courseLines(for: course)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lines.title)
                                            .font(.caption2)
                                            .foregroundStyle(.primary)
                                        Text(lines.room)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("—")
                                            .font(.caption2)
                                            .foregroundColor(.secondary.opacity(0.3))
                                        Text(" ")
                                            .font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 30, alignment: .leading)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack(spacing: 14) {
                    actionButton(title: "充值", icon: "creditcard", tint: .blue, action: .url("henau://card/recharge"))
                    actionButton(title: "付款", icon: "qrcode", tint: .green, action: .url("henau://card/qr"))
                    actionButton(title: "刷新", icon: "arrow.clockwise", tint: .orange, action: .refresh)
                    Spacer()
                }
                .padding(.top, 4)
            } else {
                Text("暂无课表数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - 新增大尺寸（横向今日课表）
struct LargeDailyWidgetView: View {
    let entry: ClassScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerInfoView(weekNumber: entry.schedule?.weekNumber ?? 0)

            if let schedule = entry.schedule {
                let todayWeekday = currentWeekday()
                let dayCourses = schedule.courses(for: todayWeekday)

                if dayCourses.isEmpty {
                    Text("今日无课程安排")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    let columns = [
                        GridItem(.adaptive(minimum: 120, maximum: 170), spacing: 12, alignment: .top)
                    ]

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ForEach(dayCourses) { course in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(course.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Text(formattedRoom(for: course.location))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Text(course.timeDescription)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 14) {
                    actionButton(title: "充值", icon: "creditcard", tint: .blue, action: .url("henau://card/recharge"))
                    actionButton(title: "付款", icon: "qrcode", tint: .green, action: .url("henau://card/qr"))
                    actionButton(title: "刷新", icon: "arrow.clockwise", tint: .orange, action: .refresh)
                    Spacer()
                }
                .padding(.top, 4)
            } else {
                Text("暂无课表数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Widget Configuration
struct ClassScheduleWidget: Widget {
    let kind: String = "ClassScheduleWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClassScheduleProvider()) { entry in
            if #available(iOS 17.0, *) {
                ClassScheduleWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ClassScheduleWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("课表小组件")
        .description("显示本周课表和饭卡快捷入口")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ClassScheduleDailyWidget: Widget {
    let kind: String = "ClassScheduleDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClassScheduleProvider()) { entry in
            if #available(iOS 17.0, *) {
                LargeDailyWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LargeDailyWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("今日课表横排")
        .description("查看当天所有课程与时间安排")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - 公共组件
@ViewBuilder
private func headerInfoView(weekNumber: Int, period: String? = nil) -> some View {
    let weekValue = weekNumber > 0 ? weekNumber : 3
    let weekText = "第\(weekValue)周"
    let dateText = formattedDate()
    let weekdayText = weekdayDisplayName(currentWeekday())
    let periodSuffix = period.map { " · \($0)" } ?? ""

    VStack(alignment: .leading, spacing: 2) {
        Text(weekText)
            .font(.headline)
            .fontWeight(.bold)
        Text("\(dateText) · \(weekdayText)\(periodSuffix)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

private enum WidgetActionDestination {
    case url(String)
    case refresh
}

@ViewBuilder
private func actionButton(title: String, icon: String, tint: Color, action: WidgetActionDestination) -> some View {
    switch action {
    case .url(let urlString):
        if let url = URL(string: urlString) {
            Link(destination: url) {
                actionLabel(title: title, icon: icon, tint: tint)
                    .background(tint.opacity(0.15))
                    .cornerRadius(8)
            }
        }
    case .refresh:
        if #available(iOS 17.0, *), canUseAppIntents {
            Button(intent: RefreshScheduleIntent()) {
                actionLabel(title: title, icon: icon, tint: tint)
            }
            .buttonStyle(WidgetPressableButtonStyle(tint: tint))
        } else if let url = URL(string: "henau://schedule/refresh") {
            Link(destination: url) {
                actionLabel(title: title, icon: icon, tint: tint)
                    .background(tint.opacity(0.15))
                    .cornerRadius(8)
            }
        }
    }
}

@ViewBuilder
private func actionLabel(title: String, icon: String, tint: Color) -> some View {
    Label {
        Text(title)
            .font(.caption2)
            .fontWeight(.semibold)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    } icon: {
        Image(systemName: icon)
            .font(.caption)
    }
    .labelStyle(.titleAndIcon)
    .frame(minWidth: 52, alignment: .center)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .foregroundColor(tint)
}

private var canUseAppIntents: Bool {
    #if APP_INTENTS_TARGET
    true
    #else
    false
    #endif
}

private func currentWeekday() -> Int {
    let today = Calendar.current.component(.weekday, from: Date())
    let weekday = today == 1 ? 7 : today - 1
    return min(max(weekday, 1), 7)
}

private func weekdayDisplayName(_ weekday: Int) -> String {
    let names = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    return names.indices.contains(weekday) ? names[weekday] : ""
}

private func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M.d"
    return formatter.string(from: Date())
}

private func dayPeriod(for date: Date) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    if hour >= 22 || hour < 12 {
        return "上午"
    } else if hour < 18 {
        return "下午"
    } else {
        return "晚上"
    }
}

private func courseLines(for course: Course) -> (title: String, room: String) {
    let title = course.name.count > 2 ? String(course.name.prefix(2)) : course.name
    let room = formattedRoom(for: course.location)
    return (title, room)
}

private func formattedRoom(for location: String) -> String {
    let alphanumerics = location.filter { $0.isLetter || $0.isNumber }
    guard !alphanumerics.isEmpty else { return location }

    let letters = alphanumerics.filter { $0.isLetter }
    let digits = alphanumerics.filter { $0.isNumber }

    let letterPart = letters.isEmpty ? "" : String(letters.prefix(1)).uppercased()
    let numberPart = digits.isEmpty ? "" : String(digits.suffix(3))

    return letterPart + numberPart
}

@available(iOS 17.0, *)
private struct WidgetPressableButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(tint.opacity(configuration.isPressed ? 0.4 : 0.15))
            .cornerRadius(8)
            .animation(.easeOut(duration: 1.0), value: configuration.isPressed)
    }
}
