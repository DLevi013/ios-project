//
//  AddPostViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/22/25.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

var idCounter = 4

class AddPostViewController: ModeViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LocationSelectionDelegate{
    
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var postButton: UIButton!
    
    let curUser = Auth.auth().currentUser!.uid
    var curUserName = ""
    
    var caption: String?
    var imageLink: String?
    var locationName: String = ""
    var address: String = ""
    var latitude: Double?
    var longitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var ref: DatabaseReference!
        ref = Database.database().reference().child("users").child(curUser)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "userName").value as? String {
                self.curUserName = username
            }
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
            guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
                dismiss(animated: true, completion: nil)
                return
            }

            let storageRef = Storage.storage().reference().child("postImages/\(UUID().uuidString).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Image upload failed: \(error!)")
                    let controller = UIAlertController(title: "Add Image", message: "Image upload failed.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    controller.addAction(okAction)
                    controller.preferredAction = okAction
                    self.present(controller, animated:true)
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
                        return
                    }

                    self.imageLink = downloadURL.absoluteString
                    self.postButton.isEnabled = true
                    
                    let controller = UIAlertController(title: "Add Image", message: "Image successfully added.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    controller.addAction(okAction)
                    controller.preferredAction = okAction
                    self.present(controller, animated:true)
                }
            }
            
            dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func addLocationPressed(_ sender: Any) {
        performSegue(withIdentifier: "postToDiscoverSegue", sender: self)
    }
    
    func didSelectLocation(selectedLatitude: Double, selectedLongitude: Double, selectedName: String, address: String) {
        self.latitude = selectedLatitude
        self.longitude = selectedLongitude
        self.locationName = selectedName
        self.address = address
    }
    
    func makeLocationId(lat: Double, lon: Double, name: String) -> String {
        let lat = String(format: "%.4f", lat).replacingOccurrences(of: ".", with: "_")
        let lon = String(format: "%.4f", lon).replacingOccurrences(of: ".", with: "_")
        let locationId = "\(self.locationName);\(lat);\(lon)"
        return locationId
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        guard let caption = captionTextField.text,
            !caption.isEmpty,
            !locationName.isEmpty,
            let longtitude = longitude,
            let latitude = latitude,
            let imageLink = imageLink,
            !imageLink.isEmpty else {
            
            let controller = UIAlertController(title: "Missing fields", message: "Please provide all info to make a post.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            controller.addAction(okAction)
            controller.preferredAction = okAction
            present(controller, animated:true)
            return
        }
        
        let locationId = makeLocationId(lat: self.longitude!, lon: self.latitude!, name: self.locationName)
        
        let ref = Database.database().reference()
        ref.child("users").child(curUser).child("username").observeSingleEvent(of: .value) { snapshot in
            guard let userName = snapshot.value as? String else {
                let controller = UIAlertController(title: "Error", message: "Could not fetch username.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                controller.addAction(okAction)
                controller.preferredAction = okAction
                self.present(controller, animated:true)
                return
            }
            let postsRef = ref.child("posts").childByAutoId()
            let postId = postsRef.key ?? UUID().uuidString
            let timestamp = Date().timeIntervalSince1970
            let locationRef = ref.child("locations").child(locationId)
            let postData: [String: Any] = [
                "postId": postId,
                "userId": self.curUser,
                "username": userName,
                "image": imageLink,
                "timestamp": timestamp,
                "caption": caption,
                "likes": [String](),
                "comments": [String](),
                "locationId": locationId
            ]
            let locationData: [String: Any] = [
                "name": self.locationName,
                "address": self.address,
                "coordinates": [
                    "latitude": latitude,
                    "longitude": longtitude
                ]
            ]
            locationRef.updateChildValues(locationData) { error, _ in
                if let error = error {
                    print("Failed to update/find location: \(error.localizedDescription)")
                }
                let postIdsRef = locationRef.child("postIds")
                postIdsRef.updateChildValues([postId: true]) { error, _ in
                    if let error = error {
                        print("Failed to attach postId: \(error.localizedDescription)")
                    }
                }
            }
            postsRef.setValue(postData) { error, _ in
                var alertMessage = ""
                if let error = error {
                    print("Error saving post: \(error.localizedDescription)")
                    alertMessage = "Post failed"
                } else {
                    print("Post successfully added!")
                    alertMessage = "Post added!"
                }
                let controller = UIAlertController(title: "Add Post", message: alertMessage, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                controller.addAction(okAction)
                controller.preferredAction = okAction
                self.present(controller, animated:true)
            }
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "postToDiscoverSegue" {
            if let discoverVC = segue.destination as? DiscoverPage {
                discoverVC.isSelectingLocation = true
                discoverVC.discoverDelegate = self
            }
        }
    }
}

protocol LocationSelectionDelegate: AnyObject {
    func didSelectLocation(selectedLatitude: Double, selectedLongitude: Double, selectedName: String, address: String)
}

