//
//  ContentView.swift
//  Widget1
//
//  Created by INKLING on 9/19/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

// MARK: - 主页面（课表）
struct HomeView: View {
    @EnvironmentObject var router: AppRouter
    @State private var schedule: WeekSchedule?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 标题栏
                HStack {
                    VStack(alignment: .leading) {
                        Text("本周课表")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let schedule = schedule {
                            Text("第\(schedule.weekNumber)周")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 快捷按钮
                    HStack(spacing: 12) {
                        Button(action: {
                            router.navigate(to: .recharge)
                        }) {
                            Image(systemName: "creditcard")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            router.navigate(to: .cardQR)
                        }) {
                            Image(systemName: "qrcode")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 课程列表
                if let schedule = schedule {
                    LazyVStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { weekday in
                            let dayName = weekdayName(weekday)
                            let dayCourses = schedule.coursesForWeekday(weekday)
                            
                            if !dayCourses.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(dayName)
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(dayCourses) { course in
                                        CourseCardView(course: course)
                                            .onTapGesture {
                                                router.navigate(to: .scheduleDay(weekday))
                                            }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            loadSchedule()
        }
        #if os(iOS)
        .navigationTitle("")
        .navigationBarHidden(true)
        #else
        .navigationTitle("本周课表")
        #endif
    }
    
    private func loadSchedule() {
        schedule = SharedDataManager.shared.loadSchedule()
    }
    
    private func weekdayName(_ weekday: Int) -> String {
        let names = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        return names[weekday]
    }
}

// MARK: - 课程卡片
struct CourseCardView: View {
    let course: Course
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                
                HStack {
                    Label(course.location, systemImage: "location")
                    Spacer()
                    Text(course.timeDescription)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if let teacher = course.teacher {
                    Text(teacher)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - 二维码页面
struct CardQRView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("饭卡二维码")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 200, height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("二维码占位")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
            
            VStack(spacing: 8) {
                Text("余额: ¥123.45")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("向商家出示此码完成支付")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("刷新二维码") {
                // 刷新二维码逻辑
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        #if os(iOS)
        .navigationTitle("饭卡支付")
        .navigationBarTitleDisplayMode(.inline)
        #else
        .navigationTitle("饭卡支付")
        #endif
    }
}

// MARK: - 充值页面
struct RechargeView: View {
    @State private var rechargeAmount = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("饭卡充值")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("当前余额: ¥123.45")
                    .font(.title2)
                
                Text("充值金额")
                    .font(.headline)
                
                TextField("请输入充值金额", text: $rechargeAmount)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach([10, 20, 30, 50, 100, 200], id: \.self) { amount in
                        Button("\(amount)元") {
                            rechargeAmount = "\(amount)"
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(10)
            
            Button("确认充值") {
                // 充值逻辑
            }
            .buttonStyle(.borderedProminent)
            .disabled(rechargeAmount.isEmpty)
            
            Spacer()
        }
        .padding()
        #if os(iOS)
        .navigationTitle("充值")
        .navigationBarTitleDisplayMode(.inline)
        #else
        .navigationTitle("充值")
        #endif
    }
}

// MARK: - 单日课表详情页
struct ScheduleDayView: View {
    let day: Int
    @State private var schedule: WeekSchedule?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let schedule = schedule {
                    let courses = schedule.coursesForWeekday(day)
                    
                    if !courses.isEmpty {
                        ForEach(courses) { course in
                            CourseDetailCardView(course: course)
                        }
                    } else {
                        Text("今日无课程安排")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ProgressView("加载中...")
                }
            }
            .padding()
        }
        #if os(iOS)
        .navigationTitle(weekdayName(day))
        .navigationBarTitleDisplayMode(.inline)
        #else
        .navigationTitle(weekdayName(day))
        #endif
        .onAppear {
            schedule = SharedDataManager.shared.loadSchedule()
        }
    }
    
    private func weekdayName(_ weekday: Int) -> String {
        let names = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        return names[weekday]
    }
}

// MARK: - 课程详情卡片
struct CourseDetailCardView: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(course.name)
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Label(course.location, systemImage: "location.fill")
                Label(course.timeDescription, systemImage: "clock.fill")
                
                if let teacher = course.teacher {
                    Label(teacher, systemImage: "person.fill")
                }
            }
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppRouter())
}

private extension Color {
    static var cardBackground: Color {
        #if os(iOS)
        Color(.systemGray6)
        #else
        Color.gray.opacity(0.15)
        #endif
    }
}
