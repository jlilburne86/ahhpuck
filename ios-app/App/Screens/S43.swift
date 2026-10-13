import SwiftUI

/// S43 · ECU capabilities · limits come from the ECU
struct S43View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S43", subtitle: "NOT BUILT YET")
        }
    }
}
