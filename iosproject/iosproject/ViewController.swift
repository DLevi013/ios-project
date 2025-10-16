//
//  ViewController.swift
//  iosproject
//
//  Created by Daniel Levi on 10/8/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            // Wait 1 second, then transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.goToMainView()
            }
        }
        
        func goToMainView() {
            // Load the destination VC from storyboard
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let mainVC = storyboard.instantiateViewController(withIdentifier: "LoginPage") as? LoginPage {
                
                // Make it the new root view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = windowScene.delegate as? SceneDelegate,
                   let window = sceneDelegate.window {
                    window.rootViewController = mainVC
                    window.makeKeyAndVisible()
                    
                    // Optional: add a fade animation
                    UIView.transition(with: window,
                                      duration: 0.4,
                                      options: .transitionCrossDissolve,
                                      animations: nil,
                                      completion: nil)
                }
            }
        }


}

