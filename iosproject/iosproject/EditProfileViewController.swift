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

        var message = "No New UserId or Bio Provided"

        if let newUsername = userIDTextField.text, !newUsername.isEmpty {
            ref.child("username").setValue(newUsername)
            message = "New UserId Saved"
        }

        if let newBio = bioTextField.text, !newBio.isEmpty {
            ref.child("bio").setValue(newBio)
            if message != "" {
                message = "New UserID and Bio Saved"
            } else {
                message = "New Bio Saved"
            }
        }

        let alertController = UIAlertController(title: "Edit Profile", message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default)

        alertController.addAction(okAction)

        alertController.preferredAction = okAction
        present(alertController, animated: true)
    }
}
