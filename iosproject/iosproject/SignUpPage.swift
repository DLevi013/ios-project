//
//  SignUpPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/16/25.
//

import UIKit
import FirebaseAuth

class SignUpPage: UIViewController {

    @IBOutlet weak var userIDField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var passwordConfirmField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func signupPressed(_ sender: Any) {
        if passwordField.text != passwordConfirmField.text {
            showError(title: "Bad Password", message: "Passwords do not match.")
            return
        }
        if passwordField.text?.isEmpty == true {
            showError(title: "Bad Password", message: "Password cannot be empty.")
        }
        if userIDField.text?.isEmpty == true {
            showError(title: "Bad email", message: "Email cannot be empty.")
        }
        Auth.auth().createUser(withEmail: userIDField.text!, password: passwordField.text!) {
            (authResult, error) in
            if (error != nil) {
                self.showError(title: "Error", message: error?.localizedDescription ?? "Easter Egg unlocked.")
            } else if (authResult != nil) {
                print(authResult!)
                self.showError(title:"Account created", message: "Account created successfully.")
            }
        }
        
        
    }
    
    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
