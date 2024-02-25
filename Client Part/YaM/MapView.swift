import MapKit
import SwiftUI

struct MapView: View {
    @State private var position = MapCameraPosition.userLocation(fallback: .automatic)
    @ObservedObject var locationManager = LocationManager()

    var userLatitude: String {
        return "\(locationManager.lastLocation?.coordinate.latitude ?? 0)"
    }
    var userLongitude: String {
        return "\(locationManager.lastLocation?.coordinate.longitude ?? 0)"
    }
    
    @State var posts: [Post] = []
    
    var body: some View {
        NavigationView {
            List(posts) { post in
                VStack {
                    Text(post.title)
                        .fontWeight(.bold)
                    Text(post.body)
                }
                .onAppear {
                    API().getPost {(posts) in
                        self.posts = posts
                    }
                }
//                .navigationTitle("Posts")
            }
        }
        
//        VStack {
//            Map(position: $position) {
//                UserAnnotation()
//            }
//            .tint(.purple)
//            .mapControls {
//                MapUserLocationButton()
//                MapCompass()
//            }
//            
//            Text("latitude = \(userLatitude), longitude = \(userLongitude)")
//        }
    }
}

struct Post: Codable, Identifiable {
    var id = UUID()
    var title: String
    var body: String
}

class API {
    func getPost(completion: @escaping ([Post]) -> ()) {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts")
        else { return }
        
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            let posts = try! JSONDecoder().decode([Post].self, from: data!)
            DispatchQueue.main.async {
                completion(posts)
            }
        }
        .resume()
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
    }

    
}

#Preview {
    MapView()
}
