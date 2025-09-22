//
//  Widget1App.swift
//  Widget1
//
//  Created by INKLING on 9/19/25.
//

import SwiftUI

@main
struct Widget1App: App {
    @StateObject private var router = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navigationPath) {
                ContentView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case .home:
                            ContentView()
                        case .cardQR:
                            CardQRView()
                        case .recharge:
                            RechargeView()
                        case .scheduleDay(let day):
                            ScheduleDayView(day: day)
                        }
                    }
            }
            .environmentObject(router)
            .onOpenURL { url in
                router.handleURL(url)
            }
        }
    }
}
