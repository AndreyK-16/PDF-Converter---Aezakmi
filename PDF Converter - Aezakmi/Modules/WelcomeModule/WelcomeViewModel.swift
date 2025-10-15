//
//  WelcomeViewModel.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import UIKit

class WelcomeViewModel: ObservableObject {
    private let userDefaultsManager = UserDefaultsManager.shared
        
        func markWelcomeAsSeen() {
            userDefaultsManager.hasSeenWelcome = true
            triggerHapticFeedback()
        }
        
        private func triggerHapticFeedback() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
}
