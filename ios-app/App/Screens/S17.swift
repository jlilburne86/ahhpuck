import SwiftUI

/// S17 · Concerns & rollback plan
struct S17View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S17", subtitle: "NOT BUILT YET")
        }
    }
}
