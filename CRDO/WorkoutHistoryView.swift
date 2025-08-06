import SwiftUI
import MapKit

struct WorkoutHistoryView: View {
    @StateObject private var workoutStore = WorkoutStore()
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirmation = false
    @State private var clearText = ""
    @State private var selectedWorkout: Workout? // Only this state is needed for sheet
    // Removed: @State private var showFullMap = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.3), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Enhanced Header
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("BACK")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showClearConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(15)
                        }
                    }
                    
                    // Workout History Title
                    Text("WORKOUT HISTORY")
                        .font(.system(size: 23, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Summary Stats
                    if !workoutStore.workouts.isEmpty {
                        HStack(spacing: 12) {
                            SummaryStatCard(
                                title: "TOTAL",
                                value: "\(workoutStore.workouts.count)",
                                icon: "figure.run",
                                color: .blue
                            )
                            SummaryStatCard(
                                title: "DISTANCE",
                                value: String(format: "%.1f mi", workoutStore.workouts.reduce(0) { $0 + $1.distance }),
                                icon: "location.fill",
                                color: .green
                            )
                            SummaryStatCard(
                                title: "TIME",
                                value: formatTotalTime(workoutStore.workouts.reduce(0) { $0 + $1.time }),
                                icon: "clock.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Workouts List
                if workoutStore.workouts.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "figure.run")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("NO WORKOUTS YET")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("Complete your first workout to see it here")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(workoutStore.workouts.reversed()) { workout in
                                ModernWorkoutCard(workout: workout) {
                                    workoutStore.deleteWorkout(workout)
                                } onMapTap: {
                                    print("Map tapped for workout: \(workout.id)")
                                    selectedWorkout = workout // Only set selectedWorkout
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedWorkout) { workout in
            SheetContentView(workout: workout)
        }
        .alert("Type 'clear' to confirm", isPresented: $showClearConfirmation, actions: {
            TextField("Type 'clear' to confirm", text: $clearText)
            Button("Confirm", role: .destructive) {
                if clearText.lowercased() == "clear" {
                    workoutStore.clearAllWorkouts()
                }
                clearText = ""
            }
            Button("Cancel", role: .cancel) {
                clearText = ""
            }
        }, message: {
            Text("This will delete all workout history. This action cannot be undone.")
        })
    }
    
    private func formatTotalTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ModernWorkoutCard: View {
    let workout: Workout
    let onDelete: () -> Void
    let onMapTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with date and category
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(workout.date))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: workout.category.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text(workout.category.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ModernStatRow(label: "AVG SPEED", value: String(format: "%.1f mph", workout.averageSpeed), icon: "speedometer")
                ModernStatRow(label: "PEAK SPEED", value: String(format: "%.1f mph", workout.peakSpeed), icon: "bolt.fill")
                ModernStatRow(label: "DISTANCE", value: String(format: "%.2f mi", workout.distance), icon: "location.fill")
                ModernStatRow(label: "TIME", value: formatTime(workout.time), icon: "clock.fill")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Route Preview
            if !workout.route.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text("ROUTE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("TAP TO VIEW")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    
                    MapRoutePreview(route: workout.route)
                        .frame(height: 120)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .contentShape(Rectangle()) // Make the whole area tappable
                        .onTapGesture {
                            print("Map preview tapped!")
                            onMapTap()
                        }
                }
                .padding(.bottom, 20)
            } else {
                // Debug: route is empty, so map preview is not shown
                Color.clear
                    .frame(height: 0)
                    .onAppear {
                        print("Workout route is empty, map preview not shown for workout: \(workout.id)")
                    }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct ModernStatRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

import MapKit

struct MapRoutePreview: UIViewRepresentable {
    let route: [Coordinate]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        let coords = route.map { $0.clLocationCoordinate2D }
        guard coords.count > 1 else {
            // Center on first point if only one
            if let first = coords.first {
                let region = MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                mapView.setRegion(region, animated: false)
            }
            return
        }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)
        // Fit region
        var rect = polyline.boundingMapRect
        let padding = 0.002
        rect = rect.insetBy(dx: -rect.size.width * padding, dy: -rect.size.height * padding)
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemGreen
                renderer.lineWidth = 5
                renderer.alpha = 0.8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct FullScreenMapView: View {
    let workout: Workout
    @Environment(\.dismiss) var dismiss
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var replayIndex: Int = 1 // Revert to Int for working replay
    @State private var isPlaying: Bool = false
    @State private var speed: Double = 5.0 // Default to 5x
    let speedOptions: [Double] = [1.0, 5.0, 10.0]
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ReplayMapRouteView(
                coordinates: workout.route.map { $0.clLocationCoordinate2D },
                replayIndex: replayIndex
            )
            .edgesIgnoringSafeArea(.all)
            .onDisappear {
                timer?.invalidate()
            }
            
            // Close button (closer to top left)
            Button(action: {
                timer?.invalidate()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .padding(.top, 18)
            .padding(.leading, 14)
            
            // Compact stats box (top right)
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 10) {
                    StatIconText(icon: "speedometer", text: String(format: "%.1f mph", workout.averageSpeed))
                    StatIconText(icon: "bolt.fill", text: String(format: "%.1f mph", workout.peakSpeed))
                }
                HStack(spacing: 10) {
                    StatIconText(icon: "location.fill", text: String(format: "%.2f mi", workout.distance))
                    StatIconText(icon: "clock.fill", text: formatTime(workout.time))
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.65))
            .cornerRadius(12)
            .padding(.top, 18)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            
            // Speed controls and progress bar (bottom center)
            VStack(spacing: 12) {
                Spacer()
                // Progress bar with play button
                if workout.route.count > 1 {
                    HStack(spacing: 16) {
                        Button(action: {
                            if isPlaying {
                                timer?.invalidate()
                                isPlaying = false
                            } else {
                                if replayIndex >= workout.route.count {
                                    replayIndex = 1
                                }
                                startReplay()
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.white)
                                .shadow(radius: 6)
                                .background(Color.black.opacity(0.3).clipShape(Circle()))
                        }
                        Slider(value: Binding(
                            get: { Double(replayIndex) },
                            set: { newValue in
                                timer?.invalidate()
                                replayIndex = Int(newValue)
                                isPlaying = false
                            }
                        ), in: 1...Double(workout.route.count), step: 1)
                        .accentColor(.green)
                    }
                    .padding(.horizontal, 30)
                    // Live timer below slider
                    HStack {
                        Text(replayElapsedTimeString)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text(totalElapsedTimeString)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 38)
                }
                // Speed controls
                HStack(spacing: 16) {
                    ForEach(speedOptions, id: \.self) { option in
                        Button(action: {
                            speed = option
                            if isPlaying { restartReplay() }
                        }) {
                            Text("\(Int(option))x")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(speed == option ? .black : .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(speed == option ? Color.white : Color.black.opacity(0.7))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    private func startReplay() {
        timer?.invalidate()
        isPlaying = true
        let total = workout.route.count
        guard total > 1 else { return }
        if replayIndex >= total {
            replayIndex = 1
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.2 / speed, repeats: true) { _ in
            if replayIndex < total {
                replayIndex += 1
            } else {
                timer?.invalidate()
                isPlaying = false
                replayIndex = total
            }
        }
    }
    private func restartReplay() {
        if isPlaying {
            startReplay()
        }
    }
    
    // Add computed properties for timer display
    private var replayElapsedTimeString: String {
        guard workout.route.count > 1 else { return "0:00" }
        let totalTime = workout.time
        let percent = Double(replayIndex - 1) / Double(workout.route.count - 1)
        let elapsed = totalTime * percent
        return formatTimeShort(elapsed)
    }
    private var totalElapsedTimeString: String {
        formatTimeShort(workout.time)
    }
    private func formatTimeShort(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ReplayMapRouteView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    let replayIndex: Int
    
    class MapState: NSObject {
        var didSetRegion = false
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        context.coordinator.state = MapState()
        // Set initial region to fit the full route
        if coordinates.count > 1 {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            var rect = polyline.boundingMapRect
            let padding = 0.1
            rect = rect.insetBy(dx: -rect.size.width * padding, dy: -rect.size.height * padding)
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20), animated: false)
            context.coordinator.state?.didSetRegion = true
        } else if let first = coordinates.first {
            let region = MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: false)
            context.coordinator.state?.didSetRegion = true
        }
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        let shownCoords = Array(coordinates.prefix(replayIndex))
        if shownCoords.count > 1 {
            let polyline = MKPolyline(coordinates: shownCoords, count: shownCoords.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var state: MapState?
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemGreen
                renderer.lineWidth = 5
                renderer.alpha = 0.8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct StatIconText: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(Color.white.opacity(0.08))
        .cornerRadius(6)
    }
}

struct FullScreenMapRouteView: UIViewRepresentable {
    let workout: Workout
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinates = workout.route.map { $0.clLocationCoordinate2D }
        
        // Clear existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        if coordinates.count > 1 {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            
            // Fit the map to show the entire route
            var rect = polyline.boundingMapRect
            let padding = 0.1
            rect = rect.insetBy(dx: -rect.size.width * padding, dy: -rect.size.height * padding)
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20), animated: true)
        } else if let firstCoordinate = coordinates.first {
            // If only one point, center on it
            let region = MKCoordinateRegion(center: firstCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemGreen
                renderer.lineWidth = 5
                renderer.alpha = 0.8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct SheetContentView: View {
    let workout: Workout // Now non-optional
    
    var body: some View {
        FullScreenMapView(workout: workout)
            .onAppear {
                print("Sheet presenting workout: \(workout.id)")
            }
    }
}

#Preview {
    WorkoutHistoryView()
} 
