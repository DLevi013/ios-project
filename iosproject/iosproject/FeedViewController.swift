//
//  FeedViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/20/25.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class FeedViewController: ModeViewController, UITableViewDataSource, UITableViewDelegate, PostTableViewCellDelegate {
    

    @IBOutlet weak var tableView: UITableView!
    
    var selectedLocationId:String?
    
    var posts: [FeedPost] = []
    let postTableViewCellIdentifier = "PostCell"
    let ref = Database.database().reference()
    var selectedIndex: Int?
//    var otherProfile = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupRefreshControl()
        fetchPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchPosts()
    }
    
    func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
        tableView.separatorStyle = .none
    }
    
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc func handleRefresh() {
        fetchPosts()
    }
    
    func fetchPosts() {
        posts = []
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let userRef = ref.child("users").child(currentUserId)
        
        // get friend uids
        userRef.child("friends").observeSingleEvent(of: .value) { friendSnapshot in
            var friendUIDs: Set<String> = []
            for child in friendSnapshot.children {
                if let friendSnap = child as? DataSnapshot,
                   let friendUID = friendSnap.value as? String {
                    friendUIDs.insert(friendUID)
                }
            }
            // add self too
            friendUIDs.insert(currentUserId)

            // fetch posts and only add those from friends to posts
            self.ref.child("posts").observeSingleEvent(of: .value) { snapshot in
                var feedPosts: [FeedPost] = []
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let dict = childSnapshot.value as? [String: Any],
                       let postUserId = dict["userId"] as? String,
                       friendUIDs.contains(postUserId) {
                        let postId = dict["postId"] as? String ?? ""
                        let username = dict["username"] as? String ?? ""
                        let imageUrl = dict["image"] as? String ?? ""
                        let timestamp = dict["timestamp"] as? Double ?? 0
                        let likeCount = (dict["likes"] as? [String])?.count ?? 0

                        let commentsArray = dict["comments"] as? [[String: Any]] ?? []
                        let commentObjs = commentsArray.compactMap { Comment.from(dict: $0) }

                        let location = dict["locationId"] as? String ?? ""
                        let caption = dict["caption"] as? String ?? ""
                        
                        if let url = URL(string: imageUrl) {
                            URLSession.shared.dataTask(with: url) { data, response, error in
                                if let data = data, let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        let post = FeedPost(
                                            postId: postId,
                                            username: username,
                                            postImage: image,
                                            timestamp: Int(timestamp),
                                            likeCount: likeCount,
                                            comments: commentObjs,
                                            location: location,
                                            caption: caption
                                        )
                                        feedPosts.append(post)
                                        self.posts = feedPosts
                                        self.tableView.reloadData()
                                        self.tableView.refreshControl?.endRefreshing()
                                    }
                                }
                            }.resume()
                        } else {
                            
                            let post = FeedPost(
                                postId: postId,
                                username: username,
                                postImage: nil,
                                timestamp: Int(timestamp),
                                likeCount: likeCount,
                                comments: commentObjs,
                                location: location,
                                caption: caption
                            )
                            feedPosts.append(post)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.posts = feedPosts
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
        if segue.identifier == "feedToProfile",
            let vc = segue.destination as? OtherProfilePage,
            let userId = sender as? String {
                vc.otherUserID = userId
        }
         */
        if segue.identifier == "feedToProfile",
           let uid = sender as? String,
           let destination = segue.destination as? OtherProfilePage {
            print("Setting destination with \(uid)")
            destination.otherUserID = uid
        }
        if segue.identifier == "feedToPost" {
            if let destinationVC = segue.destination as? PostPage,
               let index = selectedIndex {
                destinationVC.post = posts[index]
            }
        }
         
        if segue.identifier == "feedToLocation",
           let destination = segue.destination as? FoodLocationViewController,
           let locationId = self.selectedLocationId {
            
            destination.locationId = locationId
            destination.delegate = self
        }
           
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: postTableViewCellIdentifier, for: indexPath) as? PostTableViewCell else {
               fatalError("Could not dequeue PostTableViewCell")
           }
        
        cell.selectionStyle = .none
        
        let post = posts[indexPath.row]
        cell.usernameLabel.text = post.username
        
        // IMPLEMENT DATE/TIME SHOWING LATER(like time only if its current day, yesterday, then month and days without year for current year, then full date after that.
        let dateFormatter = DateFormatter()
        let date = Date(timeIntervalSince1970: TimeInterval(post.timestamp))
        dateFormatter.dateStyle = .medium
        cell.dateLabel.text = dateFormatter.string(from: date)
        
        
        cell.likeCountLabel.text = String(post.likeCount)
        cell.commentCountLabel.text = String(post.comments.count)
        
        cell.postImageView.image = post.postImage
        cell.captionLabel.text = String(post.caption)
        cell.commentButton.tag = indexPath.row
        cell.delegate = self
        return cell
    }
    
    
    func didTapProfileButton(on cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.row]
        let username = post.username
        
        let usersRef = Database.database().reference().child("users")
        usersRef.queryOrdered(byChild: "username").queryEqual(toValue:username).observeSingleEvent(of: .value) { snapshot in
            guard let firstChild = snapshot.children.allObjects.first as? DataSnapshot else {
                print("DEBUG: NO USER \(username) FOUND")
                return
            }
            let uid = firstChild.key
            print("FOUND UID: \(uid)")
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "feedToProfile", sender: uid)
            }
        }
        
        // performSegue(withIdentifier: "feedToProfile", sender: post.username)
    }
    
    
    func didTapLikeButton(on cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.row]
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let postRef = ref.child("posts").child(post.postId).child("likes")

                // Check if user already liked
        postRef.observeSingleEvent(of: .value) { snapshot,error  in
                    var likes = snapshot.value as? [String] ?? []
                    if likes.contains(userId) {
                        // Unlike
                        likes.removeAll { $0 == userId }
                    } else {
                        // Like
                        likes.append(userId)
                    }

                    // Update Firebase
                    postRef.setValue(likes)
                    self.posts[indexPath.row].likeCount = likes.count
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    let heartImage = likes.contains(userId) ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
                    cell.likeButton.setImage(heartImage, for: .normal)
            
        
                }
        }
    
    func didTapLocation(on cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.row]
        let postRef = ref.child("posts").child(post.postId).child("locationId")

        postRef.observeSingleEvent(of: .value) { snapshot,error  in
            
                    self.selectedLocationId = post.location
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "feedToLocation", sender: self)
                    }
            
        
                }
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    

   
    
    @IBAction func didTapCommentButton(_ sender: UIButton) {
        selectedIndex = sender.tag
        performSegue(withIdentifier:"feedToPost", sender: self)
        
        
    }
    
   

}

