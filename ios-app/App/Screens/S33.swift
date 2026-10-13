import SwiftUI

/// S33 · Raw frames (tuner)
struct S33View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S33", subtitle: "NOT BUILT YET")
        }
    }
}
