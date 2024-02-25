import Foundation
import CoreLocation


class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // singletone
    
    let manager = CLLocationManager()
    
    var completion: ((CLLocation) -> Void))?
    
    public func getUserLocation(comletion: @escaping ((CLLocation) -> Void)) {
        self.completion = comletion
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        completion?(location)
        manager.stopUpdatingLocation()
    }
    
}
