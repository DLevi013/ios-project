//
//  PostTableViewCell.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/20/25.
//

import UIKit

protocol PostTableViewCellDelegate: AnyObject {
    func didTapLikeButton(on cell: PostTableViewCell)
    func didTapProfileButton(on cell: PostTableViewCell)
    func didTapLocation(on cell: PostTableViewCell)
}


class PostTableViewCell: UITableViewCell {
  
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    
    weak var delegate: PostTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func likeButtonPressed(_ sender: Any) {
        delegate?.didTapLikeButton(on: self)
        
    }
    
    @IBAction func profileButtonTapped(_ sender: Any) {
        delegate?.didTapProfileButton(on: self)
    }
    
    @IBAction func locationButtonPressed(_ sender: Any) {
        delegate?.didTapLocation(on: self)
    }
    
    
}
