//
//  UsernameCache.swift
//  iosproject
//
//  Created by Ian Tran on 11/19/25.
//

import Foundation
import FirebaseDatabase

class UsernameCache {
    static let shared = UsernameCache()
    
    private var cache: [String: String] = [:]
    private let ref = Database.database().reference()
    
    private init() {}
    
    func getUsername(for userId: String, completion: @escaping (String?) -> Void) {
        if let cachedUsername = cache[userId] {
            completion(cachedUsername)
            return
        }
        
        ref.child("users").child(userId).child("username").observeSingleEvent(of: .value) { (snapshot) in
            if let username = snapshot.value as? String {
                self.cache[userId] = username
                completion(username)
            } else {
                completion(nil)
            }
        }
    }
    
    func getUsernames(for userIds: [String], completion: @escaping ([String: String]) -> Void) {
        var usernames: [String: String] = [:]
        
        let group = DispatchGroup()
        
        for userId in userIds {
            group.enter()
            self.getUsername(for: userId) { (username) in
                if let username {
                    usernames[userId] = username
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(usernames)
        }
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    func invalidate(userId: String) {
        cache.removeValue(forKey: userId)
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
