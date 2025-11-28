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

    var delegate: UIViewController?
    var locationId: String?
    var currentAnnotation: DiscoverPin?
    let ref = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard var id = locationId else { return }
        id = id.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        print(id)

        let invalidChars = CharacterSet(charactersIn: ".#$[]")
        guard !id.isEmpty, id.rangeOfCharacter(from: invalidChars) == nil else {
            print("Invalid Firebase path after cleaning: \(id)")
            return
        }
        addPin(paramId: id)
    }

    func addPin(paramId: String) {
        let invalidChars = CharacterSet(charactersIn: ".#$[]")
        if paramId.isEmpty || paramId.rangeOfCharacter(from: invalidChars) != nil {
            print("Invalid Firebase path: \(paramId)")
            return
        }

        ref.child("locations").child(paramId).observeSingleEvent(of: .value) { snapshot, error in
            guard let dict = snapshot.value as? [String: Any],
                  let coords = dict["coordinates"] as? [String: Any],
                  let lat = coords["latitude"] as? Double,
                  let lon = coords["longitude"] as? Double else {
                print("Invalid or missing data for location \(paramId)")
                return
            }

            let name = dict["name"] as? String ?? "Unknown"
            let address = dict["address"] as? String ?? "No Address"
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            let annotation = DiscoverPin(
                coordinate: coordinate,
                title: name,
                subtitle: address,
                address: address,
                locationId: paramId,
                PostId: "Placeholder"
            )

            DispatchQueue.main.async {
                self.mapView.addAnnotation(annotation)
                self.currentAnnotation = annotation

                let region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                self.mapView.setRegion(region, animated: true)

                self.nameLabel.text = name
                self.addressValue.text = address
            }
        }
    }
}

