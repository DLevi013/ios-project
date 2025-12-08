//
//  EditProfileViewController.swift
//  iosproject
//
//  Created by Daniel Levi on 11/12/25.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImage

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var saveChangesButton: UIButton!

    @IBOutlet weak var newSaveChangesButton: UIButton!
    
    @IBOutlet weak var profilePicture: UIImageView!
    
    @IBOutlet weak var oldUserIDField: UITextField!
    
    @IBOutlet weak var oldBioField: UITextField!
    
    var imageLink : String?
    var isUploadingImage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profilePicture.image = UIImage(named: "default_profile_pic.jpg")
        profilePicture.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(recognizeTapGesture(recognizer:)))
            profilePicture.addGestureRecognizer(tapRecognizer)
        
        loadCurrentUserData()
        newSaveChangesButton.layer.shadowColor = UIColor.black.cgColor
        newSaveChangesButton.layer.shadowRadius = 5.0
        newSaveChangesButton.layer.shadowOpacity = 0.4
        newSaveChangesButton.layer.shadowOffset = CGSize(width: 2, height: 4)
        // Do any additional setup after loading the view.
        
        userIDTextField.delegate = self
        bioTextField.delegate = self
        oldUserIDField.delegate = self
        oldBioField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
        
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        loadCurrentUserData()
//    }
    
    @IBAction func recognizeTapGesture(recognizer: UITapGestureRecognizer){
        let photoPicker = UIImagePickerController()
        photoPicker.delegate = self
        photoPicker.sourceType = .photoLibrary
        present(photoPicker, animated: true, completion: nil)
    }

    func loadCurrentUserData() {
        let curUser = Auth.auth().currentUser!.uid

        let ref = Database.database().reference().child("users").child(curUser)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "username").value as? String {
                self.oldUserIDField.placeholder = username
                self.oldUserIDField.isUserInteractionEnabled = false
            }
            if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                self.oldBioField.placeholder = bio
                self.oldBioField.isUserInteractionEnabled = false
            }
            if let profilePic = snapshot.childSnapshot(forPath: "profilePicture").value as? String, let url = URL(string: profilePic) {
                self.profilePicture.sd_setImage(with: url, placeholderImage: UIImage(named: "default_profile_pic.jpg"))
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
//            self.analyzeImageForFood(image: selectedImage)
            
            profilePicture.image = selectedImage
            guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
                dismiss(animated: true, completion: nil)
                newSaveChangesButton.isEnabled = true
                return
            }

            let storageRef = Storage.storage().reference().child("profileImages/\(UUID().uuidString).jpg")
            
            isUploadingImage = true
            newSaveChangesButton.isEnabled = false
            
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Image upload failed: \(error!)")
                    let controller = UIAlertController(title: "Add Image", message: "Image upload failed.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    controller.addAction(okAction)
                    controller.preferredAction = okAction
                    self.present(controller, animated:true)
                    self.isUploadingImage = false
                    self.newSaveChangesButton.isEnabled = true
                    return
                }
                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        print("Image upload failed: \(error!)")
                        let controller = UIAlertController(title: "Add Image", message: "Image upload failed: \(error!)", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default)
                        controller.addAction(okAction)
                        controller.preferredAction = okAction
                        self.present(controller, animated:true)
                        print("Failed to get download URL")
                        self.isUploadingImage = false
                        self.newSaveChangesButton.isEnabled = true
                        return
                    }

                    self.imageLink = downloadURL.absoluteString
                    self.isUploadingImage = false
                    self.newSaveChangesButton.isEnabled = true
                }
            }
            
            dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
            newSaveChangesButton.isEnabled = true
        }
    }

    @IBAction func newSaveChangesPressed(_ sender: Any) {
        
        let currentUserID = Auth.auth().currentUser!.uid
        let ref = Database.database().reference().child("users").child(currentUserID)

        var usernameChanged = false
        var bioChanged = false
        var profilePicChanged = false

        if let newUsername = userIDTextField.text, !newUsername.isEmpty {
            ref.child("username").setValue(newUsername)
            usernameChanged = true
        }

        if let newBio = bioTextField.text, !newBio.isEmpty {
            ref.child("bio").setValue(newBio)
            bioChanged = true
        }
        
        if let newProfilePic = imageLink, !newProfilePic.isEmpty {
            ref.child("profileImageURL").setValue(newProfilePic)
            profilePicChanged = true
        }

        var message = "No New UserId, Bio, or Profile Image Provided"
        if usernameChanged || bioChanged || profilePicChanged {
            var parts: [String] = []
            if usernameChanged { parts.append("New UserId") }
            if bioChanged { parts.append("Bio") }
            if profilePicChanged { parts.append("Profile Image") }
            message = parts.joined(separator: ", ") + " Saved"
        }

        let alertController = UIAlertController(title: "Edit Profile", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        alertController.preferredAction = okAction
        present(alertController, animated: true)
        
        
    }
    
    @IBAction func saveChangesPressed(_ sender: Any) {
        print("old Button Pressed!")
        
    }
}

