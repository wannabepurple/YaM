import MapKit
import CoreLocation
import FirebaseDatabase

class MapViewController: UIViewController {
    
    private let locMan = UIView()
    private var locationManager = LocationManager()
    private var currentUserLatitude = 0.0
    private var currentUserLongitude = 0.0
    private let map = MKMapView()
    private let currentLocationButton = UIButton() // self location
    private let friendLocationButton = UIButton() // another user location
    private let userIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    

    override func viewDidLoad() {
        super.viewDidLoad()

        setViewController()
    }
}


// MARK: Server + location logic
extension MapViewController {
    private func getCoordinates() {
        currentUserLatitude = locationManager.lastLocation?.coordinate.latitude ?? 0
        currentUserLongitude = locationManager.lastLocation?.coordinate.longitude ?? 0
    }
    
    private func sendLocationToServer(withInterval: TimeInterval) {
        // URL базы данных Firebase
        let urlString = "https://yam-server-ad898-default-rtdb.europe-west1.firebasedatabase.app/locations.json"
        
        // Проверка URL на валидность
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Каждые withInterval секунд происходит отправка данных на сервер
        Timer.scheduledTimer(withTimeInterval: withInterval, repeats: true) { _ in
            self.getCoordinates()
            // Данные для отправки
            let locationData: [String: Any] = [
                "id": self.userIdentifier,
                "latitude": self.currentUserLatitude,
                "longitude": self.currentUserLongitude
            ]
            
            do {
                // Создает JSON-данные из словаря locationData
                let jsonData = try JSONSerialization.data(withJSONObject: locationData, options: [])
                
                // Создает экземпляр URLRequest с заданным URL (url)
                var request = URLRequest(url: url)
                
                // Устанавливает метод HTTP-запроса как POST, потому что мы ОТПРАВЛЯЕМ данные на сервер
                request.httpMethod = "POST"
                
                // Устанавливает тело запроса, которое содержит JSON-данные
                request.httpBody = jsonData
                
                // Устанавливает заголовок запроса для указания типа контента как "application/json"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Создает асинхронную задачу (dataTask) для отправки запроса на сервер. Замыкание будет выполнено после завершения задачи
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error sending location to server: \(error.localizedDescription)")
                    } else {
                        print("Location sent to server successfully!")
                    }
                }
                // Запускает выполнение асинхронной задачи. Запрос отправляется на сервер, и после завершения задачи выполнится замыкание
                task.resume()
            } catch {
                print("Error serializing location data: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func showCurrentLocation() {
        getCoordinates()
        let center = CLLocationCoordinate2D(latitude: currentUserLatitude, longitude: currentUserLongitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: true)
    }
    
    @objc private func showFriendLocation() {
        let urlString = "https://yam-server-ad898-default-rtdb.europe-west1.firebasedatabase.app/locations.json"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching location data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Переменная для хранения последнего местоположения друга
                    var lastFriendLocation: [String: Any]?
                    // Перебираем все пары ключ-значение в словаре
                    for (key, value) in json.reversed() {
                        // Проверяем, является ли это местоположение друга (не мое)
                        let position = value as! [String: Any]?
                        if position?["id"] as! String != self.userIdentifier {
                            // Обновляем последнее местоположение друга
                            lastFriendLocation = position
                            print("Loc found successfully")
                            break
                        }
                    }
                    
                    // Проверяем, удалось получить последнее местоположение друга
                    if let lastLocation = lastFriendLocation,
                       let latitude = lastLocation["latitude"],
                       let longitude = lastLocation["longitude"] {
                        print("Friend's latest location - Latitude: \(latitude), Longitude: \(longitude)")
                        // Добавьте свою логику для обновления карты или других действий с полученными данными
                    } else {
                        print("No location data available for friend")
                    }
                } else {
                    print("Failed to parse JSON")
                }
            } catch {
                print("Error deserializing location data: \(error.localizedDescription)")
            }
        }.resume()
    }

    
}


// MARK: UI
extension MapViewController {
    private func setViewController() {
        setMap()
        setCurrentUserLocationButton()
        sendLocationToServer(withInterval: 5)
        setAnotherLocationButton()
    }
    
    private func setMap() {
        view.addSubview(map)
        map.showsUserLocation = true
        map.tintColor = .green
        map.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            map.topAnchor.constraint(equalTo: view.topAnchor),
            map.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            map.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            map.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setCurrentUserLocationButton() {
        view.addSubview(currentLocationButton)
        currentLocationButton.layer.cornerRadius = 20
        currentLocationButton.backgroundColor = .black
        currentLocationButton.setImage(UIImage(named:"me")?.withRenderingMode(.alwaysTemplate), for: .normal)
        currentLocationButton.tintColor = .green
        currentLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        currentLocationButton.setTitleColor(.green, for: .normal)
        currentLocationButton.configuration?.titleAlignment = .center
        currentLocationButton.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        
        currentLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            currentLocationButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.2),
            currentLocationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),            currentLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setAnotherLocationButton() {
        view.addSubview(friendLocationButton)
        friendLocationButton.layer.cornerRadius = 20
        friendLocationButton.backgroundColor = .black
        friendLocationButton.setImage(UIImage(named: "user")?.withRenderingMode(.alwaysTemplate), for: .normal)
        friendLocationButton.tintColor = .green
        friendLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        friendLocationButton.setTitleColor(.green, for: .normal)
        friendLocationButton.configuration?.titleAlignment = .center
        friendLocationButton.addTarget(self, action: #selector(showFriendLocation), for: .touchUpInside)
        
        friendLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            friendLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            friendLocationButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.2),
            friendLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),            friendLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    

}
