//
//  OtherProfilePage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/22/25.
//

import UIKit
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class OtherProfilePage: UIViewController {
    
    var otherUserNameText = ""
    var otherUserID = ""
    @IBOutlet weak var otherUserName: UILabel!
    
    @IBOutlet weak var otherBio: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        otherUserName.text = otherUserNameText
        let db = Firestore.firestore()
        var ref : DatabaseReference!
        ref = Database.database().reference().child("users").child(otherUserID)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "userName").value as? String {
                self.otherUserName.text = username
            }
            if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                self.otherBio.text = bio
            }
        }
        print(otherUserID)

        // Do any additional setup after loading the view.
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
