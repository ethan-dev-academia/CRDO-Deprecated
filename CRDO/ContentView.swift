//
//  ContentView.swift
//  CRDO
//
//  Created by Ethan yip on 7/16/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutStore = WorkoutStore()
    @StateObject private var userProfile = UserProfile()
    @StateObject private var userStats = UserStats()
    @State private var showProfile = false
    @State private var showPersonalStats = false
    @State private var showDeveloperInfo = false
    @State private var developerModeEnabled = false
    @State private var countdown: Int = 15 * 60
    @State private var timerActive: Bool = false
    @State private var timer: Timer? = nil
    @State private var dailyProgress: Double = 0
    private let dailyGoal: Double = 15 * 60
    @State private var showConfetti = false
    @AppStorage("lastGoalCelebratedDate") private var lastGoalCelebratedDate: String = ""
    @State private var previousProgress: Double = 0
    @State private var showCityModal = false
    @State private var showCalendar = false
    @State private var calendarStart: Date = Date()
    @State private var calendarEnd: Date = Date()
    @State private var selectedDate: Date = Date()
    @AppStorage("completedGoalDays") private var completedGoalDaysRaw: String = ""
    @State private var completedGoalDays: Set<Date> = []
    
    // Device-specific adaptations
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Adaptive sizing based on device
    private var adaptiveSpacing: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 40
        } else if UIScreen.main.bounds.height > 800 {
            return 35
        } else {
            return 30
        }
    }

    private var adaptiveIconSize: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 80
        } else if UIScreen.main.bounds.height > 800 {
            return 70
        } else {
            return 60
        }
    }

    private var adaptiveTitleSize: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 32
        } else if UIScreen.main.bounds.height > 800 {
            return 28
        } else {
            return 24
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    HStack {
                        // Profile Photo
                        Button(action: {
                            showProfile = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        
                        Spacer()
                        
                        // App Title
                        Text("CRDO")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Settings Button
                        Button(action: {}) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(Color.black)
                    
                    // Main Content
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // 15-Minute Countdown Circle
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 16)
                                .frame(width: 200, height: 200)
                            Circle()
                                .trim(from: 0, to: CGFloat(min(dailyProgress, dailyGoal) / dailyGoal))
                                .stroke(dailyProgress >= dailyGoal ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 200, height: 200)
                                .animation(.linear, value: dailyProgress)
                            VStack {
                                Text("00:00.00")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(timerDisplay)
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundColor(dailyProgress >= dailyGoal ? .green : .white)
                                    .minimumScaleFactor(0.4)
                                    .lineLimit(1)
                                    .frame(maxWidth: 160)
                                Text("/ 15:00.00")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        // Start 15 Minute CRDO Button
                        if dailyProgress >= dailyGoal {
                            NavigationLink(destination: MapView(initialCountdown: 15 * 60)) {
                                Text("Continue Running")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 18)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 40)
                            // CRDO City Button
                            Button(action: { showCityModal = true }) {
                                HStack(spacing: 4) {
                                    Text("Your")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    Text("CRDO")
                                        .font(.system(size: 22, weight: .bold, design: .serif))
                                    Text("City")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.purple)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 60)
                        } else {
                            NavigationLink(destination: MapView(initialCountdown: Int(dailyGoal - min(dailyProgress, dailyGoal)))) {
                                Text("Start my 15 Minute CRDO")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 18)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 40)
                            // CRDO City Button
                            Button(action: { showCityModal = true }) {
                                HStack(spacing: 4) {
                                    Text("Your")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    Text("CRDO")
                                        .font(.system(size: 22, weight: .bold, design: .serif))
                                    Text("City")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.purple)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 60)
                        }
                        // Small Buttons Row
                        HStack(spacing: 16) {
                            NavigationLink(destination: WorkoutHistoryView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 14))
                                    Text("History")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                            Button(action: { showPersonalStats = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 14))
                                    Text("Stats")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.orange)
                                .cornerRadius(8)
                            }
                        }
                        // DEV: Add 1 minute to daily progress
                        Button(action: {
                            let todayKey = "dailyProgress_" + DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")
                            let prev = UserDefaults.standard.double(forKey: todayKey)
                            UserDefaults.standard.set(prev + 60, forKey: todayKey)
                            loadDailyProgress()
                        }) {
                            Text("Add 1 Minute (DEV)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.purple)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    .onAppear(perform: loadDailyProgress)
                    // Show 2-week streak bar at the bottom
                    WeekStreakBar(completedGoalDays: completedGoalDays, days: 14)
                        .padding(.bottom, 24)
                }
                // Confetti and congratulatory overlay
                if showConfetti {
                    ConfettiView()
                        .edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer()
                        Text("You have achieved your daily CRDO goal!")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(18)
                            .shadow(radius: 10)
                        Spacer()
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(userProfile: userProfile, showDeveloperInfo: $showDeveloperInfo)
        }
        .sheet(isPresented: $showPersonalStats) {
            PersonalStatsView(userStats: userStats)
        }
        .sheet(isPresented: $showDeveloperInfo) {
            DeveloperInfoView(userStats: userStats, workoutStore: workoutStore)
        }
        .fullScreenCover(isPresented: $showCityModal) {
            CRDOCityView(onClose: { showCityModal = false })
        }
        .onAppear {
            loadCompletedGoalDays()
        }
    }
    
    // Watch for dailyProgress change to trigger confetti
    private func checkGoal() {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        // Only show confetti if crossing the threshold and not already celebrated today
        if previousProgress < dailyGoal && dailyProgress >= dailyGoal && !showConfetti && lastGoalCelebratedDate != today {
            showConfetti = true
            lastGoalCelebratedDate = today
            markGoalCompletedForToday() // Automatically mark the day as completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
        previousProgress = dailyProgress
    }
    // Call checkGoal whenever dailyProgress changes
    private func loadDailyProgress() {
        let todayKey = "dailyProgress_" + DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")
        dailyProgress = UserDefaults.standard.double(forKey: todayKey)
        checkGoal()
    }
    private var timerDisplay: String {
        let totalSeconds = Int(dailyProgress)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let hundredths = Int((dailyProgress - floor(dailyProgress)) * 100)
        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, hundredths)
        } else {
            return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
        }
    }
    
    // Helper to get first exercise date
    func firstExerciseDate() -> Date? {
        // Replace with your actual exercise log data source
        // Example: return exerciseLogs.map { $0.date }.min()
        return completedGoalDays.min()
    }
    // Helpers for completed goal days persistence
    func saveCompletedGoalDays() {
        let formatter = ISO8601DateFormatter()
        let strings = completedGoalDays.map { formatter.string(from: $0) }
        completedGoalDaysRaw = strings.joined(separator: ",")
    }
    func loadCompletedGoalDays() {
        let formatter = ISO8601DateFormatter()
        completedGoalDays = Set(
            completedGoalDaysRaw
                .split(separator: ",")
                .compactMap { formatter.date(from: String($0)) }
        )
    }
    // Call this when the 15-minute goal is reached
    func markGoalCompletedForToday() {
        let today = Date().stripTime()
        completedGoalDays.insert(today)
        saveCompletedGoalDays()
    }
}

