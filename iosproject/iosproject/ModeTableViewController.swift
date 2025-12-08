//
//  ModeTableViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 11/20/25.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import CoreLocation

// hopefully allows notification check to be easier
var isNotif: Bool = true

class ModeTableViewController: UITableViewController, CLLocationManagerDelegate {

    var isPrivate: Bool = false
    var isDark: Bool = false
    // var isNotif: Bool = false
    @IBOutlet weak var privateSwitch: UISwitch!
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    
    fileprivate let locationManager: CLLocationManager = CLLocationManager()
    @IBOutlet weak var locationStatus: UILabel!
    @IBOutlet weak var locationButton: UIButton!
    
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
        
        locationManager.delegate = self
        locationButton.tintColor = .systemBlue
        updateLocationLabel()
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
    
    func updateLocationLabel() {
        let status = self.locationManager.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse:
            locationStatus.text = "Allowed when in use"
            locationButton.isUserInteractionEnabled = true
            locationButton.setTitleColor(.systemBlue, for: .normal)
            locationButton.tintColor = .systemBlue
        case .authorizedAlways:
            locationStatus.text = "Allowed always"
            locationButton.isUserInteractionEnabled = true
            locationButton.setTitleColor(.systemBlue, for: .normal)
            locationButton.tintColor = .systemBlue
        case .denied:
            locationStatus.text = "Never"
            locationButton.isUserInteractionEnabled = true
            locationButton.setTitleColor(.systemGray, for: .normal)
            locationButton.tintColor = .systemGray
        default:
            locationStatus.text = "Not allowed"
            locationButton.isUserInteractionEnabled = true
            locationButton.setTitleColor(.systemGray, for: .normal)
            locationButton.tintColor = .systemGray
        }
    }

    @IBAction func locationPressed(_ sender: Any) {
        
        let status = self.locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorizedAlways:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .denied:
            self.locationManager.requestWhenInUseAuthorization()
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        default:
            self.locationManager.requestWhenInUseAuthorization()
        }
        updateLocationLabel()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            updateLocationLabel()
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
    
    @IBAction func deleteAccountButton(_ sender: Any) {
        let alertController = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive){_ in
            
            guard let user = Auth.auth().currentUser else { return }
            let uid = user.uid
            let ref = Database.database().reference()
            let storage = Storage.storage()

            func extractStoragePath(from urlString: String) -> String? {
                guard let url = URL(string: urlString) else { return nil }
                guard URLComponents(url: url, resolvingAgainstBaseURL: false) != nil else { return nil }

                // find the "/o/" part in the path and extract the encoded path after it
                if let range = url.path.range(of: "/o/") {
                    let encodedPath = String(url.path[range.upperBound...])
                    return encodedPath.removingPercentEncoding
                }
                return nil
            }
            
            // delete all user's posts
            ref.child("posts").observeSingleEvent(of: .value) { snapshot in
                let group = DispatchGroup()
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let dict = childSnapshot.value as? [String: Any],
                          let postUserId = dict["userId"] as? String,
                          postUserId == uid,
                          let postId = dict["postId"] as? String else { continue }

                    group.enter()
                    
                    // delete post image from Storage
                    if let imageString = dict["image"] as? String, !imageString.isEmpty {
                        let imagePath = extractStoragePath(from: imageString) ?? imageString
                        storage.reference(withPath: imagePath).delete { error in
                            if let error = error {
                                print("Failed to delete post image at \(imagePath): \(error.localizedDescription)")
                            } else {
                                print("Successfully deleted post image at \(imagePath)")
                            }
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                    
                    // remove postId from location's postIds and possibly location if its the last post in that location
                    if let locationId = dict["locationId"] as? String, !locationId.isEmpty {
                        let locationRef = ref.child("locations").child(locationId).child("postIds").child(postId)
                        locationRef.removeValue { _, _ in
                            // clean up location if no posts remain
                            let parentLocationRef = ref.child("locations").child(locationId).child("postIds")
                            parentLocationRef.observeSingleEvent(of: .value) { postsSnap in
                                if postsSnap.childrenCount == 0 {
                                    ref.child("locations").child(locationId).removeValue()
                                }
                            }
                        }
                    }
                    // remove the post itself
                    ref.child("posts").child(postId).removeValue()
                }
                
                group.notify(queue: .main) {
                    // remove profile picture and remove self from friend's friends lists
                    ref.child("users").child(uid).observeSingleEvent(of: .value) { snap,_  in
                        if let userDict = snap.value as? [String: Any],
                           let imageString = userDict["profileImageURL"] as? String, !imageString.isEmpty {
                            let imagePath = extractStoragePath(from: imageString) ?? imageString
                            storage.reference(withPath: imagePath).delete { error in
                                if let error = error {
                                    print("Failed to delete profile image at \(imagePath): \(error.localizedDescription)")
                                } else {
                                    print("Successfully deleted profile image at \(imagePath)")
                                }
                            }

                            // remove self from friend's friends lists
                            if let friendsDict = userDict["friends"] as? [String: Any] {
                                for (_, friendUIDValue) in friendsDict {
                                    if let friendUID = friendUIDValue as? String {
                                        ref.child("users").child(friendUID).child("friends").observeSingleEvent(of: .value) { friendSnap in
                                            for friendChild in friendSnap.children {
                                                if let friendItem = friendChild as? DataSnapshot, let friendId = friendItem.value as? String, friendId == uid {
                                                    ref.child("users").child(friendUID).child("friends").child(friendItem.key).removeValue()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // remove user from users
                        ref.child("users").child(uid).removeValue { _, _ in
                            // delete Firebase Auth user
                            user.delete { _ in
                                do {
                                    try Auth.auth().signOut()
                                    self.performSegue(withIdentifier: "settingsLogoutSegue", sender: nil)
                                } catch _ as NSError {
                                    print("No signin detected.")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true)
    }
}

