//
//  ProfilePage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/17/25.
//

import UIKit
import SDWebImage

import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase


class Post: UICollectionViewCell {
    @IBOutlet weak var singlePost: UIImageView!
}

class ProfilePage: ModeViewController, UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var userNameField: UILabel!
    
    @IBOutlet weak var bioField: UILabel!
    
    var posts: [FeedPost] = []
    
    @IBOutlet weak var optionsBar: UISegmentedControl!
    
    @IBOutlet weak var gridOfPosts: UICollectionView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var friendsList: UITableView!
    
    let textCellIdentifier = "CellView"
    
    public var tempFriends = ["Isaac", "Ian", "Austin"]
    public var friendUIDs: [String] = []

    var chosenFriend: String?
    var chosenFriendIndex = 0
    
    var selectedPostImage: UIImage?
    var selectedPostIndex: Int = 0
    
    @IBOutlet weak var editProfileButton: UIButton!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        gridOfPosts.dataSource = self
        gridOfPosts.delegate = self
        friendsList.dataSource = self
        friendsList.delegate = self
        
        let curUser = Auth.auth().currentUser!.uid
        var ref : DatabaseReference!
        ref = Database.database().reference().child("users").child(curUser)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "username").value as? String {
                self.userNameField.text = username
            }
            if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                self.bioField.text = bio
            }
        }
        
        ref = Database.database().reference().child("posts")
            ref.observeSingleEvent(of: .value) { snapshot in
                var feedPosts: [FeedPost] = []

                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let dict = childSnapshot.value as? [String: Any],
                       let postUserId = dict["userId"] as? String,
                       postUserId == curUser {
                        let postId = dict["postId"] as? String ?? childSnapshot.key
                        // let username = dict["username"] as? String ?? ""
                        let imageUrl = dict["image"] as? String ?? ""
                        let timestamp = dict["timestamp"] as? Double ?? 0
                        let likeCount = (dict["likes"] as? [String])?.count ?? 0

                        let commentsArray = dict["comments"] as? [[String: Any]] ?? []
                        let commentObjs = commentsArray.compactMap { Comment.from(dict: $0) }

                        let location = dict["location"] as? String ?? ""
                        let caption = dict["caption"] as? String ?? ""
                        
                        // Store imageUrl in FeedPost; do NOT download image here
                        let post = FeedPost(
                            postId: postId,
                            userId: postUserId,
                            imageUrl: imageUrl, // Assuming FeedPost now has an imageUrl property
                            timestamp: Int(timestamp),
                            likeCount: likeCount,
                            comments: commentObjs,
                            location: location,
                            caption: caption
                        )
                        feedPosts.append(post)
                    }
                }

                DispatchQueue.main.async {
                    self.posts = feedPosts
                    self.gridOfPosts.reloadData()
                }
            }
        
           ref = Database.database().reference().child("users").child(curUser)
           ref.child("friends").observe(.value) { snapshot in
               var loadedFriends: [String] = []
               var friendUIDs: [String] = []
               print("Checking friends for user: \(curUser)")
               print("Snapshot: \(snapshot.value ?? "No friends")")
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
                   self.friendsList.reloadData()
               }
           }
        
        let layout = UICollectionViewFlowLayout()
                layout.minimumInteritemSpacing = 0
                layout.minimumLineSpacing = 0
                layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                gridOfPosts.collectionViewLayout = layout
                optionsBar.selectedSegmentIndex = 0

        // Do any additional setup after loading the view.
        mapView.isHidden = true
                let initialLocation = CLLocationCoordinate2D(latitude: 30.2862, longitude: -97.7394)
                let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
                mapView.setRegion(region, animated: false)
        friendsList.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let curUser = Auth.auth().currentUser!.uid
        let ref = Database.database().reference().child("users").child(curUser)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "username").value as? String {
                self.userNameField.text = username
            }
            if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                self.bioField.text = bio
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = gridOfPosts.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! Post
        
        // Use SDWebImage to load images asynchronously from URL with placeholder
        let imageUrlString = posts[indexPath.item].imageUrl
        if let imageUrlString = imageUrlString, let url = URL(string: imageUrlString) {
            cell.singlePost.sd_setImage(with: url, placeholderImage: UIImage(named: "dark-placeholder"))
        } else {
            cell.singlePost.image = UIImage(named: "dark-placeholder")
        }
        
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
        self.selectedPostIndex = indexPath.row
        performSegue(withIdentifier: "profileToPost", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profileToPost", let vc = segue.destination as? PostPage {
            vc.post = posts[selectedPostIndex]
        }
        if segue.identifier == "toOtherProfile", let vc = segue.destination as? OtherProfilePage {
            vc.otherUserNameText = "THIS IS THE TEMP PAGE FOR THE OTHER PROFILES"
            vc.otherUserID = friendUIDs[chosenFriendIndex]
        }
//        if segue.identifier == "profileToEditProfile", let vc = segue.destination as? EditProfileViewController {
//        }
        
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
        tableView.deselectRow(at: indexPath, animated: true)
        chosenFriend = tempFriends[indexPath.row]
        chosenFriendIndex = indexPath.row
        // let chosenFriendID = friendUIDs[indexPath.row]
        
        let alertController = UIAlertController(title: "Friend Action", message: "Select an action to perform for \(chosenFriend!)", preferredStyle: .actionSheet)
        
        let viewProfileAction = UIAlertAction(title: "View Profile", style: .default){ _ in
            self.performSegue(withIdentifier: "toOtherProfile", sender: self)
        }
        
        let removeFriendAction = UIAlertAction(title: "Remove Friend", style: .destructive){ _ in
            self.removeFriend(chosenFriend: self.chosenFriend!)
        }
        
        alertController.addAction(viewProfileAction)
        alertController.addAction(removeFriendAction)
        
        alertController.preferredAction = viewProfileAction
        present(alertController, animated: true)
    }
    
    func removeFriend(chosenFriend: String) {
        guard let curUser = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()
        ref.child("users").child(curUser).child("friends").child(chosenFriend).removeValue { error, _ in
            if let error = error {
                print("Error removing friend: \(error.localizedDescription)")
            } else {
                print("Friend removed successfully from user's list.")
                // remove user from friend's friends
                ref.child("users").child(chosenFriend).child("friends").child(curUser).removeValue { error, _ in
                    if let error = error {
                        print("Error removing user from friend's list: \(error.localizedDescription)")
                    } else {
                        print("User removed successfully from friend's list.")
                
                        DispatchQueue.main.async {
                            self.friendsList.reloadData()
                        }
                    }
                }
            }
        }
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
    
    @IBAction func editProfilePressed(_ sender: Any) {
        performSegue(withIdentifier: "profileToEditProfile", sender: self)
        
    }
    
}
