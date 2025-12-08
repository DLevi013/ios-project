//
//  SignUpPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/16/25.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SignUpPage: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userIDField: UITextField!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordConfirmField: UITextField!

    let ref = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        userIDField.delegate = self
        userNameField.delegate = self
        passwordField.delegate = self
        passwordConfirmField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
        
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    @IBAction func signupPressed(_ sender: Any) {
        if userIDField.text?.isEmpty == true {
            showError(title: "Bad email", message: "Email cannot be empty.")
            return
        }
        if passwordField.text?.isEmpty == true {
            showError(title: "Bad Password", message: "Password cannot be empty.")
            return
        }
        if passwordField.text != passwordConfirmField.text {
            showError(title: "Bad Password", message: "Passwords do not match.")
            return
        }
        Auth.auth().createUser(withEmail: userIDField.text!, password: passwordField.text!) { (authResult, error) in
            if (error != nil) {
                self.showError(title: "Error", message: error?.localizedDescription ?? "Easter Egg unlocked.")
            } else if (authResult != nil) {
                print(authResult!)
                let userData = ["username": self.userNameField.text!]
                self.ref.child("users").child(authResult!.user.uid).setValue(userData)

                let alert = UIAlertController(title: "Login successful", message: "Login success", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    self!.performSegue(withIdentifier: "signupToLogin", sender: nil)
                }
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
