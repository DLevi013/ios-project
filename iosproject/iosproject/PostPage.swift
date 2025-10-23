//
//  PostPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/21/25.
//

import UIKit

class PostPage: ModeViewController {

    var userID : String = ""
    var selectedPostImage: UIImage?
    var selectedPostIndex: Int = 0
    @IBOutlet weak var postImages: UIImageView!
    
    @IBOutlet weak var userIDField: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = selectedPostImage {
                    postImages.image = image
        }
        userIDField.text = userID
        
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
