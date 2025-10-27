//
//  AddPostViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/22/25.
//

import UIKit
import Firebase
import FirebaseAuth
var idCounter = 4

class AddPostViewController: ModeViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    

    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    let curUser = Auth.auth().currentUser!.uid
    var curUserName = ""
    
    var caption: String?
    var image: UIImage?
    var location: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusLabel.text = ""
        var ref : DatabaseReference!
        ref = Database.database().reference().child("users").child(curUser)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "userName").value as? String {
                self.curUserName = username
            }
            // Do any additional setup after loading the view.
        }
    }
    
    
    @IBAction func addImagePressed(_ sender: Any) {
        let photoPicker = UIImagePickerController()
        photoPicker.delegate = self
        photoPicker.sourceType = .photoLibrary
        present(photoPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            image = selectedImage
            statusLabel.text = "Added Image"
        }
        dismiss(animated: true, completion: nil)
    }

    
    @IBAction func postButtonPressed(_ sender: Any) {
        if let caption = captionTextField.text,
           caption != "",
           let location = locationTextField.text,
           location != "",
           let image = image {
            let newDate = Date()
            let newPost = FeedPost(id: "test\(idCounter)", username: curUserName, postImage: image, timestamp: newDate, likeCount: 0, commentCount: 0, location: location, caption: caption)
            
            posts.append(newPost)
            idCounter += 1
            statusLabel.text = "Added Post"
        }else{
            // make this an alert
            statusLabel.text = "Please provide all info"
        }
        
    }
    
}
