import SwiftUI
import Observation

/// Stable screen IDs from the design (S01–S42).
enum ScreenID: String, CaseIterable, Hashable, Identifiable {
    case S01, S02, S03, S04, S05, S06, S07, S08, S09, S10
    case S11, S12, S13, S14, S15, S16, S17, S18, S19, S20
    case S21, S22, S23, S24, S25, S26, S27, S28, S29, S30
    case S31, S32, S33, S34, S35, S36, S37, S38, S39, S40
    case S41, S42, S43
    var id: String { rawValue }

    /// Full-screen modals with no tab bar (README · Navigation).
    var isFullScreenModal: Bool { [.S11, .S12, .S18].contains(self) }
    /// Bottom sheets: S04 from the status bar, S41 from any gated button.
    var isSheet: Bool { [.S04, .S41].contains(self) }
}

/// AppTab bar: 5 roots (README · Navigation).
enum AppTab: Int, CaseIterable, Identifiable {
    case live, map, runs, review, garage
    var id: Int { rawValue }
    var title: String { ["Live", "Map", "Runs", "Review", "Garage"][rawValue] }
    var root: ScreenID { [.S06, .S09, .S30, .S27, .S32][rawValue] }
}

@MainActor
@Observable
final class Router {
    /// First-run flow: S01 → S34 → S35 → S36 → S04 → S02 → S03, then Live (S40 coach marks on first visit).
    static let firstRun: [ScreenID] = [.S01, .S34, .S35, .S36, .S04, .S02, .S03]

    var onboarding: Bool
    var onboardingPath: [ScreenID] = []
    var tab: AppTab = .live
    var paths: [AppTab: [ScreenID]] = [:]
    var modal: ScreenID?
    var sheet: ScreenID?
    /// S40 shows once, on the first visit to Live.
    var coachMarksPending = true
    /// Debug/screenshot harness: `-screen S06` renders a single screen.
    let single: ScreenID?

    init() {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-screen"), i + 1 < args.count, let id = ScreenID(rawValue: args[i + 1]) {
            single = id
        } else {
            single = nil
        }
        onboarding = !UserDefaults.standard.bool(forKey: "onboardingDone") && !args.contains("-skipOnboarding")
        if args.contains("-skipOnboarding") || args.contains("-screen") { coachMarksPending = false }
    }

    /// Push a screen. Sheets and full-screen modals are presented instead.
    func go(_ id: ScreenID) {
        if id.isFullScreenModal { modal = id; return }
        if id.isSheet { sheet = id; return }
        if onboarding { onboardingPath.append(id); return }
        if let t = AppTab.allCases.first(where: { $0.root == id }) { select(t); return }
        paths[tab, default: []].append(id)
    }

    func back() {
        if onboarding { if !onboardingPath.isEmpty { onboardingPath.removeLast() }; return }
        if paths[tab]?.isEmpty == false { paths[tab]?.removeLast() }
    }

    func dismiss() { modal = nil; sheet = nil }

    /// Tapping the active tab pops it to its root.
    func select(_ t: AppTab) {
        // S03 is optional and its tab bar is the way out of the first-run flow.
        if onboarding { finishOnboarding(); tab = t; return }
        if t == tab { paths[t] = [] }
        tab = t
    }

    /// Advance along the first-run flow; leaving S03 (or skipping it) finishes onboarding.
    func nextInFirstRun(after id: ScreenID) {
        guard let i = Router.firstRun.firstIndex(of: id), i + 1 < Router.firstRun.count else { finishOnboarding(); return }
        let next = Router.firstRun[i + 1]
        if next == .S04 { onboardingPath.append(.S04); return }
        onboardingPath.append(next)
    }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingDone")
        onboarding = false
        onboardingPath = []
        tab = .live
    }
}
