//
//  OtherProfilePage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/22/25.
//

import UIKit
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class OtherPost: UICollectionViewCell {
    @IBOutlet weak var otherSinglePost: UIImageView!
    
}



class OtherProfilePage: ModeViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UITableViewDelegate, UITableViewDataSource  {

    
    var otherUserNameText = ""
    var otherUserID = ""
    @IBOutlet weak var otherUserName: UILabel!
    
    @IBOutlet weak var otherBio: UILabel!
    
    @IBOutlet weak var otherOptionsBar: UISegmentedControl!
    
    @IBOutlet weak var otherGridOfPosts: UICollectionView!
    
    
    @IBOutlet weak var otherMapView: MKMapView!
    
    @IBOutlet weak var otherFriendsList: UITableView!
    
    let textCellIdentifier = "CellView"
    
    public var tempFriends = ["Isaac", "Ian", "Austin"]
    public var friendUIDs: [String] = []

    var nextFriend : String = ""
    var chosenFriend: String?
    var chosenFriendIndex = 0
    
    var posts: [UIImage] = [UIImage(named: "gsWithSoup")!, UIImage(named: "halfEaten")!,UIImage(named: "parisChoco")!,UIImage(named: "parisMatcha")!]
    
    var otherSelectedPostImage: UIImage?
    var otherSelectedPostIndex: Int = 0
    var isPrivate:Bool = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        otherGridOfPosts.dataSource = self
        otherGridOfPosts.delegate = self
        otherFriendsList.delegate = self
        otherFriendsList.dataSource = self

        
        // otherUserName.text = otherUserNameText
        let db = Firestore.firestore()
        var ref : DatabaseReference!
        ref = Database.database().reference().child("users").child(otherUserID)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "username").value as? String {
                self.otherUserName.text = username
            }
            if let isPrivate = snapshot.childSnapshot(forPath: "isPrivate").value as? Bool, isPrivate {
                // private profile
                self.isPrivate = true
                self.setProfilePrivate()
                self.otherMapView.isHidden = true
                self.otherFriendsList.isHidden = true
                self.otherGridOfPosts.isHidden = true
                self.otherOptionsBar.isHidden = true
                
            } else {
                // later on, setProfilePublic will handle populating the the profile with data
                // consider making this code simple later
                if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                    self.setProfilePublic(bio: bio)
                }
            }

        }
        
        ref.child("friends").observeSingleEvent(of: .value) { snapshot in
            var loadedFriends: [String] = []
            var friendUIDs: [String] = []
            
            for child in snapshot.children {
                if let friendSnap = child as? DataSnapshot {
                    let friendName = friendSnap.key
                    let friendID = friendSnap.value as? String ?? ""
                    loadedFriends.append(friendName)
                    friendUIDs.append(friendID)
                }
            }
            
            self.tempFriends = loadedFriends
            self.friendUIDs = friendUIDs
            DispatchQueue.main.async {
                self.otherFriendsList.reloadData()
            }
        }
        
        let layout = UICollectionViewFlowLayout()
                layout.minimumInteritemSpacing = 0
                layout.minimumLineSpacing = 0
                layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                otherGridOfPosts.collectionViewLayout = layout
                otherOptionsBar.selectedSegmentIndex = 0

        let initialLocation = CLLocationCoordinate2D(latitude: 30.2862, longitude: -97.7394)
        let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
        otherMapView.setRegion(region, animated: false)
        
        print(otherUserID)

        // Do any additional setup after loading the view.
    }
    
    // function for setting profiles based on private or public
    func setProfilePrivate() {
        self.otherBio.text = "This user is private."
    }
    
    func setProfilePublic(bio: String) {
        self.otherBio.text = bio
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = otherGridOfPosts.dequeueReusableCell(withReuseIdentifier: "OtherPostCell", for: indexPath) as! OtherPost
        cell.otherSinglePost.image = posts[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3.0
                let totalSpacing: CGFloat = 0.0
                let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
                return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        self.otherSelectedPostImage = posts[indexPath.row]
            self.otherSelectedPostIndex = indexPath.row
        performSegue(withIdentifier: "otherProfileToPost", sender: self)
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "otherProfileToPost", let vc = segue.destination as? PostPage {
            vc.selectedPostImage = otherSelectedPostImage.self
            vc.selectedPostIndex = otherSelectedPostIndex.self
            vc.userID = otherUserName.text!
        }
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Row selected: \(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
        chosenFriend = tempFriends[indexPath.row]
        chosenFriendIndex = indexPath.row
        let chosenFriendID = friendUIDs[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let newVC = storyboard.instantiateViewController(withIdentifier: "OtherProfilePage") as? OtherProfilePage {
                newVC.otherUserID = chosenFriendID
                newVC.otherUserNameText = tempFriends[indexPath.row]
                self.present(newVC, animated: true, completion: nil)
            }

    }
    
    
    @IBAction func otherChooseTab(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                otherGridOfPosts.isHidden = false
            otherMapView.isHidden = true
            otherFriendsList.isHidden = true
            otherGridOfPosts.reloadData()
            case 1:
            otherGridOfPosts.isHidden = true
            otherMapView.isHidden = false
            otherFriendsList.isHidden = true
            case 2:
            otherGridOfPosts.isHidden = true
            otherMapView.isHidden = true
            otherFriendsList.isHidden = false
            default:
            otherGridOfPosts.isHidden = false
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
