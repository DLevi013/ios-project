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

class OtherProfilePage: ModeViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var otherUserName: UILabel!
    @IBOutlet weak var otherBio: UILabel!
    @IBOutlet weak var otherOptionsBar: UISegmentedControl!
    @IBOutlet weak var otherGridOfPosts: UICollectionView!
    @IBOutlet weak var otherMapView: MKMapView!
    @IBOutlet weak var otherFriendsList: UITableView!
    @IBOutlet weak var addFriendButton: UIButton!
    
    var otherUserNameText = ""
    var otherUserID = ""
    let textCellIdentifier = "CellView"
    public var tempFriends = ["Isaac", "Ian", "Austin"]
    public var friendUIDs: [String] = []
    var nextFriend: String = ""
    var chosenFriend: String?
    var chosenFriendIndex = 0
    var posts: [FeedPost] = []
    var otherSelectedPostImage: UIImage?
    var otherSelectedPostIndex: Int = 0
    var isPrivate: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        friendCheck()
        otherGridOfPosts.dataSource = self
        otherGridOfPosts.delegate = self
        otherFriendsList.delegate = self
        otherFriendsList.dataSource = self

        var ref: DatabaseReference!
        ref = Database.database().reference().child("users").child(otherUserID)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "username").value as? String {
                self.otherUserName.text = username
            }
            if let isPrivate = snapshot.childSnapshot(forPath: "isPrivate").value as? Bool, isPrivate {
                self.isPrivate = true
                self.setProfilePrivate()
                self.otherMapView.isHidden = true
                self.otherFriendsList.isHidden = true
                self.otherGridOfPosts.isHidden = true
                self.otherOptionsBar.isHidden = true
            } else {
                if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                    self.setProfilePublic(bio: bio)
                }
                ref = Database.database().reference().child("posts")
                ref.observeSingleEvent(of: .value) { snapshot in
                    var feedPosts: [FeedPost] = []
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot,
                           let dict = childSnapshot.value as? [String: Any],
                           let postUserId = dict["userId"] as? String,
                           postUserId == self.otherUserID {
                            let postId = dict["postId"] as? String ?? childSnapshot.key
                            // let username = dict["username"] as? String ?? ""
                            let imageUrl = dict["image"] as? String ?? ""
                            let timestamp = dict["timestamp"] as? Double ?? 0
                            let likeCount = (dict["likes"] as? [String])?.count ?? 0
                            let commentsArray = dict["comments"] as? [[String: Any]] ?? []
                            let commentObjs = commentsArray.compactMap { Comment.from(dict: $0) }
                            let location = dict["location"] as? String ?? ""
                            let caption = dict["caption"] as? String ?? ""
                            
                            UsernameCache.shared.getUsername(for: postUserId) { username in
                                if let url = URL(string: imageUrl) {
                                    URLSession.shared.dataTask(with: url) { data, _, _ in
                                        if let data = data, let image = UIImage(data: data) {
                                            DispatchQueue.main.async {
                                                let post = FeedPost(
                                                    postId: postId,
                                                    userId: postUserId,
                                                    username: username ?? "Anonymous",
                                                    postImage: image,
                                                    timestamp: Int(timestamp),
                                                    likeCount: likeCount,
                                                    comments: commentObjs,
                                                    location: location,
                                                    caption: caption
                                                )
                                                feedPosts.append(post)
                                                self.posts = feedPosts
                                                self.otherGridOfPosts.reloadData()
                                            }
                                        }
                                    }.resume()
                                } else {
                                    print("No post found!")
                                }
                            }
                        }
                            
                            
                    }
                    DispatchQueue.main.async {
                        self.posts = feedPosts
                        self.otherGridOfPosts.reloadData()
                    }
                }
            }
        }
        ref = Database.database().reference().child("users").child(otherUserID)
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
    }

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
        cell.otherSinglePost.image = posts[indexPath.item].postImage
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
        self.otherSelectedPostIndex = indexPath.row
        performSegue(withIdentifier: "otherProfileToPost", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "otherProfileToPost", let vc = segue.destination as? PostPage {
            vc.post = posts[otherSelectedPostIndex]
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tempFriends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath)
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

    @IBAction func addFriendTapped(_ sender: Any) {
        let currentUserID = Auth.auth().currentUser!.uid
        let ref = Database.database().reference()
        let currentUserRef = ref.child("users").child(currentUserID)
        let otherUserRef = ref.child("users").child(otherUserID)
        currentUserRef.child("username").observeSingleEvent(of: .value) { snapshot in
            let currentUsername = snapshot.value as? String ?? "Unknown"
            otherUserRef.child("username").observeSingleEvent(of: .value) { otherSnap in
                let otherUsername = otherSnap.value as? String ?? "Unknown"
                let updates = [
                    "users/\(currentUserID)/friends/\(otherUsername)": self.otherUserID,
                    "users/\(self.otherUserID)/friends/\(currentUsername)": currentUserID
                ]
                ref.updateChildValues(updates) { error, _ in
                    if let error = error {
                        print("Error in adding friend", error.localizedDescription)
                    } else {
                        print("Added Friend!")
                        DispatchQueue.main.async {
                            self.addFriendButton.isHidden = true
                        }
                    }
                }
            }
        }
    }

    func friendCheck() {
        addFriendButton.isHidden = false
        let db = Database.database().reference()
        let currentUserID = Auth.auth().currentUser!.uid
        let friendsRef = db.child("users").child(currentUserID).child("friends")
        friendsRef.observeSingleEvent(of: .value) { snapshot in
            var isFriend = false
            for child in snapshot.children {
                if let friendSnap = child as? DataSnapshot,
                   let friendUID = friendSnap.value as? String,
                   friendUID == self.otherUserID {
                    isFriend = true
                    break
                }
            }
            DispatchQueue.main.async {
                if isFriend {
                    self.addFriendButton.isEnabled = false
                    self.addFriendButton.isHidden = true
                } else {
                    self.addFriendButton.setTitle("Add Friend", for: .normal)
                    self.addFriendButton.isEnabled = true
                    self.addFriendButton.isHidden = false
                }
            }
        }
    }
}
