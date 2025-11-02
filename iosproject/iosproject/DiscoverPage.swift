//
 //  DiscoverPage.swift
 //  iosproject
 //
 //  Created by Austin Nguyen on 10/17/25.
 //

import UIKit
import MapKit
import CoreLocation


struct RestaurantPin{
    var name : String
    var location : CLLocationCoordinate2D
}

class DiscoverPage : ModeViewController, MKMapViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var searchResults: UITableView!
    var searchText:String = ""
    
    @IBOutlet weak var confirmLocationButton: UIButton!

    var searchFieldLocations: [RestaurantPin] = []
    
    var locations:[RestaurantPin] = []
    var viewSize:Double = 500
    var currentView: MKAnnotationView!
    
    var selectedCoordinate: CLLocationCoordinate2D?
    
    var discoverDelegate: AddPostViewController?
    var isSelectingLocation: Bool = false
    
    
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
            print("wow")
        } else {
            confirmLocationButton.isHidden = true
        }
        reloadAnnotations()
        
    }
    
    func searchBar(_ searchField: UISearchBar, textDidChange text: String) {
        self.searchText = searchField.searchTextField.text!
        searchResults.isHidden = false
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
                let result = RestaurantPin(name: name, location: item.location.coordinate)
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
        if isSelectingLocation {
            selectedCoordinate = searchFieldLocations[indexPath.row].location
        }
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(
            center: searchFieldLocations[indexPath.row].location,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
        searchResults.isHidden = true
    }
    
    func reloadAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        for location in locations{
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.location
            annotation.title = location.name
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if isSelectingLocation {
            selectedCoordinate = view.annotation?.coordinate
        }
        viewSize = 500
        currentView = view
        setAnnotationRegion()
        
    }
    
    func setAnnotationRegion() {
        guard let annotation = currentView?.annotation else { return }
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
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
        discoverDelegate?.didSelectLocation(selectedLatitude: coordinate.latitude, selectedLongitude: coordinate.longitude)
                
        dismiss(animated: true)
 
    }
    
}
