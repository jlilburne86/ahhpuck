import SwiftUI

/// S15 · Proposal
struct S15View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S15", subtitle: "NOT BUILT YET")
        }
    }
}
