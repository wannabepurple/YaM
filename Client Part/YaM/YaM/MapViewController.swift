import MapKit
import CoreLocation
import FirebaseDatabase

class MapViewController: UIViewController {
    
    private let locMan = UIView()
    private var locationManager = LocationManager()
    private var currentUserLatitude = 0.0
    private var currentUserLongitude = 0.0
    private let map = MKMapView()
    private let selfLocationButton = UIButton() // self location
    private let anotherLocationButton = UIButton() // another user location
    private let selfID = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    
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
                "id": self.selfID,
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
                        if position?["id"] as! String != self.selfID {
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
        view.addSubview(selfLocationButton)
        selfLocationButton.layer.cornerRadius = 20
        selfLocationButton.backgroundColor = .black
        selfLocationButton.setImage(UIImage(named:"me")?.withRenderingMode(.alwaysTemplate), for: .normal)
        selfLocationButton.tintColor = .green
        selfLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        selfLocationButton.setTitleColor(.green, for: .normal)
        selfLocationButton.configuration?.titleAlignment = .center
        selfLocationButton.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        
        selfLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selfLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            selfLocationButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.2),
            selfLocationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),            selfLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setAnotherLocationButton() {
        view.addSubview(anotherLocationButton)
        anotherLocationButton.layer.cornerRadius = 20
        anotherLocationButton.backgroundColor = .black
        anotherLocationButton.setImage(UIImage(named: "user")?.withRenderingMode(.alwaysTemplate), for: .normal)
        anotherLocationButton.tintColor = .green
        anotherLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        anotherLocationButton.setTitleColor(.green, for: .normal)
        anotherLocationButton.configuration?.titleAlignment = .center
        anotherLocationButton.addTarget(self, action: #selector(showFriendLocation), for: .touchUpInside)
        
        anotherLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            anotherLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            anotherLocationButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.2),
            anotherLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),            anotherLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    

}
