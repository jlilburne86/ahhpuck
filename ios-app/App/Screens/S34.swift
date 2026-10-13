import SwiftUI

/// S34 · How AhhPuck works
struct S34View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S34", subtitle: "NOT BUILT YET")
        }
    }
}
