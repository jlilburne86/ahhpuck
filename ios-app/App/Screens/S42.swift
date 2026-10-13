import SwiftUI

/// S42 · Glossary & help
struct S42View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        PhoneScreen(tab: nil) {
            ScreenHeader(title: "S42", subtitle: "NOT BUILT YET")
        }
    }
}
