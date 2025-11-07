//
//  PostPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/21/25.
//

import UIKit

class PostPage: ModeViewController {

    var post: FeedPost?
    var userID : String = "default"
    var selectedPostImage: UIImage?
    var selectedPostIndex: Int = 0
    @IBOutlet weak var postImages: UIImageView!
    
    @IBOutlet weak var userIDField: UILabel!
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    
    @IBOutlet weak var captionLabel: UILabel!
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
        
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
