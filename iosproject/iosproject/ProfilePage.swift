//
//  ProfilePage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/17/25.
//

import UIKit


import UIKit
import MapKit

class Post: UICollectionViewCell {
    @IBOutlet weak var singlePost: UIImageView!
    
}



class ProfilePage: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UITableViewDelegate, UITableViewDataSource {
    
    
    var posts: [UIImage] = [UIImage(named: "foocation logo")!, UIImage(named: "houseLogo")!]
    
    @IBOutlet weak var optionsBar: UISegmentedControl!
    
    @IBOutlet weak var gridOfPosts: UICollectionView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    @IBOutlet weak var friendsList: UITableView!
    
    let textCellIdentifier = "CellView"
    
    public var tempFriends = ["Isaac", "Ian", "Austin"]
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gridOfPosts.dataSource = self
        gridOfPosts.delegate = self
        friendsList.dataSource = self
        friendsList.delegate = self
        let layout = UICollectionViewFlowLayout()
            let itemWidth = (gridOfPosts.bounds.width - 20) / 3
            layout.itemSize = CGSize(width: itemWidth - 5, height: itemWidth - 5)
            layout.minimumInteritemSpacing = 5
            layout.minimumLineSpacing = 5
            layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        gridOfPosts.collectionViewLayout = layout
        optionsBar.selectedSegmentIndex = 0

        // Do any additional setup after loading the view.
        mapView.isHidden = true // Hide map initially
                // Set a default map region (e.g., Austin, TX as an example)
                let initialLocation = CLLocationCoordinate2D(latitude: 30.2862, longitude: -97.7394) // Austin, TX
                let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
                mapView.setRegion(region, animated: false)
        friendsList.isHidden = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = gridOfPosts.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! Post
        cell.singlePost.image = posts[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20) / 3 - 5
        return CGSize(width: width, height: width)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tempFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for:indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = tempFriends[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
  
    
    @IBAction func choosingTab(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                gridOfPosts.isHidden = false
            mapView.isHidden = true
            friendsList.isHidden = true
            gridOfPosts.reloadData()
            case 1:
            gridOfPosts.isHidden = true
                        mapView.isHidden = false
            friendsList.isHidden = true
            case 2:
            mapView.isHidden = true
            gridOfPosts.isHidden = true
            friendsList.isHidden = false
            
            default:
            gridOfPosts.isHidden = true
            }
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
