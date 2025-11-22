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
 
    @IBOutlet weak var postImages: UIImageView!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var userIDField: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!

    var comments: [Comment] = []

    var post: FeedPost?
    var userID: String = "default"
    var selectedPostImage: UIImage?
    var selectedPostIndex: Int = 0
    var currentUserName = ""

    let ref = Database.database().reference().child("posts")
    var userNameRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        getUserName()
        guard let post = post else { return }

        if let imageUrlString = post.imageUrl, let url = URL(string: imageUrlString) {
            postImages.sd_setImage(with: url, placeholderImage: UIImage(named: "dark-placeholder"))
        } else {
            postImages.image = UIImage(named: "dark-placeholder")
        }

        print("\(post.caption)")
        userIDField.text = post.username
        captionLabel.text = post.caption
        likeLabel.text = post.likeCount.description
        commentLabel.text = post.comments.count.description

        commentTableView.dataSource = self
        commentTableView.delegate = self

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
            print("Loaded Comments: \(self.comments)")
            self.commentTableView.reloadData()
        }
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as? CommentTableViewCell else {
            fatalError("Could not dequeue CommentTableViewCell")
        }
        let comment = comments[indexPath.row]
        cell.usernameLabel.text = comment.username
        cell.commentLabel.text = comment.text
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        cell.dateLabel.text = formatter.string(from: comment.timestamp)
        return cell
    }

    @IBAction func locationButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "postToLocation", sender: self)
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "postToLocation",
           let destination = segue.destination as? FoodLocationViewController,
           let locationId = self.post?.location {
            destination.locationId = locationId
            destination.delegate = self
        }
    }
}
