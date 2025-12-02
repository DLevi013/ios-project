import Foundation
import FirebaseDatabase

class ProfileImageCache {
    static let shared = ProfileImageCache()
    private var cache = [String: String]() // userId -> profileImageURL
    private let queue = DispatchQueue(label: "ProfileImageCacheQueue")

    private init() {}

    func getProfileImageURL(for userId: String, completion: @escaping (String?) -> Void) {
        queue.sync {
            if let url = cache[userId] {
                DispatchQueue.main.async { completion(url) }
                return
            }
        }
        // Fetch from database if not cached
        let ref = Database.database().reference().child("users").child(userId).child("profileImageURL")
        ref.observeSingleEvent(of: .value) { snapshot in
            let url = snapshot.value as? String
            self.queue.async {
                self.cache[userId] = url
            }
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }

    func clearCache() {
        queue.async {
            self.cache.removeAll()
        }
    }
}
