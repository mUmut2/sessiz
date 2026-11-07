import SwiftUI

@main
struct SessizApp: App {
    init() {
        AdsConfig.startIfEnabled()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
