import SwiftUI

/// S41 · "Why is this locked?" sheet. Every gated button opens it. In the design it is drawn over
/// a dimmed Proposal screen; the `-screen S41` harness renders that whole composition, and the
/// live app presents only the sheet panel.
struct S41View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        if app.router.single == .S41 {
            PhoneScreen(tab: .review, status: "OFFLINE", statusStyle: .dim, scrolls: false) {
                ScreenHeader(title: "Proposal", subtitle: "DRIVABILITY · FUEL ONLY")
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 8), spacing: 3) {
                            ForEach(Array(S41View.backdrop.enumerated()), id: \.offset) { _, on in
                                RoundedRectangle(cornerRadius: 4).fill(on ? AP.raised : Color(hex: 0x121315)).frame(height: 34)
                            }
                        }
                        .opacity(0.35)
                        .padding(.horizontal, 18).padding(.top, 12)
                        Spacer(minLength: 0)
                    }
                    Color.black.opacity(0.55)
                    CWhyPanel()
                }
                .frame(maxHeight: .infinity)
            }
        } else {
            ScrollView { CWhyPanel(sheet: true) }
                .scrollBounceBehavior(.basedOnSize)
                .background(AP.card)
                .presentationDetents([.height(460), .large])
                .presentationDragIndicator(.hidden)
        }
    }

    static let backdrop: [Bool] = "011000100101000010000101001000110000110001001010".map { $0 == "1" }
}

/// The sheet panel: grabber, title, the blocking conditions and the CTA (port of `whyRows`).
struct CWhyPanel: View {
    @Environment(AppModel.self) private var app
    var sheet = false

    struct Row { let k: String?; let t: String; let d: String; let act: String; let go: ScreenID?; let c: Status }
    static let rows: [Row] = [
        Row(k: "inv", t: "Investigation open", d: "EVT-0413-01 · lean under load", act: "Open S13", go: .S13, c: .stop),
        Row(k: "prof", t: "Vehicle profile incomplete", d: "Load strategy is Unknown", act: "Fix in S02", go: .S02, c: .caution),
        Row(k: nil, t: "Preflight passed", d: "Today 10:12", act: "", go: nil, c: .ok),
        Row(k: nil, t: "Baseline recorded", d: "Baseline 03 · sha 3f9a…c21e", act: "", go: nil, c: .ok),
        Row(k: nil, t: "ECU writes locked", d: "Always, in this release", act: "", go: nil, c: .ok),
    ]

    var body: some View {
        let shown = CWhyPanel.rows.map { r -> (Row, Status, Bool) in
            let cleared = r.k.map { app.why[$0] ?? false } ?? false
            return (r, cleared ? .ok : r.c, cleared)
        }
        let blk = shown.filter { $0.1 != .ok }.count
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 3).fill(AP.hatchA).frame(width: 40, height: 5).frame(maxWidth: .infinity)
            T(app.tr("Why is this locked?"), .barlow, 28, 700).apFont(.barlow, 28, 700, lineHeight: 1)
            T(app.tr("Proposals unlock when every item shows ✓. Tap a blocking item to preview clearing it."), .sans, 13)
                .apFont(.sans, 13).foregroundStyle(AP.text3).fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 0) {
                ForEach(shown, id: \.0.t) { r, st, cleared in
                    HStack(spacing: 10) {
                        T(st.glyph, .sans, 11, 700).apFont(.sans, 11, 700)
                            .foregroundStyle(st == .stop ? Color.white : AP.ink)
                            .frame(width: 20, height: 20)
                            .background(RoundedRectangle(cornerRadius: 5).fill(st.color))
                        VStack(alignment: .leading, spacing: 1) {
                            T(app.tr(r.t), .sans, 13).apFont(.sans, 13)
                            T(app.tr(cleared ? "Cleared (preview)" : r.d), .mono, 10).apFont(.mono, 10).foregroundStyle(AP.label)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if !cleared, !r.act.isEmpty {
                            T(app.tr(r.act), .mono, 10).apFont(.mono, 10).foregroundStyle(AP.text2).lineLimit(1).fixedSize()
                                .contentShape(Rectangle())
                                .onTapGesture { if let g = r.go { app.router.dismiss(); app.router.go(g) } }
                        }
                    }
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .padding(.bottom, 1)
                    .background(Color(hex: 0x0f1012))
                    .overlay(alignment: .bottom) { Rectangle().fill(AP.divider).frame(height: 1) }
                    .contentShape(Rectangle())
                    .onTapGesture { if let k = r.k { app.why[k] = !(app.why[k] ?? false) } }
                }
            }
            .padding(1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .outlined(AP.border, radius: 12)
            T(app.tr(blk > 0 ? "\(blk) to clear · proposals locked" : "Open proposal"), .sans, 15, 600)
                .apFont(.sans, 15, 600)
                .foregroundStyle(blk > 0 ? AP.faint : AP.ink)
                .lineLimit(1)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(blk > 0 ? AP.disabled : AP.text))
                .contentShape(Rectangle())
                .onTapGesture { if blk == 0 { app.router.dismiss(); app.router.go(.S15) } }
        }
        .padding(.horizontal, 18).padding(.top, 11).padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22).fill(AP.card)
        }
        .overlay {
            if !sheet {
                UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                    .stroke(AP.control, lineWidth: 1)
                    .mask(alignment: .top) { Rectangle().frame(height: 22) }
                    .padding(.horizontal, 0.5).padding(.top, 0.5).padding(.bottom, -1)
            }
        }
    }
}
