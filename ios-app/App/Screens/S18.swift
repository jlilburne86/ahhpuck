import SwiftUI

/// S18 · Supervised approval (full-screen modal) — six confirmations, then press-and-hold to sign:
/// the fill grows 6 % every 40 ms while held, releasing early resets it, and at 100 % the record
/// is signed (fill turns green). Port of `appr`, `holdDown`, `holdUp`, `resetAppr`.
struct S18View: View {
    @Environment(AppModel.self) private var app
    @State private var timer: Timer?
    @State private var showWhy = false

    static let items = ["Vehicle and ECU profile are correct", "Baseline backup and rollback path verified", "Change and expected effect understood", "All displayed warnings reviewed", "Supervised test conditions in place", "Stop criteria agreed with observer"]

    var body: some View {
        let na = (0..<6).filter { app.appr[$0] ?? false }.count
        let all = na == 6
        let label = app.signed ? "Signed · record EXP-04-A1" : all ? "Press and hold to sign" : "\(6 - na) confirmations left"
        let fg: Color = app.signed || app.hold > 50 ? AP.ink : all ? AP.text : AP.faint
        PhoneScreen(tab: nil, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: "Approve test", subtitle: "EXP-04 · CREATES A RECORD · NO ECU WRITE")

            VStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { i in
                    let on = app.appr[i] ?? false
                    HStack(spacing: 12) {
                        T(on ? "✓" : "", .sans, 14, 700).apFont(.sans, 14, 700).foregroundStyle(AP.ink)
                            .frame(width: 25, height: 25)
                            .background(RoundedRectangle(cornerRadius: 6).fill(on ? AP.text : .clear))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(hex: 0x4a4f54), lineWidth: 1.5))
                        T(app.tr(S18View.items[i]), .sans, 13).apFont(.sans, 13, lineHeight: 1.35)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 11).padding(.horizontal, 12)
                    .padding(.bottom, 1)
                    .overlay(alignment: .bottom) { Rectangle().fill(AP.divider).frame(height: 1) }
                    .contentShape(Rectangle())
                    .onTapGesture { if !app.signed { app.appr[i] = !on } }
                }
            }
            .padding(1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .outlined(AP.border, radius: 12)
            .block(top: 10)

            T(app.tr("Signing records who approved what and when. In this release the change itself is made by hand, outside AhhPuck."), .sans, 13)
                .apFont(.sans, 13, lineHeight: 1.45).foregroundStyle(AP.text3)
                .fixedSize(horizontal: false, vertical: true)
                .block(top: 12)

            Spacer(minLength: 0)

            // press-and-hold to sign
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(AP.raised)
                    Rectangle().fill(app.signed ? AP.green : AP.text).frame(width: geo.size.width * app.hold / 100)
                    T(app.tr(label), .sans, 15, 600).apFont(.sans, 15, 600).foregroundStyle(fg).lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if timer == nil { holdDown(all: all) } }
                .onEnded { _ in holdUp(all: all) })
            .padding(.horizontal, 18).padding(.bottom, 10)

            T(app.tr("Reset"), .sans, 12).apFont(.sans, 12).foregroundStyle(AP.label).underline()
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { app.appr = [:]; app.hold = 0; app.signed = false }
                .padding(.horizontal, 18).padding(.bottom, 22)
        }
        .sheet(isPresented: $showWhy) {
            S41View().environment(app)
                .presentationCornerRadius(22)
                .presentationBackground(AP.card)
        }
        .onDisappear { timer?.invalidate(); timer = nil }
    }

    private func holdDown(all: Bool) {
        wasSigned = app.signed
        guard all, !app.signed else { timer = Timer(timeInterval: 1e9, repeats: false) { _ in }; return }
        let t = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { t in
            MainActor.assumeIsolated {
                if app.hold >= 100 { t.invalidate(); app.signed = true } else { app.hold = min(100, app.hold + 6) }
            }
        }
        timer = t
    }

    private func holdUp(all: Bool) {
        timer?.invalidate(); timer = nil
        if app.signed {
            // Tapping the signed bar continues the core loop: S18 → S11 candidate run.
            if wasSigned { app.router.dismiss(); app.router.go(.S11) }
            return
        }
        app.hold = 0
        if !all { showWhy = true }
    }

    @State private var wasSigned = false
}
