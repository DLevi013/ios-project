//
//  PostPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/21/25.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SDWebImage

class PostPage: ModeViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var profilePicture: UIButton!
    @IBOutlet weak var postImages: UIImageView!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var userIDField: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentTextLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!
    
    @IBOutlet weak var heartButton: UIButton!
    
    
    @IBOutlet weak var deletePostButton: UIButton!
    

    var comments: [Comment] = []

    var post: FeedPost?
    var userID: String = "default"
    var selectedPostImage: UIImage?
    var selectedPostIndex: Int = 0
    var currentUserName = ""
    
    var selectedCommentUserId: String?

    let ref = Database.database().reference().child("posts")
    var userNameRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        deletePostButton.layer.shadowColor = UIColor.black.cgColor
        deletePostButton.layer.shadowRadius = 5.0
        deletePostButton.layer.shadowOpacity = 0.4
        deletePostButton.layer.shadowOffset = CGSize(width: 2, height: 4)
        
        
        let posterId = post?.userId
        guard let userId = Auth.auth().currentUser?.uid else { return }
        if(posterId != userId){
            deletePostButton.isHidden = true
        } else {
            deletePostButton.isHidden = false
        }
        
        
        getUserName()
        guard let post = post else { return }

        if let imageUrlString = post.imageUrl, let url = URL(string: imageUrlString) {
            postImages.sd_setImage(with: url, placeholderImage: UIImage(named: "dark-placeholder"))
        } else {
            postImages.image = UIImage(named: "dark-placeholder")
        }

        print("\(post.caption)")
        userIDField.text = post.username
        
        dateLabel.text = formattedPostDate(timestamp: post.timestamp)
        
        let basePlaceholder = UIImage(named: "default_profile_pic.jpg")
        let resizedPlaceholder = resizedImage(basePlaceholder, to: CGSize(width: 32, height: 32))
        let circularPlaceholder = circularImage(resizedPlaceholder)
        profilePicture.setImage(circularPlaceholder, for: .normal)
        
        ProfileImageCache.shared.getProfileImageURL(for: post.userId) { url in
            if let url = url, let imageURL = URL(string: url) {
                SDWebImageManager.shared.loadImage(with: imageURL, options: [], progress: nil) { image, _, _, _, _, _ in
                    let resized = self.resizedImage(image, to: CGSize(width: 32, height: 32))
                    let circular = self.circularImage(resized)
                    self.profilePicture.setImage(circular ?? circularPlaceholder, for: .normal)
                }
            } else {
                self.profilePicture.setImage(circularPlaceholder, for: .normal)
            }
        }

        captionLabel.text = post.caption
        likeLabel.text = post.likeCount.description
        commentTextLabel.text = "Comments (\(post.comments.count.description))"

        commentTableView.dataSource = self
        commentTableView.delegate = self
        commentTableView.estimatedRowHeight = 60.0
        commentTableView.rowHeight = UITableView.automaticDimension

        let postRef = ref.child(post.postId).child("comments")
        postRef.observe(.value) { snapshot in
            var loadedComments: [Comment] = []
            if let array = snapshot.value as? [[String: Any]] {
                for dict in array {
                    if let comment = Comment.from(dict: dict) {
                        loadedComments.append(comment)
                    }
                }
            }
            self.comments = loadedComments
            let userIds = Set(self.comments.map { $0.userId })
            UsernameCache.shared.getUsernames(for: Array(userIds)) { usernames in
                for idx in self.comments.indices {
                    self.comments[idx].username = usernames[self.comments[idx].userId]
                }
                print("Loaded Comments with usernames: \(self.comments)")
                self.commentTableView.reloadData()
            }
        }
    }

    private func circularImage(_ image: UIImage?) -> UIImage? {
        guard let image = image else { return nil }
        let minDimension = min(image.size.width, image.size.height)
        let size = CGSize(width: minDimension, height: minDimension)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(ovalIn: rect).addClip()
        image.draw(in: rect)
        let rounded = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rounded
    }

    
    @IBAction func heartButtonPressed(_ sender: Any) {
        // 1. Guard and setup references
            guard var post = post else { return } // Use 'var' to allow modification
            let likeRef = Database.database().reference()
            let postRef = likeRef.child("posts").child(post.postId).child("likes")
            guard let userId = Auth.auth().currentUser?.uid else { return }

            // 2. Perform Firebase Read operation
        postRef.observeSingleEvent(of: .value, with: { snapshot in
           
            var likes = snapshot.value as? [String] ?? []
                    let isCurrentlyLiked = likes.contains(userId)

                    if isCurrentlyLiked {
                        // Unlike
                        likes.removeAll { $0 == userId }
                        print("this stucks")
                    } else {
                        // Like
                        likes.append(userId)
                    }

                    // 3. Update Firebase WRITE operation
                    postRef.setValue(likes) { error, _ in
                        if let error = error {
                            print("Firebase update failed: \(error.localizedDescription)")
                            return
                        }
                        
                        post.likeCount = likes.count
                        self.post = post
                        
                        // Update the UI elements on the main thread
                        DispatchQueue.main.async {
                            let newLikeCount = likes.count
                            self.likeLabel.text = "\(newLikeCount)"
                        }
                    }
        })

    }
    
    
    @IBAction func pressedEditButton(_ sender: Any) {
        print("Delete post button pressed")
        let alert = UIAlertController(
                title: "Delete Post?",
                message: "Are you sure you want to delete this post?",
                preferredStyle: .actionSheet
            )

            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                let ref = Database.database().reference()
                    .child("posts")
                    .child(self.post!.postId)

                ref.removeValue { error, _ in
                    if let error = error {
                        print("Error deleting post: \(error.localizedDescription)")
                        return
                    }

                    DispatchQueue.main.async {
                        self.dismiss(animated: true)
                    }
                }
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        
    }

    @IBAction func sendCommentTapped(_ sender: Any) {
        guard let commentText = commentTextField.text, !commentText.isEmpty else {
            showError(title: "Invalid comment", message: "Comment cannot be empty.")
            return
        }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            showError(title: "Invalid user", message: "User not authenticated.")
            return
        }
        let comment = Comment(
            commentId: UUID().uuidString,
            userId: currentUserId,
            text: commentText,
            timestamp: Date(),
            username: currentUserName
        )
        self.comments.append(comment)
        let ref = Database.database().reference()
        let postRef = ref.child("posts").child(post!.postId)
        let commentDicts = self.comments.map { $0.toDict() }
        postRef.child("comments").setValue(commentDicts) { error, _ in
            if let error = error {
                self.showError(title: "ERROR", message: "\(error)")
            } else {
                self.showError(title: "Success", message: "comment sent!")
            }
        }
        print("SENT: \(commentText)")
    }

    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
        if let daysAgo = calendar.dateComponents([.day], from: postDate, to: now).day, daysAgo < 7 {
            return "\(daysAgo) days ago"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: postDate)
    }
    
    private func resizedImage(_ image: UIImage?, to size: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selectedItem = comments[indexPath.row]
        // If current user is the one that selected comment, give alert to let them delete comment
        if selectedItem.userId == Auth.auth().currentUser?.uid {
            let alertController = UIAlertController(title: "Delete Comment", message: "Would you like to delete this comment?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                self.comments.remove(at: indexPath.row)
                
                guard let postId = self.post?.postId else { return }
                let ref = Database.database().reference().child("posts").child(postId).child("comments")
                let commentDicts = self.comments.map { $0.toDict() }
                
                ref.setValue(commentDicts) { error, _ in
                    if let error = error {
                        self.showError(title: "Error", message: "Failed to delete comment: \(error.localizedDescription)")
                    } else {
                        self.commentTableView.reloadData()
                        self.showError(title: "Success", message: "Comment deleted!")
                    }
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as? CommentTableViewCell else {
            fatalError("Could not dequeue CommentTableViewCell")
        }
        let comment = comments[indexPath.row]
        cell.usernameLabel.text = comment.username
        cell.commentLabel.text = comment.text
        cell.dateLabel.text = formattedPostDate(timestamp: Int(comment.timestamp.timeIntervalSince1970))
        
        let basePlaceholder = UIImage(named: "default_profile_pic.jpg")
        let resizedPlaceholder = resizedImage(basePlaceholder, to: CGSize(width: 32, height: 32))
        let circularPlaceholder = circularImage(resizedPlaceholder)
        cell.profilePicture.setImage(circularPlaceholder, for: .normal)
        
        ProfileImageCache.shared.getProfileImageURL(for: comment.userId) { url in
            if let url = url, let imageURL = URL(string: url) {
                SDWebImageManager.shared.loadImage(with: imageURL, options: [], progress: nil) { image, _, _, _, _, _ in
                    let resized = self.resizedImage(image, to: CGSize(width: 32, height: 32))
                    let circular = self.circularImage(resized)
                    cell.profilePicture.setImage(circular ?? circularPlaceholder, for: .normal)
                }
            } else {
                cell.profilePicture.setImage(circularPlaceholder, for: .normal)
            }
        }
        
        cell.profilePicture.tag = indexPath.row
        cell.profilePicture.addTarget(self, action: #selector(commentProfileTapped(_:)), for: .touchUpInside)
        
        return cell
    }

    @IBAction func locationButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "postToLocation", sender: self)
    }

    @IBAction func profilePicturePressed(_ sender: Any) {
        performSegue(withIdentifier: "profilePictureToOtherProfile", sender: self)
    }
    
    func getUserName() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference()
        ref.child("users").child(currentUserID).child("username").observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.value as? String {
                self.currentUserName = username
            } else {
                self.currentUserName = "No Username Found!"
            }
        }
    }

    @objc func commentProfileTapped(_ sender: UIButton) {
        let row = sender.tag
        guard comments.indices.contains(row) else { return }
        selectedCommentUserId = comments[row].userId
        performSegue(withIdentifier: "commentToOtherProfile", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "postToLocation",
           let destination = segue.destination as? FoodLocationViewController,
           let locationId = self.post?.location {
            destination.locationId = locationId
            destination.delegate = self
        }
        
        if segue.identifier == "commentToOtherProfile",
           let destination = segue.destination as? OtherProfilePage,
           let userId = selectedCommentUserId {
            destination.otherUserID = userId
        }
        
        if segue.identifier == "profilePictureToOtherProfile",
           let destination = segue.destination as? OtherProfilePage,
           let userId = self.post?.userId {
            destination.otherUserID = userId
        }
    }
}

