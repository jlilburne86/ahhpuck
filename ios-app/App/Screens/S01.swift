import SwiftUI

/// S01 · Welcome & safety boundary
struct S01View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S01", subtitle: "NOT BUILT YET")
        }
    }
}
