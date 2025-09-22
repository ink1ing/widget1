import SwiftUI
import Combine

enum NavigationDestination: Hashable {
    case home
    case cardQR
    case recharge
    case scheduleDay(Int)
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var navigationPath = NavigationPath()

    func navigate(to destination: NavigationDestination) {
        switch destination {
        case .home:
            navigationPath = NavigationPath()
        default:
            navigationPath.append(destination)
        }
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }

    func popLast() {
        guard !navigationPath.isEmpty else {
            return
        }
        navigationPath.removeLast()
    }

    func handleURL(_ url: URL) {
        guard url.scheme?.lowercased() == "henau" else {
            return
        }

        let host = url.host?.lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch (host, pathComponents.first?.lowercased()) {
        case ("card", "qr"):
            navigate(to: .cardQR)
        case ("card", "recharge"):
            navigate(to: .recharge)
        case ("schedule", let dayString):
            if let dayString,
               let day = Int(dayString),
               (1...7).contains(day) {
                navigate(to: .scheduleDay(day))
            }
        default:
            break
        }
    }
}
