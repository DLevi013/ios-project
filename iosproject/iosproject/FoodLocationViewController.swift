//
//  FoodLocationViewController.swift
//  iosproject
//
//  Created by Austin Nguyen on 11/11/25.
//

import UIKit

class FoodLocationViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressValue: UILabel!
    
    var name: String = ""
    var address: String = ""
    var delegate : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameLabel.text = name
        addressValue.text = address
    }
    

}
