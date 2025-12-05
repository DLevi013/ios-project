//
//  ModeTableViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 11/20/25.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

// hopefully allows notification check to be easier
var isNotif: Bool = false

class ModeTableViewController: UITableViewController {

    var isPrivate: Bool = false
    var isDark: Bool = false
    // var isNotif: Bool = false
    @IBOutlet weak var privateSwitch: UISwitch!
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeChanged, object: nil)
        // Settings logic from former SettingsPage
        var ref: DatabaseReference!
        ref = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            // shouldn't pass unless something happened
            self.showError(title: "Bad User", message: "Invalid Session")
            self.performSegue(withIdentifier: "settingsLogoutSegue", sender: nil)
            // might be overkill, but just make the user log out, and have them login with a new session
            return
        }

        ref.child("users").child(uid).child("isPrivate").observeSingleEvent(of: .value) { snapshot in
            if let isPrivate = snapshot.value as? Bool {
                DispatchQueue.main.async {
                    self.privateSwitch.isOn = isPrivate
                }
            } else {
                self.privateSwitch.isOn = false
            }
        }
        
        // Load notification setting
        ref.child("users").child(uid).child("notificationsEnabled").observeSingleEvent(of: .value) { (snapshot: DataSnapshot, _: String?)  in
            if let notificationsEnabled = snapshot.value as? Bool {
                DispatchQueue.main.async {
                    self.notificationSwitch.isOn = notificationsEnabled
                    isNotif = notificationsEnabled
                }
            } else {
                self.notificationSwitch.isOn = true
                isNotif = true
            }
        }
    }
    
    @objc func applyTheme() {
        view.backgroundColor = AppColors.screen
        applyThemeRecursively(to: view)
    }

    private func applyThemeRecursively(to view: UIView) {
        for subview in view.subviews {
            switch subview {
            case let label as UILabel:
                label.textColor = AppColors.text
            case let button as UIButton:
                button.tintColor = AppColors.text
            case let table as UITableView:
                table.backgroundColor = AppColors.secondaryBackground
            case let tableCell as UITableViewCell:
                tableCell.backgroundColor = AppColors.secondaryBackground
            case let searchBarUI as UISearchBar:
                searchBarUI.barTintColor = AppColors.secondaryBackground
            case let collectionView as UICollectionView:
                collectionView.backgroundColor = AppColors.screen
            case let collectionViewCell as UICollectionViewCell:
                collectionViewCell.backgroundColor = AppColors.screen
            case let selectedSegmentedControl as UISegmentedControl:
                selectedSegmentedControl.selectedSegmentTintColor = AppColors.segmentedControlIndex
            default:
                if subview.tag == 100 {
                    subview.backgroundColor = AppColors.banner
                }
            }
            applyThemeRecursively(to: subview)
        }
    }

    @IBAction func pressedProfileButton(_ sender: Any) {
        self.performSegue(withIdentifier: "settingsToProfileSegue", sender: nil)
    }

    @IBAction func darkSwitch(_ sender: UISwitch) {
        isDark = sender.isOn
        ThemeManager.shared.toggleMode(isDark: isDark)
    }

    @IBAction func notificationSwitch(_ sender: UISwitch) {
        isNotif = sender.isOn
        print("Notification: \(isNotif)")
        let ref = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            self.showError(title: "Bad User", message: "Invalid Session")
            return
        }
        
        if isNotif {
            // User wants to enable notifications; request permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        // Permission granted; schedule reminders
                        PostReminderManager.shared.scheduleDailyReminders()
                        
                        // Save to Firebase
                        ref.child("users").child(uid).child("notificationsEnabled").setValue(true)
                        
                        let alert = UIAlertController(
                            title: "Reminders Enabled! 🎉",
                            message: "We'll send you friendly reminders to post throughout the day.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                        
                    } else {
                        // Permission denied
                        isNotif = false
                        self.notificationSwitch.isOn = false
                        ref.child("users").child(uid).child("notificationsEnabled").setValue(false)
                        
                        self.showNotificationPermissionAlert()
                    }
                }
            }
        } else {
            // User wants to disable notifications
            PostReminderManager.shared.cancelAllReminders()
            ref.child("users").child(uid).child("notificationsEnabled").setValue(false)
            
            let alert = UIAlertController(
                title: "Reminders Disabled",
                message: "We won't send you post reminders anymore.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    private func showNotificationPermissionAlert() {
            let alert = UIAlertController(
                title: "Notification Permission Required",
                message: "Please enable notifications in Settings to receive post reminders.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
        }

    @IBAction func privateSwitch(_ sender: UISwitch) {
        isPrivate = sender.isOn
        print("Private: \(isPrivate)")
        let ref = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else {
            self.showError(title: "Bad User", message: "Invalid Session")
            self.performSegue(withIdentifier: "settingsLogoutSegue", sender: nil)
            return
        }
        ref.child("users").child(uid).child("isPrivate").setValue(isPrivate) { error, _ in
            if let error = error {
                self.showError(title: "Error updating private", message: "error: \(error.localizedDescription)")
            } else {
                print("Successfully set isPrivate to \(self.isPrivate) in firebase.")
            }
        }
    }

    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func logOffButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "settingsLogoutSegue", sender: nil)
        } catch _ as NSError {
            print("No signin detected.")
        }
    }
}
