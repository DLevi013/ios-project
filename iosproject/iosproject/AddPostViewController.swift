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
import Vision

var idCounter = 4

class AddPostViewController: ModeViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LocationSelectionDelegate{
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captionTextField: UITextField!
//    @IBOutlet weak var postButton: UIButton!
    
    @IBOutlet weak var betterLocationButton: UIButton!
    @IBOutlet weak var betterPostButton: UIButton!
    
    
    
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
        
        betterLocationButton.layer.shadowColor = UIColor.black.cgColor
        betterLocationButton.layer.shadowRadius = 5.0
        betterLocationButton.layer.shadowOpacity = 0.4
        betterLocationButton.layer.shadowOffset = CGSize(width: 2, height: 4)
        
        
        betterPostButton.layer.shadowColor = UIColor.black.cgColor
        betterPostButton.layer.shadowRadius = 5.0
        betterPostButton.layer.shadowOpacity = 0.4
        betterPostButton.layer.shadowOffset = CGSize(width: 2, height: 4)
        
        
        
//        captionTextField.lineLimit(1...)
        
        var ref: DatabaseReference!
        ref = Database.database().reference().child("users").child(curUser)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "userName").value as? String {
                self.curUserName = username
            }
        }
        
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(recognizeTapGesture(recognizer:)))
        imageView.addGestureRecognizer(tapRecognizer)
        
        let isDarkMode = UserDefaults.standard.bool(forKey: "mode")
        if isDarkMode {
            imageView.image = UIImage(named: "dark_placeholder")
        } else {
            imageView.image = UIImage(named: "placeholder-square")
        }
        betterPostButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let isDarkMode = UserDefaults.standard.bool(forKey: "mode")
        if isDarkMode {
            imageView.image = UIImage(named: "dark_placeholder")
        } else {
            imageView.image = UIImage(named: "placeholder-square")
        }
        imageLink = ""
    }
    
    @IBAction func recognizeTapGesture(recognizer: UITapGestureRecognizer){
        let photoPicker = UIImagePickerController()
        photoPicker.delegate = self
        photoPicker.sourceType = .photoLibrary
        present(photoPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
//            self.analyzeImageForFood(image: selectedImage)
            
            imageView.image = selectedImage
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
                    self.betterPostButton.isEnabled = true
                }
            }
            
            dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func addLocationPressed(_ sender: Any) {
        print("Old BUtton Pressed")
    }
    
    
    @IBAction func betterAddLocationPressed(_ sender: Any) {
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
        print("Old Post button pressed")
        }
    
    
    @IBAction func betterPostButtonPressed(_ sender: Any) {
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
            let postsRef = ref.child("posts").childByAutoId()
            let postId = postsRef.key ?? UUID().uuidString
            let timestamp = Date().timeIntervalSince1970
            let locationRef = ref.child("locations").child(locationId)
            let postData: [String: Any] = [
                "postId": postId,
                "userId": self.curUser,
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
                    if (isNotif) {
                        self.checkPostMilestone()
                    }

                }
                let controller = UIAlertController(title: "Add Post", message: alertMessage, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default)
                controller.addAction(okAction)
                controller.preferredAction = okAction
                self.present(controller, animated:true)
            }
    }
    
    private func checkPostMilestone() {
        let ref = Database.database().reference()
            // Count total posts by current user
            ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: curUser).observeSingleEvent(of: .value) { snapshot in
                let postCount = Int(snapshot.childrenCount)
                print("User has \(postCount) total posts")
                
                // Send milestone notification if applicable
                if [1, 5, 10, 25, 50, 100].contains(postCount) {
                    PostReminderManager.shared.sendMotivationalReminder(postsCount: postCount)
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
        
        if segue.identifier == "postToDiscoverSegue",
           let vc = segue.destination as? DiscoverPage {
            vc.delegate = self
            vc.fromAddPost = true
        }
    }
}

