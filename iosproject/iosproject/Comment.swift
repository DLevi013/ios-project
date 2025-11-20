//
//  Comment.swift
//  iosproject
//
//  Created by Isaac Thomas on 10/29/25.
//

import UIKit

struct Comment {
    let commentId: String
    let userId: String
    let text: String
    let timestamp: Date
    var username: String?
}

extension Comment {
    func toDict() -> [String: Any] {
        return [
            "commentId": commentId,
            "userId": userId,
            "text": text,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }

    static func from(dict: [String: Any]) -> Comment? {
        guard let commentId = dict["commentId"] as? String,
              let userId = dict["userId"] as? String,
              let text = dict["text"] as? String,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        return Comment(commentId: commentId, userId: userId, text: text, timestamp: Date(timeIntervalSince1970: timestamp), username: nil)
    }
}
