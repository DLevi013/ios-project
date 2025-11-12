//
//  FoodLocationViewController.swift
//  iosproject
//
//  Created by Austin Nguyen on 11/11/25.
//

import UIKit
import FirebaseDatabase
import MapKit


class FoodLocationViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressValue: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var name: String = ""
    var address: String = ""
    var delegate : UIViewController?
    var locationId: String = ""
    
    let ref = Database.database().reference()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameLabel.text = name
        addressValue.text = address
    }
    
    func addPin(locationId: String) {
        ref.child("locations").child(locationId).observeSingleEvent(of: .value) { snapshot in
            guard let dict = snapshot.value as? [String: Any],
                  let coords = dict["coordinates"] as? [String: Any],
                  let lat = coords["latitude"] as? Double,
                  let lon = coords["longitude"] as? Double else {
                print("Invalid or missing data for location \(locationId)")
                return
            }

            let name = dict["name"] as? String ?? "Unknown"
            let address = dict["address"] as? String ?? "No Address"
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = name
            annotation.subtitle = address
            self.mapView.addAnnotation(annotation)
        }
    }
    

}
