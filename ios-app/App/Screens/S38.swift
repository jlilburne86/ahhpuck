import SwiftUI

/// S38 · Data sources
struct S38View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S38", subtitle: "NOT BUILT YET")
        }
    }
}
