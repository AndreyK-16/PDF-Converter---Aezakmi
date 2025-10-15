//
//  UserDefaultsManager.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import Foundation
class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let hasSeenWelcomeKey = "hasSeenWelcome"
    
    var hasSeenWelcome: Bool {
        get {
            return UserDefaults.standard.bool(forKey: hasSeenWelcomeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasSeenWelcomeKey)
        }
    }
}
