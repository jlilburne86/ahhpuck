import SwiftUI

/// S13 · Investigation log
struct S13View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S13", subtitle: "NOT BUILT YET")
        }
    }
}
