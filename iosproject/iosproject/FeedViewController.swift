//
//  FeedViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/20/25.
//


//
//  FeedViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/20/25.
//

import UIKit

var posts: [FeedPost] = []

class FeedViewController: ModeViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let postTableViewCellIdentifier = "PostCell"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchPosts()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        fetchPosts()
//    }
    
    func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
        tableView.separatorStyle = .none
    }
    
    func fetchPosts(){
        // fetch post data from db
        // MOCK IMPLEMENTATION FOR TESTING
        if posts.count == 0{
            let newDate = Date()
            let newPostImage = UIImage(named: "chickenAndRice")
            
            let newPost = FeedPost(id: "test1", username: "IsaacPlayz245", postImage: newPostImage, timestamp: newDate, likeCount: 1000, commentCount: 3827, location: "Isaac's Carribean Restauarant", caption: "This Chicken and Rice from here is heavenly.")
            
            posts.append(newPost)
        }
        
        // reloadData
        tableView.reloadData()
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
        dateFormatter.dateStyle = .medium
        cell.dateLabel.text = dateFormatter.string(from: post.timestamp)
        
        
        cell.likeCountLabel.text = String(post.likeCount)
        cell.commentCountLabel.text = String(post.commentCount)
        
        cell.postImageView.image = post.postImage
        cell.captionLabel.text = String(post.caption)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

}
