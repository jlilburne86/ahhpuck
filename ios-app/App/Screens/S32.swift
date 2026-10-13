import SwiftUI

/// S32 · Garage & settings
struct S32View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S32", subtitle: "NOT BUILT YET")
        }
    }
}
