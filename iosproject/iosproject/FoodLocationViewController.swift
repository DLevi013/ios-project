//
//  FoodLocationViewController.swift
//  iosproject
//
//  Created by Austin Nguyen on 11/11/25.
//

import UIKit
import FirebaseDatabase
import MapKit
import SDWebImage


class FoodLocationViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressValue: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    var selectedPost: FeedPost?
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var delegate: UIViewController?
    var locationId: String?
    var currentAnnotation: DiscoverPin?
    let ref = Database.database().reference()
    
    var relevantPosts: [FeedPost] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        guard var id = locationId else { return }
        id = id.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        
        let invalidChars = CharacterSet(charactersIn: ".#$[]")
        guard !id.isEmpty, id.rangeOfCharacter(from: invalidChars) == nil else {
            print("Invalid Firebase path after cleaning: \(id)")
            return
        }
        addPin(paramId: id)
        addRelevantPosts(locationId: id)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 12
                
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self

    }
    
    func addRelevantPosts(locationId: String) {
        let postsRef = Database.database().reference().child("posts")

        postsRef.observeSingleEvent(of: .value) { snapshot in
            let group = DispatchGroup()
            var feedPosts: [FeedPost] = []

            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                    let dict = childSnapshot.value as? [String: Any],
                    let postUserId = dict["userId"] as? String,
                    let postLocationId = dict["locationId"] as? String,
                    postLocationId == locationId
                else {
                    continue
                }

                group.enter()
                let userRef = Database.database().reference().child("users").child(postUserId)

                userRef.observeSingleEvent(of: .value) { userSnap in
                    defer { group.leave() }

                    if let userDict = userSnap.value as? [String: Any] {
                        let isPrivateValue = userDict["isPrivate"] as? Int ?? 0
                        let isPrivate = isPrivateValue != 0

                        if !isPrivate {
                            let username = userDict["username"] as? String ?? ""
                            let postId = dict["postId"] as? String ?? childSnapshot.key
                            let imageUrl = dict["image"] as? String ?? ""
                            let timestamp = dict["timestamp"] as? Double ?? 0
                            let likeCount = (dict["likes"] as? [String])?.count ?? 0
                            let commentsArray = dict["comments"] as? [[String: Any]] ?? []
                            let commentObjs = commentsArray.compactMap { Comment.from(dict: $0) }
                            let caption = dict["caption"] as? String ?? ""

                            let post = FeedPost(
                                postId: postId,
                                userId: postUserId,
                                username: username,
                                imageUrl: imageUrl,
                                timestamp: Int(timestamp),
                                likeCount: likeCount,
                                comments: commentObjs,
                                location: postLocationId,
                                caption: caption
                            )
                            feedPosts.append(post)
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.relevantPosts = feedPosts
                self.collectionView.reloadData()
                
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return relevantPosts.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodLocationIdentifier", for: indexPath) as! FoodLocationCell
        let post = relevantPosts[indexPath.row]
        cell.configure(with: post)
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPost = relevantPosts[indexPath.row]
        performSegue(withIdentifier: "foodLocationToPost", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "foodLocationToPost", let vc = segue.destination as? PostPage {
            vc.post = self.selectedPost
        }
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

class FoodLocationCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    func configure(with post: FeedPost) {
        
        
        let imageUrlString = post.imageUrl!
        
        let isDark = traitCollection.userInterfaceStyle == .dark
        let placeholderName = isDark ? "dark-placeholder" : "placeholder-square"
        let placeholderImage = UIImage(named: placeholderName)

        if let imageUrlString = post.imageUrl, let url = URL(string: imageUrlString) {
            self.imageView.sd_setImage(with: url, placeholderImage: placeholderImage)
        } else {
            self.imageView.image = placeholderImage
        }
    }
}

