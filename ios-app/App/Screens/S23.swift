import SwiftUI

/// S23 · Expected vs actual
struct S23View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S23", subtitle: "NOT BUILT YET")
        }
    }
}
