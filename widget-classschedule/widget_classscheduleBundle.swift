//
//  widget_classscheduleBundle.swift
//  widget-classschedule
//
//  Created by INKLING on 9/19/25.
//

#if canImport(WidgetKit) && !APP_INTENTS_TARGET
import WidgetKit
import SwiftUI

@main
struct ClassScheduleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClassScheduleWidget()
        ClassScheduleDailyWidget()
    }
}
#endif
