import SwiftUI

/// S10 · Run setup
struct S10View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S10", subtitle: "NOT BUILT YET")
        }
    }
}
