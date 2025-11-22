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
    let imageUrl: String? // Optional URL string for the post image
    let timestamp: Int
    var likeCount: Int
    var comments: [Comment]
    let location: String
    let caption: String
    
    init(postId: String,
         userId: String,
         username: String? = nil,
         postImage: UIImage? = nil,
         imageUrl: String? = nil,
         timestamp: Int,
         likeCount: Int,
         comments: [Comment],
         location: String,
         caption: String) {
        self.postId = postId
        self.userId = userId
        self.username = username
        self.postImage = postImage
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.comments = comments
        self.location = location
        self.caption = caption
    }
}
