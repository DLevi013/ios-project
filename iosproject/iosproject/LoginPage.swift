//
//  LoginPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/15/25.
//

import UIKit
import FirebaseAuth

class LoginPage: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userIDTextField.delegate = self
        passwordTextField.delegate = self
        
        print("START")
        Auth.auth().addStateDidChangeListener() {
            (auth, user) in
            if user != nil {
                print("USER " + user!.uid)
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
                self.userIDTextField.text = ""
                self.passwordTextField.text = ""
            }
        }
        // Do any additional setup after loading the view.
    }
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
        
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        if userIDTextField.text?.isEmpty == true {
            showError(title: "Bad email", message: "Email cannot be empty.")
            return
        }
        if passwordTextField.text?.isEmpty == true {
            showError(title: "Bad Password", message: "Password cannot be empty.")
            return
        }
        Auth.auth().signIn(withEmail: userIDTextField.text!, password: passwordTextField.text!) {
            (authResult, error) in
            if let error = error as NSError? {
                self.showError(title: "login error", message: error.localizedDescription)
            }
        }
    }
    
    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
