import SwiftUI

/// S41 · "Why is this locked?" sheet
struct S41View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S41", subtitle: "NOT BUILT YET")
        }
    }
}
