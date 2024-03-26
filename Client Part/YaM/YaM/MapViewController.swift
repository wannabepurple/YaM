import MapKit
import CoreLocation
import FirebaseDatabase

class MapViewController: UIViewController {
    
    private let locMan = UIView()
    private var locationManager = LocationManager()
    private var currentUserLatitude = 0.0
    private var currentUserLongitude = 0.0

    private let map: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.tintColor = .green
        return map
    }()
    
    private let currentLocationButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 20
        button.backgroundColor = .black
        button.setImage(UIImage(named:"me")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .green
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.green, for: .normal)
        button.configuration?.titleAlignment = .center
        button.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        return button
    }()
    

    private let friendLocationButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 20
        button.backgroundColor = .black
        button.setImage(UIImage(named: "user")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .green
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.green, for: .normal)
        button.configuration?.titleAlignment = .center
        button.addTarget(self, action: #selector(showFriendLocation), for: .touchUpInside)
        return button
    }()
    

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
        // URL базы данных Firebase
        let urlString = "https://yam-server-ad898-default-rtdb.europe-west1.firebasedatabase.app/locations.json"
        
        // Проверка URL на валидность
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Создает асинхронную задачу (dataTask) для получения данных с сервера
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching location data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                // Десериализация JSON-данных в словарь
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Double]] {
                    let valuesArray = Array(json.values)
                    if let lastLocation = valuesArray.last {
                        if let latitude = lastLocation["latitude"], let longitude = lastLocation["longitude"] {
                            // Обновление карты или выполнение других действий с полученными координатами
                            print("Received latest location - Latitude: \(latitude), Longitude: \(longitude)")
                            
                            // Добавьте свою логику для обновления карты или других действий с полученными данными
                        } else {
                            print("Invalid or incomplete location data")
                        }
                    } else {
                        print("No location data available")
                    }
                } else {
                    print("Failed to parse JSON")
                }
            } catch {
                print("Error deserializing location data: \(error.localizedDescription)")
            }
        }
        
        // Запускает выполнение асинхронной задачи
        task.resume()
    }

}


// MARK: UI + Position
extension MapViewController {
    private func setViewController() {
        setMap()
        setCurrentUserLocationButton()
        sendLocationToServer(withInterval: 5)
        setAnotherLocationButton()
    }
    
    private func setMap() {
        view.addSubview(map)
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
        currentLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            currentLocationButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.2),
            currentLocationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),            currentLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setAnotherLocationButton() {
        view.addSubview(friendLocationButton)
        friendLocationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            friendLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            friendLocationButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.2),
            friendLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),            friendLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    

}
