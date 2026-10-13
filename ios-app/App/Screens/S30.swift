import SwiftUI

/// S30 · Learning ledger
struct S30View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S30", subtitle: "NOT BUILT YET")
        }
    }
}
