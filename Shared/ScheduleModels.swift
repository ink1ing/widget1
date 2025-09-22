import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct Course: Identifiable, Codable {
    enum TimeSlot: String, Codable, CaseIterable {
        case morning
        case afternoon
        case evening

        var displayName: String {
            switch self {
            case .morning:
                return "上午"
            case .afternoon:
                return "下午"
            case .evening:
                return "晚上"
            }
        }
    }

    let id: UUID
    let name: String
    let location: String
    let weekday: Int
    let timeDescription: String
    let teacher: String?
    let order: Int
    let timeSlot: TimeSlot

    init(
        id: UUID = UUID(),
        name: String,
        location: String,
        weekday: Int,
        timeDescription: String,
        teacher: String? = nil,
        order: Int,
        timeSlot: TimeSlot
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.weekday = weekday
        self.timeDescription = timeDescription
        self.teacher = teacher
        self.order = order
        self.timeSlot = timeSlot
    }
}

struct WeekSchedule: Codable {
    let weekNumber: Int
    private let coursesStorage: [Course]

    init(weekNumber: Int, courses: [Course]) {
        self.weekNumber = weekNumber
        self.coursesStorage = courses
    }

    var courses: [Course] {
        coursesStorage
    }

    func coursesForWeekday(_ weekday: Int) -> [Course] {
        courses(for: weekday)
    }

    func courses(for weekday: Int, slot: Course.TimeSlot? = nil) -> [Course] {
        coursesStorage
            .filter { course in
                course.weekday == weekday && (slot == nil || course.timeSlot == slot)
            }
            .sorted { lhs, rhs in
                if lhs.timeSlot == rhs.timeSlot {
                    return lhs.order < rhs.order
                }
                return lhs.timeSlot.sortOrder < rhs.timeSlot.sortOrder
            }
    }

    func course(for weekday: Int, period: Int) -> Course? {
        coursesStorage.first { $0.weekday == weekday && $0.order == period }
    }
}

private extension Course.TimeSlot {
    var sortOrder: Int {
        switch self {
        case .morning: return 0
        case .afternoon: return 1
        case .evening: return 2
        }
    }
}

final class SharedDataManager {
    static let shared = SharedDataManager()

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let scheduleKey = "weekSchedule"
    private let scheduleVersionKey = "weekScheduleVersion"
    private let currentScheduleVersion = 2

    init(userDefaults: UserDefaults = UserDefaults(suiteName: "group.cn.henau.app") ?? .standard) {
        self.userDefaults = userDefaults
    }

    func save(schedule: WeekSchedule) {
        guard let data = try? encoder.encode(schedule) else {
            return
        }

        userDefaults.set(data, forKey: scheduleKey)
        userDefaults.set(currentScheduleVersion, forKey: scheduleVersionKey)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    func loadSchedule() -> WeekSchedule? {
        let storedVersion = userDefaults.integer(forKey: scheduleVersionKey)
        if storedVersion != currentScheduleVersion {
            return resetToSample()
        }

        guard let data = userDefaults.data(forKey: scheduleKey) else {
            return resetToSample()
        }

        if let schedule = try? decoder.decode(WeekSchedule.self, from: data) {
            return schedule
        }

        return resetToSample()
    }

    @discardableResult
    private func resetToSample() -> WeekSchedule {
        let sample = WeekSchedule.sample
        if let sampleData = try? encoder.encode(sample) {
            userDefaults.set(sampleData, forKey: scheduleKey)
            userDefaults.set(currentScheduleVersion, forKey: scheduleVersionKey)
        }
        return sample
    }
}

extension WeekSchedule {
    static var sample: WeekSchedule {
        WeekSchedule(
            weekNumber: 3,
            courses: [
                Course(
                    name: "社会组织",
                    location: "D309",
                    weekday: 1,
                    timeDescription: "08:00-09:40",
                    teacher: nil,
                    order: 1,
                    timeSlot: .morning
                ),
                Course(
                    name: "社会伦理",
                    location: "E308",
                    weekday: 1,
                    timeDescription: "10:00-11:40",
                    teacher: nil,
                    order: 2,
                    timeSlot: .morning
                ),
                Course(
                    name: "心理学导论",
                    location: "E303",
                    weekday: 1,
                    timeDescription: "14:00-15:40",
                    teacher: nil,
                    order: 3,
                    timeSlot: .afternoon
                ),
                Course(
                    name: "宠物护理",
                    location: "D102",
                    weekday: 1,
                    timeDescription: "19:00-20:30",
                    teacher: nil,
                    order: 5,
                    timeSlot: .evening
                ),
                Course(
                    name: "形势与政策",
                    location: "C106",
                    weekday: 2,
                    timeDescription: "08:00-09:40",
                    teacher: nil,
                    order: 1,
                    timeSlot: .morning
                ),
                Course(
                    name: "社会老年学",
                    location: "E311",
                    weekday: 2,
                    timeDescription: "14:00-15:40",
                    teacher: nil,
                    order: 3,
                    timeSlot: .afternoon
                ),
                Course(
                    name: "社会组织",
                    location: "D301",
                    weekday: 3,
                    timeDescription: "08:00-09:40",
                    teacher: nil,
                    order: 1,
                    timeSlot: .morning
                ),
                Course(
                    name: "社会政策",
                    location: "E308",
                    weekday: 3,
                    timeDescription: "10:00-11:40",
                    teacher: nil,
                    order: 2,
                    timeSlot: .morning
                ),
                Course(
                    name: "社会伦理",
                    location: "E310",
                    weekday: 3,
                    timeDescription: "14:00-15:40",
                    teacher: nil,
                    order: 3,
                    timeSlot: .afternoon
                ),
                Course(
                    name: "形势与政策",
                    location: "C106",
                    weekday: 4,
                    timeDescription: "08:00-09:40",
                    teacher: nil,
                    order: 1,
                    timeSlot: .morning
                ),
                Course(
                    name: "社会政策",
                    location: "E308",
                    weekday: 4,
                    timeDescription: "14:00-15:40",
                    teacher: nil,
                    order: 3,
                    timeSlot: .afternoon
                ),
                Course(
                    name: "个案研究",
                    location: "C310",
                    weekday: 4,
                    timeDescription: "16:00-17:40",
                    teacher: nil,
                    order: 4,
                    timeSlot: .afternoon
                ),
                Course(
                    name: "个案研究",
                    location: "D403",
                    weekday: 5,
                    timeDescription: "10:00-11:40",
                    teacher: nil,
                    order: 2,
                    timeSlot: .morning
                ),
                Course(
                    name: "企业管理",
                    location: "C310",
                    weekday: 5,
                    timeDescription: "14:00-15:40",
                    teacher: nil,
                    order: 3,
                    timeSlot: .afternoon
                )
            ]
        )
    }
}
