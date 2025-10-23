//
//  AddPostViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/22/25.
//

import UIKit
var idCounter = 4

class AddPostViewController: UIViewController {
    

    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    var caption: String?
    var image: UIImage?
    var location: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        statusLabel.text = ""
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func addImagePressed(_ sender: Any) {
        image = UIImage(named: "parisMatcha")
        statusLabel.text = "Added Image"
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        if let caption = captionTextField.text,
           caption != "",
           let location = locationTextField.text,
           location != "",
           let image = image {
            let newDate = Date()
            let newPost = FeedPost(id: "test\(idCounter)", username: "IsaacPlayz245", postImage: image, timestamp: newDate, likeCount: 0, commentCount: 0, location: location, caption: caption)
            
            posts.append(newPost)
            idCounter += 1
            statusLabel.text = "Added Post"
        }else{
            // make this an alert
            statusLabel.text = "Please provide all info"
        }
        
    }
    
}
