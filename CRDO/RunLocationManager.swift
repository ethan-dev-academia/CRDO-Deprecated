import Foundation
import CoreLocation
import Combine

class RunLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = RunLocationManager()
    private let manager = CLLocationManager()
    @Published var routePoints: [CLLocationCoordinate2D] = []
    private let routeKey = "runRoutePoints"
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        loadRoutePoints()
        // Save route points whenever they change
        $routePoints.sink { [weak self] points in
            self?.saveRoutePoints()
        }.store(in: &cancellables)
    }
    
    func startTracking() {
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for loc in locations {
            routePoints.append(loc.coordinate)
        }
    }
    
    // Persistence
    private func saveRoutePoints() {
        let arr = routePoints.map { [$0.latitude, $0.longitude] }
        UserDefaults.standard.set(arr, forKey: routeKey)
    }
    private func loadRoutePoints() {
        guard let arr = UserDefaults.standard.array(forKey: routeKey) as? [[Double]], !arr.isEmpty else { return }
        routePoints = arr.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
        }
    }
    func clearRoute() {
        routePoints = []
        UserDefaults.standard.removeObject(forKey: routeKey)
    }
} 