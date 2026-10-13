import SwiftUI

/// S24 · Result dial & objective radar
struct S24View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S24", subtitle: "NOT BUILT YET")
        }
    }
}
