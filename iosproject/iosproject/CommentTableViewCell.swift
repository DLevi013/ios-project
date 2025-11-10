//
//  CommentTableViewCell.swift
//  iosproject
//
//  Created by Isaac Thomas on 11/4/25.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func userButtonPressed(_ sender: Any) {
        
    }
}
