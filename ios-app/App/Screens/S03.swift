import SwiftUI

/// S03 · Phone mount calibration
struct S03View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S03", subtitle: "NOT BUILT YET")
        }
    }
}
