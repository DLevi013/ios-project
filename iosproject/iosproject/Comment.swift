//
//  Comment.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/29/25.
//

import UIKit

struct Comment {
    let commentId: String
    let username: String
    let text: String
    let timestamp: Date
}

extension Comment {
    func toDict() -> [String: Any] {
        return [
            "commentId": commentId,
            "username": username,
            "text": text,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    static func from(dict: [String: Any]) -> Comment? {
        guard let commentId = dict["commentId"] as? String,
              let username = dict["username"] as? String,
              let text = dict["text"] as? String,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        return Comment(commentId: commentId, username: username, text: text, timestamp: Date(timeIntervalSince1970: timestamp))
    }
}
