import SwiftUI
import UniformTypeIdentifiers

struct DeveloperInfoView: View {
    @ObservedObject var userStats: UserStats
    @ObservedObject var workoutStore: WorkoutStore
    @AppStorage("developerInfoData") private var developerInfoData: String = ""
    @State private var key: String = ""
    @State private var value: String = ""
    @State private var infoDict: [String: String] = [:]
    @State private var editKey: String? = nil
    @State private var editValue: String = ""
    @State private var showShareSheet = false
    @State private var exportURL: URL? = nil
    @State private var showImportSheet = false
    @Environment(\.dismiss) var dismiss
    @AppStorage("completedGoalDays") private var completedGoalDaysRaw: String = ""
    @State private var completedGoalDays: Set<Date> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // User Stats Section
                    GroupBox(label: Text("User Stats").bold()) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Runner Level: \(userStats.runnerLevel)")
                            Text("Endurance Level: \(userStats.enduranceLevel)")
                            Text("Speed Level: \(userStats.speedLevel)")
                            Text("Total Workouts: \(userStats.totalWorkouts)")
                            Text(String(format: "Total Distance: %.2f mi", userStats.totalDistance))
                            Text("Total Time: \(formatTime(userStats.totalTime))")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                    // Workouts Section
                    GroupBox(label: Text("All Workouts").bold()) {
                        VStack(alignment: .leading, spacing: 8) {
                            if workoutStore.workouts.isEmpty {
                                Text("No workouts recorded.")
                            } else {
                                ForEach(workoutStore.workouts) { workout in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Date: \(workout.date)")
                                        Text(String(format: "Avg Speed: %.2f mph, Peak: %.2f mph", workout.averageSpeed, workout.peakSpeed))
                                        Text(String(format: "Distance: %.2f mi, Time: %@", workout.distance, formatTime(workout.time)))
                                        Text("Route points: \(workout.route.count)")
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                    // Info System Section
                    GroupBox(label: Text("Info System").bold()) {
                        VStack(spacing: 10) {
                            HStack {
                                TextField("Key", text: $key)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                TextField("Value", text: $value)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("Add") {
                                    guard !key.isEmpty else { return }
                                    infoDict[key] = value
                                    saveInfo()
                                    key = ""
                                    value = ""
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.horizontal)
                            
                            ForEach(infoDict.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                                if editKey == k {
                                    HStack {
                                        Text(k).bold()
                                        TextField("Value", text: $editValue)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        Button("Save") {
                                            infoDict[k] = editValue
                                            editKey = nil
                                            saveInfo()
                                        }
                                        .buttonStyle(.bordered)
                                        Button("Cancel") {
                                            editKey = nil
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                } else {
                                    HStack {
                                        Text(k).bold()
                                        Spacer()
                                        Text(v)
                                        Button("Edit") {
                                            editKey = k
                                            editValue = v
                                        }
                                        .buttonStyle(.bordered)
                                        Button(role: .destructive) {
                                            infoDict.removeValue(forKey: k)
                                            saveInfo()
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Streak Data Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak Data")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text("Current Streak: \(currentStreak)")
                        Text("Longest Streak: \(longestStreak)")
                        Text("Total Days with Goal Met: \(completedGoalDays.count)")
                        if !completedGoalDays.map({ $0.stripTime() }).contains(Date().stripTime()) {
                            Text("(Today not yet completed)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(10)

                    // Export Button
                    Button(action: exportAllData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export All Data as JSON")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)
                    // Export Obfuscated Button
                    Button(action: exportObfuscatedData) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Export Obfuscated JSON")
                        }
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                    }
                    // Import Obfuscated Button
                    Button(action: { showImportSheet = true }) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Import Obfuscated JSON")
                        }
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .fileImporter(isPresented: $showImportSheet, allowedContentTypes: [.plainText, .json]) { result in
                        switch result {
                        case .success(let url):
                            importObfuscatedData(from: url)
                        case .failure(let error):
                            print("Import failed: \(error)")
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Developer Info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: loadInfo)
            .onAppear {
                loadCompletedGoalDays()
            }
            .sheet(isPresented: $showShareSheet, onDismiss: { exportURL = nil }) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func saveInfo() {
        if let data = try? JSONEncoder().encode(infoDict),
           let str = String(data: data, encoding: .utf8) {
            developerInfoData = str
        }
    }
    
    private func loadInfo() {
        if let data = developerInfoData.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            infoDict = dict
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func exportAllData() {
        let exportObject: [String: Any] = [
            "userStats": [
                "runnerLevel": userStats.runnerLevel,
                "enduranceLevel": userStats.enduranceLevel,
                "speedLevel": userStats.speedLevel,
                "totalWorkouts": userStats.totalWorkouts,
                "totalDistance": userStats.totalDistance,
                "totalTime": userStats.totalTime
            ],
            "workouts": workoutStore.workouts.map { workout in
                [
                    "date": ISO8601DateFormatter().string(from: workout.date),
                    "averageSpeed": workout.averageSpeed,
                    "peakSpeed": workout.peakSpeed,
                    "distance": workout.distance,
                    "time": workout.time,
                    "route": workout.route.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
                ]
            },
            "infoDict": infoDict
        ]
        if let data = try? JSONSerialization.data(withJSONObject: exportObject, options: .prettyPrinted) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CRDO_Export.json")
            try? data.write(to: tempURL)
            exportURL = tempURL
            showShareSheet = true
        }
    }

    private func exportObfuscatedData() {
        let exportObject: [String: Any] = [
            "userStats": [
                "runnerLevel": userStats.runnerLevel,
                "enduranceLevel": userStats.enduranceLevel,
                "speedLevel": userStats.speedLevel,
                "totalWorkouts": userStats.totalWorkouts,
                "totalDistance": userStats.totalDistance,
                "totalTime": userStats.totalTime
            ],
            "workouts": workoutStore.workouts.map { workout in
                [
                    "date": ISO8601DateFormatter().string(from: workout.date),
                    "averageSpeed": workout.averageSpeed,
                    "peakSpeed": workout.peakSpeed,
                    "distance": workout.distance,
                    "time": workout.time,
                    "route": workout.route.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
                ]
            },
            "infoDict": infoDict
        ]
        if let data = try? JSONSerialization.data(withJSONObject: exportObject, options: .prettyPrinted) {
            let obfuscated = data.base64EncodedString()
            if let obfData = obfuscated.data(using: .utf8) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CRDO_Obfuscated.json")
                try? obfData.write(to: tempURL)
                exportURL = tempURL
                showShareSheet = true
            }
        }
    }

    private func importObfuscatedData(from url: URL) {
        guard let obfData = try? Data(contentsOf: url),
              let base64String = String(data: obfData, encoding: .utf8),
              let decodedData = Data(base64Encoded: base64String),
              let json = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any] else {
            print("Failed to decode obfuscated data")
            return
        }
        // Parse userStats
        if let stats = json["userStats"] as? [String: Any] {
            if let runnerLevel = stats["runnerLevel"] as? Int { userStats.updateRunnerLevel(runnerLevel) }
            if let enduranceLevel = stats["enduranceLevel"] as? Int { userStats.updateEnduranceLevel(enduranceLevel) }
            if let speedLevel = stats["speedLevel"] as? Int { userStats.updateSpeedLevel(speedLevel) }
            if let totalWorkouts = stats["totalWorkouts"] as? Int { userStats.updateTotalWorkouts(totalWorkouts) }
            if let totalDistance = stats["totalDistance"] as? Double { userStats.updateTotalDistance(totalDistance) }
            if let totalTime = stats["totalTime"] as? Double { userStats.updateTotalTime(totalTime) }
        }
        // Parse workouts
        if let workoutsArr = json["workouts"] as? [[String: Any]] {
            var newWorkouts: [Workout] = []
            for w in workoutsArr {
                guard let dateStr = w["date"] as? String,
                      let date = ISO8601DateFormatter().date(from: dateStr),
                      let averageSpeed = w["averageSpeed"] as? Double,
                      let peakSpeed = w["peakSpeed"] as? Double,
                      let distance = w["distance"] as? Double,
                      let time = w["time"] as? Double,
                      let routeArr = w["route"] as? [[String: Double]] else { continue }
                let route = routeArr.compactMap { dict -> Coordinate? in
                    if let lat = dict["latitude"], let lon = dict["longitude"] {
                        return Coordinate(latitude: lat, longitude: lon)
                    }
                    return nil
                }
                let workout = Workout(date: date, averageSpeed: averageSpeed, peakSpeed: peakSpeed, distance: distance, time: time, route: route)
                newWorkouts.append(workout)
            }
            workoutStore.workouts = newWorkouts
        }
        // Parse infoDict
        if let info = json["infoDict"] as? [String: String] {
            infoDict = info
            saveInfo()
        }
    }

    // Load completedGoalDays from storage
    func loadCompletedGoalDays() {
        let formatter = ISO8601DateFormatter()
        completedGoalDays = Set(
            completedGoalDaysRaw
                .split(separator: ",")
                .compactMap { formatter.date(from: String($0)) }
        )
    }
    // Streak calculations
    var currentStreak: Int {
        let normalizedDays = completedGoalDays.map { $0.stripTime() }
        let sorted = normalizedDays.sorted(by: >)
        guard !sorted.isEmpty else { return 0 }
        var streak = 0
        var day = Date().stripTime()
        // If today is not completed, start from yesterday
        if !normalizedDays.contains(day) {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!.stripTime()
        }
        for d in sorted {
            if d == day {
                streak += 1
                day = Calendar.current.date(byAdding: .day, value: -1, to: day)!.stripTime()
            } else if d < day {
                // Only continue if the date matches the expected streak day
                break
            }//
        }
        return streak
    }
    var longestStreak: Int {
        let sorted = completedGoalDays.map { $0.stripTime() }.sorted()
        guard !sorted.isEmpty else { return 0 }
        var maxStreak = 1
        var streak = 1
        for i in 1..<sorted.count {
            let prev = sorted[i-1]
            let curr = sorted[i]
            if Calendar.current.isDate(curr, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: prev)!) {
                streak += 1
                maxStreak = max(maxStreak, streak)
            } else {
                streak = 1
            }
        }
        return maxStreak
    }
}

// ShareSheet helper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
