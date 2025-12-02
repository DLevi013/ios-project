//
//  FeedViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/20/25.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SDWebImage

class FeedViewController: ModeViewController, UITableViewDataSource, UITableViewDelegate, PostTableViewCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var selectedLocationId:String?
    
    var posts: [FeedPost] = []
    let postTableViewCellIdentifier = "PostCell"
    let ref = Database.database().reference()
    var selectedIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupRefreshControl()
        fetchPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        posts = []
        tableView.reloadData()
        UsernameCache.shared.clearCache()
        ProfileImageCache.shared.clearCache()
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
        posts = []
        tableView.reloadData()
        UsernameCache.shared.clearCache()
        ProfileImageCache.shared.clearCache()
        fetchPosts()
    }
    
    func fetchPosts() {
        posts = []
        tableView.reloadData()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let userRef = ref.child("users").child(currentUserId)
        
        // get friend uids
        userRef.child("friends").observeSingleEvent(of: .value) { friendSnapshot, _ in
            var friendUIDs: Set<String> = []
            for child in friendSnapshot.children {
                if let friendSnap = child as? DataSnapshot,
                   let friendUID = friendSnap.value as? String {
                    friendUIDs.insert(friendUID)
                }
            }
            // add self too
            friendUIDs.insert(currentUserId)
            
            // temporary array to store unsorted posts before sorting
            var tempPosts: [FeedPost] = []
            let dispatchGroup = DispatchGroup()
            
            // fetch posts and only add those from friends to posts
            self.ref.child("posts").observeSingleEvent(of: .value) { snapshot, _ in
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let dict = childSnapshot.value as? [String: Any],
                       let postUserId = dict["userId"] as? String,
                       friendUIDs.contains(postUserId) {
                        dispatchGroup.enter()
                        let postId = dict["postId"] as? String ?? ""
                        let timestamp = dict["timestamp"] as? Double ?? 0
                        let likeCount = (dict["likes"] as? [String])?.count ?? 0
                        
                        let commentsArray = dict["comments"] as? [[String: Any]] ?? []
                        let commentObjs = commentsArray.compactMap { Comment.from(dict: $0) }
                        
                        let location = dict["locationId"] as? String ?? ""
                        let caption = dict["caption"] as? String ?? ""
                        
                        let imageUrlString = dict["image"] as? String
                        
                        UsernameCache.shared.getUsername(for: postUserId) { username in
                            let post = FeedPost(
                                postId: postId,
                                userId: postUserId,
                                username: username ?? "Anon",
                                postImage: nil,
                                imageUrl: imageUrlString,
                                timestamp: Int(timestamp),
                                likeCount: likeCount,
                                comments: commentObjs,
                                location: location,
                                caption: caption,
                
                            )
                            tempPosts.append(post)
                            dispatchGroup.leave()
                        }
                        
                        // Get usernames for comments
                        let commentUserIds = Set(commentObjs.map {$0.userId})
                        UsernameCache.shared.getUsernames(for: Array(commentUserIds)) { usernames in
                            if let idx = self.posts.firstIndex(where: { $0.postId == postId}) {
                                for (commentIdx, var comment) in self.posts[idx].comments.enumerated() {
                                    comment.username = usernames[comment.userId]
                                    self.posts[idx].comments[commentIdx] = comment
                                }
                            }
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    // Sort by timestamp most recent on top
                    self.posts = tempPosts.sorted { $0.timestamp > $1.timestamp }
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
        
        cell.dateLabel.text = formattedPostDate(timestamp: post.timestamp)
        
        cell.likeCountLabel.text = String(post.likeCount)
        cell.commentCountLabel.text = String(post.comments.count)
        
        cell.captionLabel.text = String(post.caption)
        cell.commentButton.tag = indexPath.row
        cell.delegate = self
        
        let resizedPlaceholder = resizedImage(UIImage(named: "default_profile_pic.jpg"), to: CGSize(width: 32, height: 32))
        ProfileImageCache.shared.getProfileImageURL(for: post.userId) { profilePicURL in
            if let profilePicURL = profilePicURL, let url = URL(string: profilePicURL) {
                cell.profileButton.sd_setImage(with: url, for: .normal, placeholderImage: resizedPlaceholder, options: [], completed: { image, _, _, _ in
                    if let image = image, let resized = self.resizedImage(image, to: CGSize(width: 32, height: 32)) {
                        cell.profileButton.setImage(resized, for: .normal)
                    }
                })
            } else {
                cell.profileButton.setImage(resizedPlaceholder, for: .normal)
            }
        }
        
        let isDark = traitCollection.userInterfaceStyle == .dark
        let placeholderName = isDark ? "dark-placeholder" : "placeholder-square"
        let placeholderImage = UIImage(named: placeholderName)
        
        if let imageUrlString = post.imageUrl, let url = URL(string: imageUrlString) {
            cell.postImageView.sd_setImage(with: url, placeholderImage: placeholderImage)
        } else {
            cell.postImageView.image = placeholderImage
        }
        
        return cell
    }
    
    private func formattedPostDate(timestamp: Int) -> String {
        let postDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let now = Date()
        let calendar = Calendar.current
        
        let secondsAgo = Int(now.timeIntervalSince(postDate))
        
        if secondsAgo < 60 {
            return "Just now"
        }
        
        let minutesAgo = secondsAgo / 60
        if minutesAgo < 60 {
            return "\(minutesAgo) min ago"
        }
        
        let hoursAgo = minutesAgo / 60
        if hoursAgo < 24 && calendar.isDate(postDate, equalTo: now, toGranularity: .day) {
            return "\(hoursAgo) hr ago"
        }
        
        if calendar.isDateInYesterday(postDate) {
            return "Yesterday"
        }
        
        // Days ago calculation
        if let daysAgo = calendar.dateComponents([.day], from: postDate, to: now).day, daysAgo < 7 {
            return "\(daysAgo) days ago"
        }
        
        // Fallback to full date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: postDate)
    }
    
    func didTapProfileButton(on cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.row]
        let userId = post.userId
        
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "feedToProfile", sender: userId)
            }
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
    
    func resizedImage(_ image: UIImage?, to size: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }

    @IBAction func didTapCommentButton(_ sender: UIButton) {
        selectedIndex = sender.tag
        performSegue(withIdentifier:"feedToPost", sender: self)
    }

}
