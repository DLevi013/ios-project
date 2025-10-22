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
    @IBOutlet weak var otherUserName: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        otherUserName.text = otherUserNameText

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
