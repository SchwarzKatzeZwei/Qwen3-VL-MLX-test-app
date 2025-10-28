import SwiftUI

@main
struct QwenVLDemoApp: App {
    @StateObject private var viewModel = QwenVLViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
