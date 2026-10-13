import SwiftUI

/// S11 · Recording (modal)
struct S11View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S11", subtitle: "NOT BUILT YET")
        }
    }
}
