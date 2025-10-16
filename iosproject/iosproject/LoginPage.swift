//
//  LoginPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/15/25.
//

import UIKit
import FirebaseAuth

class LoginPage: UIViewController {

    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
