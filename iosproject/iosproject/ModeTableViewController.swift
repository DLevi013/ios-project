//
//  ModeTableViewController.swift
//  iosproject
//
//  Created by Isaac Thomas on 11/20/25.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

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
}
