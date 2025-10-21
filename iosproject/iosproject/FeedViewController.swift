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

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let postTableViewCellIdentifier = "PostCell"
    var posts: [FeedPost] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
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
        // fetch post data from db
        // MOCK IMPLEMENTATION FOR TESTING
        for x in 0...4{
            let newDate = Date()
            let newPostImage = UIImage(named: "chickenAndRice")
            
            let newPost = FeedPost(id: "test\(x)", username: "IsaacPlayz245", postImage: newPostImage, timestamp: newDate, likeCount: 1000, commentCount: 3827)
            
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

}
