import SwiftUI
import FirebaseCore

@main
struct TranslateMeApp: App {
    @StateObject private var viewModel = TranslationViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
