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

class EditProfileViewController: UIViewController {

    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var bioTextField: UITextField!
    
    @IBOutlet weak var saveChangesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCurrentUserData()
        
        
        // Do any additional setup after loading the view.
    }
    
    
    
    
    
    func loadCurrentUserData() {
            let curUser = Auth.auth().currentUser!.uid

            let ref = Database.database().reference().child("users").child(curUser)
            ref.observeSingleEvent(of: .value) { snapshot in
                if let username = snapshot.childSnapshot(forPath: "username").value as? String {
                    self.userIDTextField.placeholder = username
                }
                if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                    self.bioTextField.placeholder = bio
                }
            }
    }
    

    @IBAction func saveChangesPressed(_ sender: Any) {
        let currentUserID = Auth.auth().currentUser!.uid

        let ref = Database.database().reference().child("users").child(currentUserID)
            
            if let newUsername = userIDTextField.text, !newUsername.isEmpty {
                ref.child("username").setValue(newUsername)
            }
            
            if let newBio = bioTextField.text, !newBio.isEmpty {
                ref.child("bio").setValue(newBio)
            }
    }
    

}
