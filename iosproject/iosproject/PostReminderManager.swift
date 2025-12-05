//
//  PostReminder.swift
//  iosproject
//
//  Created by Ian Tran on 12/4/25.
//

import UIKit
import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseDatabase

class PostReminderManager {
    static let shared = PostReminderManager()
    
    private let ref = Database.database().reference()
    
    // Notification identifiers
    private let dailyReminderIdentifier = "daily-post-reminder"
    private let streakReminderIdentifier = "streak-post-reminder"
    
    private init() {}
    
    // Schedule daily post reminders
    func scheduleDailyReminders() {
        // Cancel existing reminders first
        cancelAllReminders()
        
        // Check if user has notifications enabled
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        ref.child("users").child(userId).child("notificationsEnabled").observeSingleEvent(of: .value) { snapshot in
            let notificationsEnabled = snapshot.value as? Bool ?? true
            
            guard notificationsEnabled else {
                print("NOTIFICATIONS DISABLED: not scheduling reminders")
                return
            }
            
            // Schedule multiple reminders throughout the day
            self.scheduleReminderAt(hour: 9, minute: 0, identifier: "morning-reminder", message: "Good morning! 🍳 Share what you're eating today!")
            self.scheduleReminderAt(hour: 12, minute: 0, identifier: "afternoon-reminder", message: "Lunchtime! 🍽️ Post your meal to share with others!")
            self.scheduleReminderAt(hour: 18, minute: 0, identifier: "evening-reminder", message: "Dinner time! 🥘 Don't forget to share your food adventure!")
            
            print("Daily post reminders scheduled successfully")
        }
    }
    
    // Schedule a reminder at a specific time
    private func scheduleReminderAt(hour: Int, minute: Int, identifier: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Post! 📸"
        content.body = message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "POST_REMINDER"
        
        // Add user info for tracking
        content.userInfo = [
            "type": "post_reminder",
            "reminderType": identifier
        ]
        
        // Create date components for the trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Create trigger that repeats daily
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error.localizedDescription)")
            } else {
                print("Reminder scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // Schedule streak-based reminder (every 3 days if no posts)
    func scheduleStreakReminder() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Check when user last posted
        ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
            
            var lastPostTimestamp: TimeInterval = 0
            
            // Find the most recent post
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let timestamp = dict["timestamp"] as? TimeInterval {
                    if timestamp > lastPostTimestamp {
                        lastPostTimestamp = timestamp
                    }
                }
            }
            
            let now = Date().timeIntervalSince1970
            let daysSinceLastPost = (now - lastPostTimestamp) / 86400 // 86400 seconds in a day, convert seconds to days
            
            // If user hasn't posted in 3+ days, send a reminder
            if daysSinceLastPost >= 3 {
                self.sendStreakReminder(daysSinceLastPost: Int(daysSinceLastPost))
            }
        }
    }
    
    // Send Duolingo-like streak reminder notification if not posting for 3+ days
    // different messages depending on how long
    private func sendStreakReminder(daysSinceLastPost: Int) {
        let content = UNMutableNotificationContent()
        content.title = "We miss you! 😢"
        
        if daysSinceLastPost < 7 {
            content.body = "It's been \(daysSinceLastPost) days since your last post. Share something delicious today!"
        } else if daysSinceLastPost < 30 {
            content.body = "Come back! Your friends want to see what you're eating! 🍕"
        } else {
            content.body = "Long time no see! Share your latest food discovery with us! 🍖"
        }
        
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "STREAK_REMINDER"
        
        content.userInfo = [
            "type": "streak_reminder",
            "daysSinceLastPost": daysSinceLastPost
        ]
        
        // Show immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: streakReminderIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending streak reminder: \(error.localizedDescription)")
            } else {
                print("Streak reminder sent")
            }
        }
    }
    
    // Send Duolingo-styled reminder after posting
    func sendMotivationalReminder(postsCount: Int) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        // Different messages based on post count milestones
        switch postsCount {
        case 1:
            content.title = "Great start! 🎉"
            content.body = "You made your first post! Keep sharing your food journey!"
        case 5:
            content.title = "You're on fire! 🔥"
            content.body = "5 posts already! You're becoming a food icon!"
        case 10:
            content.title = "Amazing! 🌟"
            content.body = "10 posts! Your friends will love your food content!"
        case 25:
            content.title = "Incredible! 🏆"
            content.body = "25 posts! You're a foodie superstar!"
        case 50:
            content.title = "Legendary! 👑"
            content.body = "50 posts! You've inspired so many food lovers!"
        case 100:
            content.title = "Century! 💯"
            content.body = "100 posts! You're a true food content creator!"
        default:
            return // Don't send for other counts
        }
        
        content.categoryIdentifier = "MILESTONE"
        content.userInfo = ["type": "milestone", "postsCount": postsCount]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "milestone-\(postsCount)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Cancel all reminders
    func cancelAllReminders() {
        let identifiers = [
            "morning-reminder",
            "afternoon-reminder",
            "evening-reminder",
            streakReminderIdentifier
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("All reminders cancelled")
    }
    
    // Get scheduled notifications (for debugging)
    func getScheduledNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
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
