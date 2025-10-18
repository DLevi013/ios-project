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

class DiscoverPage : UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var searchField: UISearchBar!
    
    
    var locations:[TemporaryPost] = []
    var viewSize:Double = 500
    var currentView: MKAnnotationView!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        mapView.delegate = self
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

        locations.append(TemporaryPost(name:"Tower", location: CLLocationCoordinate2D(latitude: 30.28565,longitude: -97.73921)))
    }

    
  
    @IBAction func filterPressed(_ sender: Any) {
        //reloadAnnotations()
    }
    
    @IBAction func plusPressed(_ sender: Any) {
        viewSize -= 100
        guard let annotation = self.currentView.annotation else { return }
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
    }
    @IBAction func minusPressed(_ sender: Any) {
        viewSize += 100
        guard let annotation = self.currentView.annotation else { return }

        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        mapView.setRegion(region, animated: true)
    }
}

extension DiscoverPage: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        self.viewSize = 500
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: self.viewSize,
            longitudinalMeters: self.viewSize
        )
        self.currentView = view
        mapView.setRegion(region, animated: true)
    }
}
