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

class ModeTableViewController: UITableViewController {

    var isPrivate: Bool = false
    var isDark: Bool = false
    var isNotif: Bool = false
    @IBOutlet weak var privateSwitch: UISwitch!

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
                guard let url = URL(string: urlString),
                      let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
                    return nil
                }
                for item in queryItems {
                    if item.name == "o", let value = item.value?.removingPercentEncoding {
                        return value
                    }
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
