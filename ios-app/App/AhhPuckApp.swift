import SwiftUI
import UIKit

@main
struct AhhPuckApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}

/// Tabs, the first-run flow, full-screen modals (S11, S12, S18) and sheets (S04, S41).
struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var router = app.router
        Group {
            if let single = router.single {
                ScreenView(id: single)
            } else if router.onboarding {
                NavigationStack(path: $router.onboardingPath) {
                    ScreenView(id: .S01)
                        .navigationDestination(for: ScreenID.self) { ScreenView(id: $0) }
                }
            } else {
                ZStack {
                    ForEach(AppTab.allCases) { tab in
                        NavigationStack(path: Binding(get: { router.paths[tab] ?? [] }, set: { router.paths[tab] = $0 })) {
                            ScreenView(id: tab.root)
                                .navigationDestination(for: ScreenID.self) { ScreenView(id: $0) }
                        }
                        .opacity(router.tab == tab ? 1 : 0)
                        .allowsHitTesting(router.tab == tab)
                    }
                }
            }
        }
        .background(AP.screen)
        .fullScreenCover(item: $router.modal) { ScreenView(id: $0).environment(app) }
        .sheet(item: $router.sheet) { id in
            ScreenView(id: id)
                .environment(app)
                .presentationDetents([.large])
                .presentationCornerRadius(22)
                .presentationBackground(AP.screen)
        }
    }
}

/// One screen, with the system navigation bar hidden (every screen draws its own header).
struct ScreenView: View {
    let id: ScreenID
    var body: some View {
        screen(id)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
    }
}

/// Keep the edge-swipe back gesture with the navigation bar hidden.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
