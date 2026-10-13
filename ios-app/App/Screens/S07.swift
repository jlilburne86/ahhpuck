import SwiftUI

/// S07 · Live · stale / lost telemetry
struct S07View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S07", subtitle: "NOT BUILT YET")
        }
    }
}
