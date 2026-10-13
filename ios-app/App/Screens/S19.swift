import SwiftUI

/// S19 · Run overlay
struct S19View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S19", subtitle: "NOT BUILT YET")
        }
    }
}