protocol LocationSelectionDelegate: AnyObject {
    func didSelectLocation(selectedLatitude: Double, selectedLongitude: Double, selectedName: String, address: String)
}


// STORING HERE FOR LATER MAYBE??

//    func analyzeImageForFood(image: UIImage) {
//        guard let ciImage = CIImage(image: image) else {
//            print("Could not convert UIImage to CIImage.")
//            return
//        }
//
//        // 1. Load the Model
//        guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
//            fatalError("Failed to load Vision ML model.")
//        }
//
//        // 2. Create the Request
//        // FIX: Explicitly tell Swift that 'request' is VNRequest and 'error' is Error?
//        let request = VNCoreMLRequest(model: model) { [weak self] (request: VNRequest, error: Error?) in
//            self?.processClassificationResults(request, error: error, originalImage: image)
//        }
//
//        // 3. Perform the Request
//        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up)
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Failed to perform classification: \(error)")
//            }
//        }
//    }
//
    
    // Inside your AddPostViewController class

//    func processClassificationResults(_ request: VNRequest, error: Error?, originalImage: UIImage) {
//        guard let results = request.results as? [VNClassificationObservation] else {
//            print("Classification failed: \(error?.localizedDescription ?? "Unknown error")")
//            return
//        }
//
//        // 1. Find the best classification result
//        let topClassification = results.prefix(3) // Look at the top 3 results
//
//        // Check if any of the top results are related to food
//        let isFood = topClassification.contains { observation in
//            // IMPORTANT: The exact string depends on the model you use.
//            // For general-purpose models, look for 'food', 'plate', 'dish', etc.
//            // If using a dedicated food model (like Food101), check its specific class labels.
//            let identifier = observation.identifier.lowercased()
//            let confidence = observation.confidence
//
//            // This is a simple, broad check. You'll need to refine the keywords and confidence threshold.
//            let confidenceThreshold: Float = 0.50 // 50% confidence required
//
//            return confidence > confidenceThreshold &&
//                   (identifier.contains("food") ||
//                    identifier.contains("dish") ||
//                    identifier.contains("plate") ||
//                    identifier.contains("meal"))
//        }
//
//        // 2. Handle the result on the main thread
//        DispatchQueue.main.async {
//            if isFood {
//                // Food detected: Continue with image upload and posting logic
//                self.startImageUploadAndEnablePost(selectedImage: originalImage)
//            } else {
//                // No food detected: Show an alert and reset the image view
//                self.imageView.image = nil // or reset to placeholder
//                self.imageLink = nil
//                self.betterPostButton.isEnabled = false
//
//                let controller = UIAlertController(title: "Not Food", message: "That doesn't look like food! Please select a photo of a dish.", preferredStyle: .alert)
//                let okAction = UIAlertAction(title: "OK", style: .default)
//                controller.addAction(okAction)
//                self.present(controller, animated: true)
//            }
//        }
//    }
//
//
//    // Inside your AddPostViewController class
//
//    func startImageUploadAndEnablePost(selectedImage: UIImage) {
//        self.imageView.image = selectedImage
//
//        // Your existing Firebase Storage Upload Logic starts here
//        guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
//            // ... handle error ...
//            return
//        }
//
//        // Show a loading indicator here (recommended)
//
//        let storageRef = Storage.storage().reference().child("postImages/\(UUID().uuidString).jpg")
//        storageRef.putData(imageData, metadata: nil) { metadata, error in
//            // Hide loading indicator here
//            guard error == nil else {
//                // ... handle upload failed alert ...
//                return
//            }
//            storageRef.downloadURL { url, error in
//                guard let downloadURL = url else {
//                    // ... handle download URL failed alert ...
//                    return
//                }
//
//                self.imageLink = downloadURL.absoluteString
//                self.betterPostButton.isEnabled = true
//            }
//        }
//        // Dismiss the picker immediately
//        dismiss(animated: true, completion: nil)
//    }

