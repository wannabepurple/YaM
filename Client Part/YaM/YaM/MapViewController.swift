import MapKit
import CoreLocation
import FirebaseDatabase

class MapViewController: UIViewController {
    
    private var locationManager = LocationManager()
    
    private var currentUserLatitude = 0.0
    private var currentUserLongitude = 0.0
    private func getCoordinates() {
        currentUserLatitude = locationManager.lastLocation?.coordinate.latitude ?? 0
        currentUserLongitude = locationManager.lastLocation?.coordinate.longitude ?? 0
    }

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
        button.setTitle("Your current location", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.green, for: .normal)
        button.configuration?.titleAlignment = .center
        button.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        return button
    }()
    
    @objc private func showCurrentLocation() {
        getCoordinates()
        let center = CLLocationCoordinate2D(latitude: currentUserLatitude, longitude: currentUserLongitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: true)
//        getLocationFromServer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setMap()
        setCurrentUserLocationButton()
        sendLocationToServer(withInterval: 5)
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
            currentLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -70),
            currentLocationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 70),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
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
    
    /*
    private func getLocationFromServer() {
        // URL базы данных Firebase
        let urlString = "https://yam-server-ad898-default-rtdb.europe-west1.firebasedatabase.app/"
        
        // Проверка URL на валидность
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Создает экземпляр URLRequest с заданным URL (url)
        var request = URLRequest(url: url)
        
        // Устанавливает метод HTTP-запроса как GET, потому что мы получаем данные с сервера
        request.httpMethod = "GET"
        
        // Создает асинхронную задачу (dataTask) для получения данных с сервера. Замыкание будет выполнено после завершения задачи
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching location from server: \(error.localizedDescription)")
            } else if let data = data {
                do {
                    // Преобразует полученные данные в массив JSON
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        for json in jsonArray {
                            // Извлекает координаты из каждого объекта
                            if let latitude = json["latitude"] as? Double,
                               let longitude = json["longitude"] as? Double {
                                print("Location received from server - Latitude: \(latitude), Longitude: \(longitude)")
                                
                                // Здесь вы можете использовать полученные координаты по вашему усмотрению
                            } else {
                                print("Invalid data format for coordinates in server response")
                            }
                        }
                    } else {
                        print("Invalid data format from server - Not an array")
                    }
                } catch {
                    print("Error parsing JSON data: \(error.localizedDescription)")
                }
            }
        }
        // Запускает выполнение асинхронной задачи. Запрос отправляется на сервер, и после завершения задачи выполнится замыкание
        task.resume()
    }
*/
    
}
