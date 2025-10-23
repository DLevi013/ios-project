//
//  SettingsPage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/17/25.
//

import UIKit
import FirebaseAuth

class SettingsPage: ModeViewController {
    var isPrivate: Bool = false
    var isDark: Bool = false
    var isNotif: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func pressedProfileButton(_ sender: Any) {
        self.performSegue(withIdentifier: "settingsToProfileSegue", sender: nil)
    }
    
    @IBAction func DarkSwitch(_ sender: UISwitch) {
        isDark = sender.isOn
        // print("Darkmode: \(isDark)")
        ThemeManager.shared.toggleMode(isDark: isDark)
    }
    
    @IBAction func NotificationSwitch(_ sender: UISwitch) {
        isNotif = sender.isOn
        print("Notification: \(isNotif)")
    }
    
    @IBAction func PrivateSwitch(_ sender: UISwitch) {
        isPrivate = sender.isOn
        print("Private: \(isPrivate)")
    }
    @IBAction func logOffButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "settingsLogoutSegue", sender: nil)
        } catch _ as NSError {
            // this shouldn't happen
            print("No signin detected.")
        }
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
