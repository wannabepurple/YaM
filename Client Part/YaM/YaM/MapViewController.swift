import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    private let currentLocationButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 20
        button.backgroundColor = .black
        button.setTitle("Your current location", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.green, for: .normal)
        button.configuration?.titleAlignment = .center
        button.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        return button
    }()
    
    @objc private func showCurrentLocation() {
        let currentLatitude = locationManager.location?.coordinate.latitude ?? 0
        let currentLongitude = locationManager.location?.coordinate.longitude ?? 0
        let center = CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: true)
    }
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupMap()
        setupCurrentLocationButton()
    }
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    private func setupMap() {
        view.addSubview(map)
        map.frame = view.bounds
        map.showsUserLocation = true
        map.tintColor = .green
    }
    
    private func setupCurrentLocationButton() {
        view.addSubview(currentLocationButton)
        currentLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            currentLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -70),
            currentLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 70),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = manager.location?.coordinate
        print("Latitude = \(coordinate?.latitude ?? 0), longitude = \(coordinate?.longitude ?? 0)")
    }
}

