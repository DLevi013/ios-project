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

struct RestaurantPin{
    var name : String
    var location : CLLocationCoordinate2D
    var address : String
}

class DiscoverPage : ModeViewController, MKMapViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var searchResults: UITableView!
    var searchText:String = ""
    // stores search results, may be empty
    var searchFieldLocations: [RestaurantPin] = []
    
    var discoverDelegate: AddPostViewController?
    var isSelectingLocation: Bool = false
    var selectedCoordinate: CLLocationCoordinate2D?
    var selectedName: String?
    var selectedAddress: String?
    var locationId: String?
    @IBOutlet weak var confirmLocationButton: UIButton!

    var locations:[RestaurantPin] = []
    var viewSize:Double = 500
    var currentView: MKAnnotationView?
        
    let ref = Database.database().reference()
    @IBOutlet weak var moreInfoButton: UIButton!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        mapView.delegate = self
        searchField.delegate = self
        searchResults.delegate = self
        searchResults.dataSource = self
        searchResults.rowHeight = UITableView.automaticDimension
        
        searchResults.isHidden = true
        if self.isSelectingLocation {
            confirmLocationButton.isHidden = false
        } else {
            confirmLocationButton.isHidden = true
        }
        //moreInfoButton.isEnabled = false
        loadLocations()
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
    
    func getSearchResults(addressString: String) async {
        var targetRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 97.7394, longitude: 97.7394),
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        self.searchFieldLocations = []
        if let userLocation = mapView.userLocation.location {
            targetRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: self.viewSize,
                longitudinalMeters: self.viewSize
            )
        } else {
            print("User location not available")
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = addressString
        request.region = targetRegion
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            for item in response.mapItems {
                guard let name = item.name else { continue }
                // need to filter out names with weird characters
                let result = RestaurantPin(name: name, location: item.location.coordinate, address: item.address?.fullAddress ?? "")
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
        content.text = searchFieldLocations[indexPath.row].name
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = searchFieldLocations[indexPath.row].location
        annotation.title = searchFieldLocations[indexPath.row].name
        annotation.subtitle = searchFieldLocations[indexPath.row].address
        
        selectedCoordinate = searchFieldLocations[indexPath.row].location
        selectedName = searchFieldLocations[indexPath.row].name
        selectedAddress = searchFieldLocations[indexPath.row].address
        
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(
            center: searchFieldLocations[indexPath.row].location,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
        searchResults.isHidden = true
        moreInfoButton.isEnabled = true
        view.bringSubviewToFront(moreInfoButton)

    }
    
    func loadLocations() {
        ref.child("locations").observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any] {
                    
                    self.locationId = childSnapshot.key
                    let name = dict["name"] as? String ?? ""
                    let address = dict["address"] as? String ?? ""
                    
                    if let coords = dict["coordinates"] as? [String: Any],
                       let lat = coords["latitude"] as? Double,
                       let lon = coords["longitude"] as? Double {
                        
                        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        self.locations.append(RestaurantPin(name: name, location: coordinate, address: address))
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = coordinate
                        annotation.title = name
                        annotation.subtitle = address
                        
                        self.mapView.addAnnotation(annotation)
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    
        if let annotation = view.annotation {
            selectedCoordinate = annotation.coordinate
            selectedName = annotation.title ?? "Unknown"
            selectedAddress = annotation.subtitle ?? "No Address"
        }

        
        viewSize = 500
        guard let annotation = view.annotation else { return }
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
        self.moreInfoButton.isEnabled = true
    }
    
    @IBAction func moreInfoPressed(_ sender: Any) {
        performSegue(withIdentifier: "discoverToLocation", sender: self)
    }
    
    @IBAction func confirmLocationPressed(_ sender: Any) {
        guard let coordinate = selectedCoordinate else {
            let alert = UIAlertController(title: "No Location",
                                                    message: "Please select location on the map",
                                                    preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        discoverDelegate?.didSelectLocation(selectedLatitude: coordinate.latitude, selectedLongitude: coordinate.longitude,  selectedName: selectedName!, address: selectedAddress!)
                
        dismiss(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "discoverToLocation",
              let destination = segue.destination as? FoodLocationViewController {
               destination.name = selectedName!
               destination.address = selectedAddress!
               destination.delegate = self
               //destination.locationId = locationId!
           }
       }

}
