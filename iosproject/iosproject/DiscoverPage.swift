//
 //  DiscoverPage.swift
 //  iosproject
 //
 //  Created by Austin Nguyen on 10/17/25.
 //

import UIKit
import MapKit

struct TemporaryPost{
    var name : String
    var location : CLLocationCoordinate2D
}

class DiscoverPage : UIViewController, MKMapViewDelegate, UISearchBarDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchField: UISearchBar!
    
    var locations:[TemporaryPost] = []
    var viewSize:Double = 500
    var currentView: MKAnnotationView!
    var searchText:String = ""
    
    func searchBar(_ searchField: UISearchBar, textDidChange text: String) {
        self.searchText = searchField.searchTextField.text!
        print(searchText)
        let list = self.locations.map { post in post.name }
        let results = list.filter { $0.lowercased().contains(searchText.lowercased()) }
        if !results.isEmpty{
            print(results[0])
        }
    }
    
    func searchBarSearchButtonClicked(_ searchField: UISearchBar){
        print("Pressed")
        let annotation = MKPointAnnotation()
        var match: TemporaryPost = self.locations[0]
        for post in self.locations {
            if post.name.lowercased().contains(searchText.lowercased()) {
                print(true)
                match = post
            }
        }
        annotation.coordinate = match.location
        annotation.title = match.name
        changeAnnotationRegion(annotation:   annotation)
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        mapView.delegate = self
        searchField.delegate = self
        
        //getMarkers()
        
        temporaryLocations()
        reloadAnnotations()
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

    func temporaryLocations(){
        locations.append(TemporaryPost(name:"Tower", location: CLLocationCoordinate2D(latitude: 30.28565,longitude: -97.73921)))
        locations.append(TemporaryPost(name:"Union", location: CLLocationCoordinate2D(latitude: 30.28663,longitude: -97.74116)))

        locations.append(TemporaryPost(name:"Tower", location: CLLocationCoordinate2D(latitude: 30.28361,longitude: -97.73650)))
    }
  
    @IBAction func filterPressed(_ sender: Any) {
        //reloadAnnotations()
    }
    
    @IBAction func plusPressed(_ sender: Any) {
        viewSize -= 100
        setAnnotationRegion()
    }
    @IBAction func minusPressed(_ sender: Any) {
        viewSize += 100
        setAnnotationRegion()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.viewSize = 500
        self.currentView = view
        setAnnotationRegion()
    }
    
    // change later,
    func changeAnnotationRegion(annotation: MKAnnotation) {
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
    }
    
    func setAnnotationRegion() { // ? change to annotation ?
        guard let annotation = self.currentView.annotation else { return }
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
    }
    
}

