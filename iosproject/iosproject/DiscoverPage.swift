//
 //  DiscoverPage.swift
 //  iosproject
 //
 //  Created by Austin Nguyen on 10/17/25.
 //

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase


class DiscoverPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String? // same as address
    var address: String?
    var locationId: String?
    
    var PostId: String?
    
    init(coordinate: CLLocationCoordinate2D,
         title: String?,
         subtitle: String?,
         address: String?,
         locationId: String?,
         PostId: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.address = address
        self.locationId = locationId
        self.PostId = PostId
       
    }
}


class DiscoverPage : ModeViewController, MKMapViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var searchResults: UITableView!
    var searchText:String = ""
    
    // stores search results, may be empty
    var searchFieldLocations: [DiscoverPin] = []
    
    var discoverDelegate: AddPostViewController?
    var isSelectingLocation: Bool = false
    var selectedAnnot: DiscoverPin?

    var locationId: String?

    @IBOutlet weak var newConfirmLocationButton: UIButton!
    
    var locations:[DiscoverPin] = []
    var viewSize:Double = 500
    var currentView: MKAnnotationView?
        
    let ref = Database.database().reference()
    
    fileprivate let locationManager: CLLocationManager = CLLocationManager()
    var currentCLLCordinate2d: CLLocationCoordinate2D?
    
    
    var delegate: UIViewController?
    var fromAddPost = false
    
    override func viewDidLoad(){
        super.viewDidLoad()
        mapView.delegate = self
        searchField.delegate = self
        searchResults.delegate = self
        searchResults.dataSource = self
        searchResults.rowHeight = UITableView.automaticDimension
        searchResults.isHidden = true
        
        newConfirmLocationButton.layer.shadowColor = UIColor.black.cgColor
        newConfirmLocationButton.layer.shadowRadius = 5.0
        newConfirmLocationButton.layer.shadowOpacity = 0.4
        newConfirmLocationButton.layer.shadowOffset = CGSize(width: 2, height: 4)
        
        if self.isSelectingLocation {
            newConfirmLocationButton.isHidden = false
        } else {
            newConfirmLocationButton.isHidden = true
        }
        
        loadPins()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        let hideTap = UITapGestureRecognizer(target: self, action: #selector(hideSearchResults))
        hideTap.cancelsTouchesInView = false
        view.addGestureRecognizer(hideTap)

        
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            let currentCLLocation = self.locationManager.location
            var targetCLLCoordinate2D: CLLocationCoordinate2D?
            targetCLLCoordinate2D = CLLocationCoordinate2D(
                latitude: currentCLLocation!.coordinate.latitude,
                longitude: currentCLLocation!.coordinate.longitude)
            self.currentCLLCordinate2d = targetCLLCoordinate2D
        default:
            if self.currentCLLCordinate2d == nil {
                self.currentCLLCordinate2d = CLLocationCoordinate2D(latitude: 30.2862, longitude: -97.7394)
            }
        }
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        let targetRegion = MKCoordinateRegion(
            center: self.currentCLLCordinate2d!,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(targetRegion, animated: true)
    
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        loadPins()
    }
    
    func searchBar(_ searchField: UISearchBar, textDidChange text: String) {
        self.searchText = searchField.searchTextField.text!
        searchResults.isHidden = false
        searchResults.rowHeight = UITableView.automaticDimension
        view.bringSubviewToFront(searchResults)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        Task {
            await getSearchResults(addressString: searchBar.text ?? "")
        }
    }

    @objc func hideSearchResults() {
        searchResults.isHidden = true
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager){
        let currentCLLocation = locationManager.location
        var targetCLLCoordinate2D: CLLocationCoordinate2D?
        
        switch self.locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            targetCLLCoordinate2D = CLLocationCoordinate2D(
                latitude: currentCLLocation!.coordinate.latitude,
                longitude: currentCLLocation!.coordinate.longitude)
            
            let targetRegion = MKCoordinateRegion(
                center: targetCLLCoordinate2D!,
                latitudinalMeters: self.viewSize,
                longitudinalMeters: self.viewSize
            )
            mapView.setRegion(targetRegion, animated: true)
        default:
            manager.stopUpdatingLocation()
            targetCLLCoordinate2D = CLLocationCoordinate2D(latitude: 30.2862, longitude: -97.7394)
            let defaultRegion = MKCoordinateRegion(
                center: targetCLLCoordinate2D!,
                latitudinalMeters: self.viewSize,
                longitudinalMeters: self.viewSize
            )
            mapView.setRegion(defaultRegion, animated: true)
        }
        
        self.currentCLLCordinate2d = targetCLLCoordinate2D
    }
    
    func getSearchResults(addressString: String) async {
        self.searchFieldLocations = self.locations.filter { location in
            location.title?.contains(addressString) ?? false
        }
        self.searchResults.reloadData()
        
        let targetRegion = MKCoordinateRegion(
            center: self.currentCLLCordinate2d!,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = addressString
        request.region = targetRegion
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .bakery,
            .brewery,
            .cafe,
            .distillery,
            .foodMarket,
            .restaurant,
            .winery
        ])
        
        
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            for item in response.mapItems {
                guard let name = item.name else { continue }
                // need to filter out names with weird characters
                let coordinate = item.location.coordinate
                let locationId = makeLocationId(lat: coordinate.latitude, lon: coordinate.longitude, name: name)
                let result = DiscoverPin(coordinate: item.location.coordinate, title: name, subtitle: item.address?.fullAddress, address: item.address?.fullAddress, locationId: locationId, PostId: "NoPostAssociated")
                self.searchFieldLocations.append(result)
            }
            DispatchQueue.main.async {
                self.searchResults.reloadData()
            }
        } catch {
            print("serach failed")
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchFieldLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)
        var content = cell.defaultContentConfiguration( )
        let LocationAnnot = searchFieldLocations[indexPath.row]
        content.text = LocationAnnot.title
        content.secondaryText = LocationAnnot.address
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchFieldLocations[indexPath.row]

        if let existingPin = self.locations.first(where: { $0.locationId == result.locationId }) {
            let region = MKCoordinateRegion(
                center: existingPin.coordinate,
                latitudinalMeters: viewSize,
                longitudinalMeters: viewSize
            )
            mapView.setRegion(region, animated: true)
            
            searchResults.isHidden = true
            selectedAnnot = existingPin
            return
        }

        let tempPin = DiscoverPin(
            coordinate: result.coordinate,
            title: result.title,
            subtitle: result.subtitle,
            address: result.address,
            locationId: result.locationId,
            PostId: "NoPostAssociated"
        )
        mapView.addAnnotation(tempPin)

        let region = MKCoordinateRegion(
            center: result.coordinate,
            latitudinalMeters: viewSize,
            longitudinalMeters: viewSize
        )
        mapView.setRegion(region, animated: true)
        searchResults.isHidden = true
        selectedAnnot = tempPin
    }
    
    private func mapView(_ mapView: MKMapView, didSelect view: DiscoverPin) {
        selectedAnnot = view
        
        viewSize = 500
        guard let annotation = selectedAnnot else { return }
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    
        guard let annotation = view.annotation as? DiscoverPin else { return }
        self.selectedAnnot = annotation
        viewSize = 500
        
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
        //self.moreInfoButton.isEnabled = true
    }

    
    @IBAction func confirmPressedNew(_ sender: Any) {
        guard let coordinate = selectedAnnot?.coordinate else {
            let alert = UIAlertController(title: "No Location",
                                                    message: "Please select location on the map",
                                                    preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        discoverDelegate?.didSelectLocation(selectedLatitude: coordinate.latitude, selectedLongitude: coordinate.longitude,  selectedName: selectedAnnot?.title ?? "", address: selectedAnnot?.address ?? "")

        dismiss(animated: true)
    }
    
    
    
    func loadPins() {
        var publicUsers: [String] = []
        var privateUsers: [String] = []
        
        var DiscoverPins: [DiscoverPin] = []
        
        var ref: DatabaseReference!
        ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value) { snapshot in
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let userDict = childSnapshot.value as? [String: Any] {
                    
                    let isPrivateValue = userDict["isPrivate"] as? Int ?? 0
                    let isPrivate = isPrivateValue != 0
                    
                    if !isPrivate {
                        publicUsers.append(childSnapshot.key)
                    }
                    privateUsers.append(childSnapshot.key)
                }
            }
            
            print("Public users: \(publicUsers)")
        }
        
        ref = Database.database().reference().child("posts")
        ref.observeSingleEvent(of: .value) { snapshot in
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let postId = dict["postId"] as? String,
                   let userId = dict["userId"] as? String,
                   let locationId = dict["locationId"] as? String {
                    
                    if publicUsers.contains(userId) {
                        let locationRef = Database.database().reference().child("locations").child(locationId)
                        locationRef.observeSingleEvent(of: .value) { locationSnap in
                            if let dict = locationSnap.value as? [String: Any],
                               let address = dict["address"] as? String,
                               let name = dict["name"] as? String,
                               let coordinates = dict["coordinates"] as? [String: Double],
                               let lat = coordinates["latitude"],
                               let lon = coordinates["longitude"] {
                                
                                
                                DispatchQueue.main.async {
                                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                    let pin = DiscoverPin(coordinate: coordinate, title: name, subtitle: address, address: address, locationId: locationId, PostId: postId)
                                    DiscoverPins.append(pin)
                                    print(pin)
                                    for Pin in DiscoverPins {
                                        self.mapView.addAnnotation(Pin)
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                }
            }
        }
        
        
    }
    
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        if(fromAddPost){
            let point = gesture.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
                if let prev = selectedAnnot {
                    mapView.removeAnnotation(prev)
                }
                
                let alert = UIAlertController(title: "Name this location",
                                              message: nil,
                                              preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.placeholder = "Location name"
                }

                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    let name = alert.textFields?.first?.text ?? "Custom Location"
                    let pin = DiscoverPin(
                        coordinate: coordinate,
                        title: name,
                        subtitle: "Custom User Pin",
                        address: "",
                        locationId: self.makeLocationId(lat: coordinate.latitude, lon: coordinate.longitude, name: name),
                        PostId: "NoPostAssociated"
                    )
                    self.selectedAnnot = pin
                    self.mapView.addAnnotation(pin)
                })
                self.present(alert, animated: true)
        }else {
            print("hi")
        }
    }

    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let identifier = "LocationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? DiscoverPin {
            print("nice try")
            if annotation.PostId == "NoPostAssociated" || isSelectingLocation {
                return
            } else {
                self.selectedAnnot = annotation
                performSegue(withIdentifier: "discoverToLocation", sender: annotation)
            }
            
        }
    }


    
    func makeLocationId(lat: Double, lon: Double, name: String) -> String {
        let lat = String(format: "%.4f", lat).replacingOccurrences(of: ".", with: "_")
        let lon = String(format: "%.4f", lon).replacingOccurrences(of: ".", with: "_")
        let locationId = "\(name);\(lat);\(lon)"
        return locationId
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "discoverToLocation",
           let destination = segue.destination as? FoodLocationViewController,
           let selectedAnnot = selectedAnnot {
            
            
            destination.locationId = selectedAnnot.locationId
            destination.delegate = self
        }
    }
}


