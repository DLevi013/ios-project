//
//  FeedPost.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/20/25.
//

import UIKit

struct FeedPost {
    let postId: String
    let userId: String
    var username: String?
    var postImage: UIImage?
    let timestamp: Int
    var likeCount: Int
    var comments: [Comment]
    let location: String
    let caption: String
}
