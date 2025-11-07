//
//  PostPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/21/25.
//

import UIKit
import FirebaseDatabase

class PostPage: ModeViewController, UITableViewDataSource, UITableViewDelegate {
    var comments: [String] = []
    

    var post: FeedPost?
    var userID : String = "default"
    var selectedPostImage: UIImage?
    var selectedPostIndex: Int = 0
    
    @IBOutlet weak var postImages: UIImageView!
    
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var userIDField: UILabel!
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextField!
    
    
    let ref = Database.database().reference().child("posts")
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let post = post else { return }
        
        if let image = post.postImage {
                    postImages.image = image
        }
        print("\(post.caption)")
        userIDField.text = post.username
        captionLabel.text = post.caption
        likeLabel.text = post.likeCount.description
        commentLabel.text = post.comments.count.description
        
        commentTableView.dataSource = self
        commentTableView.delegate = self
        
        let postRef = ref.child(post.postId).child("comments")
        postRef.observe(.value) { snapshot  in
            if let array = snapshot.value as? [String] {
                self.comments = array
                print("\(self.comments)")
                self.commentTableView.reloadData()
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func sendCommentTapped(_ sender: Any) {
        if commentTextField == nil {
            showError(title: "Invalid comment", message: "Comment cannot be empty.")
            return
        }
        
        post?.comments.append(commentTextField.text!)
        let ref = Database.database().reference()
        let postRef = ref.child("posts").child(post!.postId)
        /*
        postRef.getData { (error, snapshot) in
            if let error = error {
                self.showError(title: "ERROR", message:"\(error)")
            }
            guard let postDict = snapshot?.value as? [String: Any],
                let caption = postDict["caption"] as? String else {
                    print("SOMETING WRONG")
                    return
            }
            print("CAPTION: \(caption)")
        }
        */
        postRef.child("comments").setValue(post?.comments) { error, _ in
            if let error = error {
                self.showError(title: "ERROR", message:"\(error)")
            } else {
                self.showError(title:"Success", message: "comment sent!")
            }
        }
        print("SENT: \(commentTextField.text!)")
        
        
    }
    
    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        cell.textLabel?.text = comments[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        return cell
    }

}
