//
//  FeedViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/20/25.
//

import UIKit
import FirebaseDatabase

class FeedViewController: ModeViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var posts: [FeedPost] = []
    let postTableViewCellIdentifier = "PostCell"
    let ref = Database.database().reference()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
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
    
    func fetchPosts(){
        posts = [FeedPost]()
        
        ref.child("posts").observeSingleEvent(of: .value) { snapshot in
            var feedPosts: [FeedPost] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any] {
                    let postId = dict["postId"] as? String ?? ""
                    let username = dict["username"] as? String ?? ""
                    let imageUrl = dict["image"] as? String ?? ""
                    let timestamp = dict["timestamp"] as? Double ?? 0
                    let likeCount = (dict["likes"] as? [String])?.count ?? 0
                    let comments = dict["comments"] as? [String] ?? []
                    let location = dict["location"] as? String ?? ""
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
                                        comments: comments,
                                        location: location,
                                        caption: caption
                                    )
                                    feedPosts.append(post)
                                    self.posts = feedPosts
                                    self.tableView.reloadData()
                                }
                            }
                        }.resume()
                    } else {
                        // If image URL invalid, append post with nil image to avoid skipping
                        let post = FeedPost(
                            postId: postId,
                            username: username,
                            postImage: nil,
                            timestamp: Int(timestamp),
                            likeCount: likeCount,
                            comments: comments,
                            location: location,
                            caption: caption
                        )
                        feedPosts.append(post)
                    }
                }
            }
            // In case all images are invalid and no async call triggered reload here
            DispatchQueue.main.async {
                self.posts = feedPosts
                self.tableView.reloadData()
            }
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

}
