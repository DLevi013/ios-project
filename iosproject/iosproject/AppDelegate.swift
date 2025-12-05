//
//  AppDelegate.swift
//  iosproject
//
//  Created by Daniel Levi on 10/8/25.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        // Request notification permissions
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Notification authorization error: \(error.localizedDescription)")
                    }
                    
                    if granted {
                        print("Notification permission granted")
                        
                        // Schedule daily post reminders if user is logged in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if Auth.auth().currentUser != nil {
                                PostReminderManager.shared.scheduleDailyReminders()
                            }
                        }
                    } else {
                        print("Notification permission denied")
                    }
                    
                    self.setupNotificationActions()
                }
        
        return true
    }
    
    private func setupNotificationActions() {
            let postAction = UNNotificationAction(
                identifier: "POST_ACTION",
                title: "Post Now 📸",
                options: .foreground
            )
            
            let remindLaterAction = UNNotificationAction(
                identifier: "REMIND_LATER",
                title: "Remind Me Later ⏰",
                options: []
            )
            
            let postReminderCategory = UNNotificationCategory(
                identifier: "POST_REMINDER",
                actions: [postAction, remindLaterAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([postReminderCategory])
        }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - UNUserNotificationCenterDelegate
        
        // Handle notification when app is in foreground
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            // Show notification even when app is in foreground
            completionHandler([.banner, .sound, .badge])
        }
        
        // Handle notification tap and actions
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            let userInfo = response.notification.request.content.userInfo
            
            print("Notification action: \(response.actionIdentifier)")
            
            switch response.actionIdentifier {
            case "POST_ACTION":
                // User wants to post now - navigate to Add Post screen
                NotificationCenter.default.post(
                    name: NSNotification.Name("navigateToAddPost"),
                    object: nil
                )
                
            case "REMIND_LATER":
                // Remind again in 2 hours
                scheduleRemindLater()
                
            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification itself
                if let type = userInfo["type"] as? String, type == "post_reminder" {
                    // Navigate to Add Post screen
                    NotificationCenter.default.post(
                        name: NSNotification.Name("navigateToAddPost"),
                        object: nil
                    )
                }
                
            default:
                break
            }
            
            completionHandler()
        }
        
        // Schedule a "remind me later" notification
        private func scheduleRemindLater() {
            let content = UNMutableNotificationContent()
            content.title = "Don't forget! 📸"
            content.body = "Time to share what you're eating!"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "POST_REMINDER"
            
            // Trigger in 2 hours
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
            let request = UNNotificationRequest(identifier: "remind-later", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling remind later: \(error.localizedDescription)")
                } else {
                    print("Remind later scheduled for 2 hours")
                }
            }
        }
}
