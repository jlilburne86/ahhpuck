import SwiftUI

/// S12 · Critical alert (modal)
struct S12View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S12", subtitle: "NOT BUILT YET")
        }
    }
}
