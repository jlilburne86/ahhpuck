import SwiftUI

/// S36 · Hardware guide · ECU first
struct S36View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S36", subtitle: "NOT BUILT YET")
        }
    }
}
