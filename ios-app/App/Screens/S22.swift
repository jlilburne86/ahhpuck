import SwiftUI

/// S22 · Assessment
struct S22View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S22", subtitle: "NOT BUILT YET")
        }
    }
}
