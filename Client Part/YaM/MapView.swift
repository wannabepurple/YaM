import MapKit
import SwiftUI

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    private let locationManager = CLLocationManager()
    
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapPitchToggle()
        }
        .accentColor(.purple)
        .onAppear {
            setupLocationManager()
            startLocationUpdateTimer()
        }
        
    }
    
    private func setupLocationManager() {
        locationManager.delegate = viewModel
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        print(locationManager.location!.coordinate)
    }
    
    private func startLocationUpdateTimer() {
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
                setupLocationManager()
            }
        }
}


#Preview {
    MapView()
}
