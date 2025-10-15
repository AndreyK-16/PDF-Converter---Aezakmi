//___FILEHEADER___

import SwiftUI

@main
struct PDF_Converter___Aezakmi: App {
    let persistenceController = PersistenceController.shared
    @State private var shouldShowWelcome = !UserDefaultsManager.shared.hasSeenWelcome
    
    var body: some Scene {
        WindowGroup {
            Group {
                if shouldShowWelcome {
                    WelcomeView(shouldShowWelcome: $shouldShowWelcome)
                } else {
                    MainTabView()
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .preferredColorScheme(.dark)
        }
    }
}
