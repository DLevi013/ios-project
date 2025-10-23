//
//  ThemeManger.swift
//  iosproject
//
//  Created by Austin Nguyen on 10/22/25.
//

import Foundation
import UIKit

class ThemeManager {
    static let shared = ThemeManager()
    
    enum ThemeMode {
        case light
        case dark
    }
    
    var currentMode: ThemeMode = .light {
        didSet {
            UserDefaults.standard.set(currentMode == .dark, forKey: "mode")
            NotificationCenter.default.post(name: .themeChanged, object: nil)
        }
    }

    private init() {
        currentMode = .light
        UserDefaults.standard.set(false, forKey: "mode")
        
//        let isDark = UserDefaults.standard.bool(forKey: "mode")
//        currentMode = isDark ? .dark : .light
    }
    
    func toggleMode(isDark : Bool) {
        currentMode = isDark ? .dark : .light
    }
    
}

extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
}
