import CoreLocation
import FirebaseDatabase

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager!
    @Published var lastLocation: CLLocation?
        
    override init() {
        super.init()
        setLocationManager()
    }

    func setLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
//        print(lastLocation!)
    }
}