// Date helpers (if not already present)
extension Date {
    func startOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
    func endOfMonth() -> Date {
        let start = startOfMonth()
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? self
    }
    func stripTime() -> Date {
        Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self) ?? self
    }
}

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userProfile: UserProfile
    @Binding var showDeveloperInfo: Bool
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // User Info
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        )
                    
                    VStack(spacing: 8) {
                        Text(userProfile.userName)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(userProfile.userDescription)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                
                // Profile Options
                VStack(spacing: 15) {
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.system(size: 20))
                            Text("Edit Profile")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Add settings functionality here
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                            Text("Settings")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Add help functionality here
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 20))
                            Text("Help & Support")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    Button(action: { 
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showDeveloperInfo = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "hammer")
                                .font(.system(size: 20))
                            Text("Developer Info")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userProfile: userProfile)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userProfile: UserProfile
    @State private var tempUserName: String
    @State private var tempUserDescription: String
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self._tempUserName = State(initialValue: userProfile.userName)
        self._tempUserDescription = State(initialValue: userProfile.userDescription)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Profile Photo Section
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        )
                    
                    Text("Edit Profile")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // Form Fields
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        TextField("Enter your name", text: $tempUserName)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        TextField("Enter your description", text: $tempUserDescription)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    userProfile.userName = tempUserName
                    userProfile.userDescription = tempUserDescription
                    dismiss()
                }) {
                    Text("Save Changes")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

struct PersonalStatsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userStats: UserStats
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Personal Stats")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Level Stats
                    VStack(spacing: 20) {
                        StatCard(
                            title: "Runner Level",
                            value: "Level \(userStats.runnerLevel)",
                            subtitle: "\(userStats.totalWorkouts) workouts completed",
                            color: .blue,
                            icon: "figure.run"
                        )
                        
                        StatCard(
                            title: "Endurance Level",
                            value: "Level \(userStats.enduranceLevel)",
                            subtitle: String(format: "%.1f miles total", userStats.totalDistance),
                            color: .green,
                            icon: "heart.fill"
                        )
                        
                        StatCard(
                            title: "Speed Level",
                            value: "Level \(userStats.speedLevel)",
                            subtitle: formatTime(userStats.totalTime),
                            color: .red,
                            icon: "bolt.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Overall Stats
                    VStack(spacing: 15) {
                        Text("Overall Progress")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ProgressRow(title: "Total Workouts", value: "\(userStats.totalWorkouts)", color: .blue)
                            ProgressRow(title: "Total Distance", value: String(format: "%.1f miles", userStats.totalDistance), color: .green)
                            ProgressRow(title: "Total Time", value: formatTime(userStats.totalTime), color: .orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Level Progress Bars
                    VStack(spacing: 15) {
                        Text("Level Progress")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 15) {
                            LevelProgressBar(
                                title: "Runner",
                                level: userStats.runnerLevel,
                                progress: userStats.progressForLevel(userStats.runnerLevel, experience: userStats.totalWorkouts * 5),
                                color: .blue
                            )
                            
                            LevelProgressBar(
                                title: "Endurance",
                                level: userStats.enduranceLevel,
                                progress: userStats.progressForLevel(userStats.enduranceLevel, experience: Int(userStats.totalDistance * 10)),
                                color: .green
                            )
                            
                            LevelProgressBar(
                                title: "Speed",
                                level: userStats.speedLevel,
                                progress: userStats.progressForLevel(userStats.speedLevel, experience: Int(userStats.totalDistance * 5)),
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Personal Stats")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct LevelProgressBar: View {
    let title: String
    let level: Int
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(title) Level \(level)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

// Simple confetti animation view
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<40).map { _ in ConfettiParticle.random }
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .animation(
                        Animation.easeOut(duration: 2.0)
                            .delay(Double.random(in: 0...0.5)),
                        value: particle.y
                    )
            }
        }
        .onAppear {
            for i in particles.indices {
                particles[i].fall()
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    static var random: ConfettiParticle {
        ConfettiParticle(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: -100...0),
            size: CGFloat.random(in: 8...18),
            color: Color(hue: Double.random(in: 0...1), saturation: 0.7, brightness: 1),
            opacity: Double.random(in: 0.7...1)
        )
    }
    mutating func fall() {
        y = CGFloat.random(in: UIScreen.main.bounds.height * 0.6...UIScreen.main.bounds.height * 1.1)
        opacity = 0
    }
}

// Custom week streak bar
typealias DateSet = Set<Date>
struct WeekStreakBar: View {
    let completedGoalDays: Set<Date>
    var days: Int = 14
    var weekDays: [[Date]] {
        let today = Date().stripTime()
        let allDays = (0..<days).map { offset in
            Calendar.current.date(byAdding: .day, value: -(days-1) + offset, to: today)!.stripTime()
        }
        // Split into two weeks (Sunday to Saturday)
        return stride(from: 0, to: allDays.count, by: 7).map { i in
            Array(allDays[i..<min(i+7, allDays.count)])
        }
    }
    var body: some View {
        VStack(spacing: 12) {
            ForEach(weekDays, id: \ .self) { week in
                HStack(spacing: 18) {
                    ForEach(week, id: \ .self) { day in
                        let isCompleted = completedGoalDays.contains(day)
                        VStack(spacing: 2) {
                            Text(day.shortWeekday)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Circle()
                                .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.green, lineWidth: isCompleted ? 2 : 0)
                                )
                            Text(day.shortDate)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}

extension Date {
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "M/d"
        return formatter.string(from: self)
    }
}
