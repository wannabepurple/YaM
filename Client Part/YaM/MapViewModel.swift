import MapKit

enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 55.814093, longitude: 37.500836)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
}

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation,
                                    span: MapDetails.defaultSpan)
    
    var locationManager: CLLocationManager?
    
    func checkLocationServisesEnabled() {
        locationManager = CLLocationManager() // locManDidChangeAuth after this line
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.delegate = self
    }
    
    // When auth changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    // Check permission to use location services by app
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
            // Pull request only in this case
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("Your location is restricted")
        case .denied:
            print("Your have denied location services for this app")
        case .authorizedAlways, .authorizedWhenInUse:
            region = MKCoordinateRegion(center: locationManager.location!.coordinate,
                                        span: MapDetails.defaultSpan)
        @unknown default:
            break
        }
    }
}
