import SwiftUI

/// S05 · Preflight checklist
struct S05View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S05", subtitle: "NOT BUILT YET")
        }
    }
}
