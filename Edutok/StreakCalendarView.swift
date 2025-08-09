// StreakCalendarView.swift
import SwiftUI

struct StreakCalendarView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var selectedDayStat: DailyStat?
    @State private var showDayDetail = false
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with month navigation
                monthHeaderView()
                
                // Calendar grid
                calendarGridView()
                
                // Current streak info
                if let user = firebaseManager.currentUser {
                    streakInfoView(user: user)
                }
                
                // Achievement timeline
                achievementTimelineView()
                
                // Extra padding for floating nav
                Color.clear.frame(height: 100)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.purple.opacity(0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showDayDetail) {
            if let stat = selectedDayStat {
                DayDetailView(dailyStat: stat)
            }
        }
    }
    
    private func monthHeaderView() -> some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            
            Spacer()
            
            VStack(spacing: 5) {
                Text(monthYearString(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let user = firebaseManager.currentUser {
                    Text("🔥 \(user.currentStreak) day streak")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    private func calendarGridView() -> some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.id) { day in
                    calendarDayView(day: day)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func calendarDayView(day: CalendarDay) -> some View {
        Button(action: {
            if day.dailyStat != nil {
                selectedDayStat = day.dailyStat
                showDayDetail = true
            }
        }) {
            ZStack {
                // Background based on activity level
                RoundedRectangle(cornerRadius: 12)
                    .fill(activityColor(for: day))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                day.isToday ? Color.white : Color.clear,
                                lineWidth: day.isToday ? 2 : 0
                            )
                    )
                
                VStack(spacing: 2) {
                    // Day number
                    Text("\(day.dayNumber)")
                        .font(.caption)
                        .fontWeight(day.isToday ? .bold : .medium)
                        .foregroundColor(textColor(for: day))
                    
                    // Activity indicators
                    if let stat = day.dailyStat, stat.hasActivity {
                        HStack(spacing: 2) {
                            if stat.cardsFlipped > 0 {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 4, height: 4)
                            }
                            if stat.topicsExplored > 0 {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    
                    // Achievement indicator
                    if let stat = day.dailyStat, !stat.achievements.isEmpty {
                        Text("🏆")
                            .font(.system(size: 8))
                    }
                }
            }
            .frame(height: 50)
            .animation(.easeInOut(duration: 0.2), value: day.activityLevel)
        }
        .disabled(day.dailyStat == nil)
    }
    
    private func streakInfoView(user: AppUser) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text("Streak Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                StreakStatCard(
                    title: "Current Streak",
                    value: "\(user.currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StreakStatCard(
                    title: "Longest Streak",
                    value: "\(user.longestStreak)",
                    subtitle: "days",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StreakStatCard(
                    title: "Total Activity",
                    value: "\(user.totalCardsFlipped + user.totalTopicsExplored)",
                    subtitle: "actions",
                    icon: "chart.bar.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func achievementTimelineView() -> some View {
        VStack(spacing: 15) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(recentAchievements, id: \.id) { achievement in
                        achievementCard(achievement: achievement)
                    }
                    
                    if recentAchievements.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "trophy")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("No achievements yet")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(width: 200, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func achievementCard(achievement: CalendarAchievement) -> some View {
        VStack(spacing: 8) {
            Text(achievement.emoji)
                .font(.title)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(relativeDateString(from: achievement.date))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }
    
    private var calendarDays: [CalendarDay] {
        guard let user = firebaseManager.currentUser else { return [] }
        
        let monthRange = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = calendar.dateInterval(of: .month, for: currentMonth)!.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        var days: [CalendarDay] = []
        
        // Add previous month padding days
        for i in 1..<firstWeekday {
            let date = calendar.date(byAdding: .day, value: -(firstWeekday - i), to: firstDay)!
            days.append(CalendarDay(
                date: date,
                dailyStat: user.statsFor(date: date),
                hasStreak: user.hasActivityOn(date: date),
                achievements: user.statsFor(date: date)?.achievements ?? []
            ))
        }
        
        // Add current month days
        for day in 1...monthRange.count {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)!
            days.append(CalendarDay(
                date: date,
                dailyStat: user.statsFor(date: date),
                hasStreak: user.hasActivityOn(date: date),
                achievements: user.statsFor(date: date)?.achievements ?? []
            ))
        }
        
        // Add next month padding days to complete the grid
        let remainingDays = 42 - days.count // 6 weeks * 7 days
        for i in 1...remainingDays {
            let date = calendar.date(byAdding: .day, value: monthRange.count + i - 1, to: firstDay)!
            days.append(CalendarDay(
                date: date,
                dailyStat: user.statsFor(date: date),
                hasStreak: user.hasActivityOn(date: date),
                achievements: user.statsFor(date: date)?.achievements ?? []
            ))
        }
        
        return days
    }
    
    private var recentAchievements: [CalendarAchievement] {
        guard let user = firebaseManager.currentUser else { return [] }
        
        let achievements = user.dailyStats
            .flatMap { stat in
                stat.achievements.compactMap { achievementId in
                    if let achievement = Achievement.allCases.first(where: { $0.rawValue == achievementId }) {
                        return CalendarAchievement(date: stat.date, achievement: achievement)
                    }
                    return nil
                }
            }
            .sorted { $0.date > $1.date }
        
        return Array(achievements.prefix(5))
    }
    
    // MARK: - Helper Functions
    
    private func activityColor(for day: CalendarDay) -> Color {
        if !calendar.isDate(day.date, equalTo: currentMonth, toGranularity: .month) {
            return Color.white.opacity(0.05)
        }
        
        switch day.activityLevel {
        case .none:
            return Color.white.opacity(0.1)
        case .low:
            return Color.green.opacity(0.3)
        case .medium:
            return Color.orange.opacity(0.6)
        case .high:
            return Color.red.opacity(0.8)
        }
    }
    
    private func textColor(for day: CalendarDay) -> Color {
        if !calendar.isDate(day.date, equalTo: currentMonth, toGranularity: .month) {
            return Color.white.opacity(0.3)
        }
        
        return day.isToday ? .white : .white.opacity(0.9)
    }
    
    private func monthYearString(from date: Date) -> String {
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    private func relativeDateString(from date: Date) -> String {
        let daysSince = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if daysSince == 0 {
            return "Today"
        } else if daysSince == 1 {
            return "Yesterday"
        } else {
            return "\(daysSince) days ago"
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - Supporting Views

struct StreakStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DayDetailView: View {
    let dailyStat: DailyStat
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date header
                    Text(dayFormatter.string(from: dailyStat.date))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Activity stats
                    VStack(spacing: 15) {
                        ActivityStatRow(
                            icon: "rectangle.stack.fill",
                            title: "Cards Flipped",
                            value: dailyStat.cardsFlipped,
                            color: .purple
                        )
                        
                        ActivityStatRow(
                            icon: "book.fill",
                            title: "Topics Explored",
                            value: dailyStat.topicsExplored,
                            color: .blue
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Achievements
                    if !dailyStat.achievements.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Achievements Unlocked")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ForEach(dailyStat.achievements, id: \.self) { achievementId in
                                if let achievement = Achievement.allCases.first(where: { $0.rawValue == achievementId }) {
                                    HStack {
                                        Text(achievement.emoji)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading) {
                                            Text(achievement.title)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text(achievement.description)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.yellow.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Color.clear.frame(height: 50) // Bottom padding
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.purple.opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
}

struct ActivityStatRow: View {
    let icon: String
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.2))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
