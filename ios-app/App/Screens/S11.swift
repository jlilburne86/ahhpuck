import SwiftUI

/// S11 · Recording (full-screen modal). No navigation; RPM 110, λ error 64, 10-cell coverage bar, 132 pt STOP.
/// The prototype times the run with its demo tick; here the clock runs on real time from the start.
struct S11View: View {
    @Environment(AppModel.self) private var app
    @State private var startedAt = Date()
    @State private var elapsed: Double = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.2)) { ctx in
            let secs = app.rec ? ctx.date.timeIntervalSince(startedAt) : elapsed
            content(secs: secs)
        }
    }

    @ViewBuilder private func content(secs: Double) -> some View {
        let b = app.base
        let clock = String(format: "%02d:%02d", Int(secs / 60), Int(secs) % 60)
        let filled = min(10, Int(secs / 2.5))
        let frames = BaseVals.grouped(Int((secs * 31).rounded()))
        PhoneScreen(tab: nil, scrolls: false) {
            if app.rec {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle().fill(AP.red).frame(width: 12, height: 12)
                            M("REC · CANDIDATE", .mono, 13)
                        }
                        Spacer()
                        M(clock, .mono, 22, translate: false)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        M("RPM", .mono, 10, color: AP.label)
                        M(b.rpm, .barlow, 110, 600, lineHeight: 0.9, translate: false)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        M(b.lamLabel + " ERROR", .mono, 10, color: AP.label)
                        M(b.lamErr, .barlow, 64, 600, color: b.lamColor, lineHeight: 0.9, translate: false)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            M("BAND COVERAGE 2.5–7k", .mono, 10, color: AP.label)
                            Spacer()
                            M("\(filled * 10)%", .mono, 12, translate: false)
                        }
                        HStack(spacing: 3) {
                            ForEach(0..<10, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 3).fill(i < filled ? AP.text : AP.disabled).frame(height: 26)
                            }
                        }
                        M(frames + " " + app.tr("FRAMES · DEMO DATA"), .mono, 11, color: AP.amber, translate: false)
                    }
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        T(app.tr("STOP"), .sans, 22, 700).apFont(.sans, 22, 700).apTracking(0.06, size: 22)
                            .frame(width: 132, height: 132)
                            .background(Circle().fill(Color.oklch(0.62, 0.20, 25)))
                            .contentShape(Circle())
                            .onTapGesture { elapsed = secs; app.recEl = Int(secs / 0.14); app.rec = false }
                            .accessibilityAddTraits(.isButton)
                        Spacer()
                    }
                    M("Screen locked against stray taps · alerts by sound + haptics", .sans, 11, color: AP.faint)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 16).padding(.horizontal, 22).padding(.bottom, 30)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    M("Run saved", .barlow, 40, 700)
                    M(clock + " · " + frames + " " + app.tr("frames · coverage") + " \(filled * 10)%", .mono, 13, color: AP.text3, translate: false)
                    M("sha 81d0…4b07", .mono, 12, color: AP.label, translate: false)
                    Spacer(minLength: 0)
                    VStack(spacing: 8) {
                        M("Go to review", .sans, 16, 600, color: AP.ink)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 14).fill(AP.text))
                            .contentShape(Rectangle())
                            .onTapGesture { app.router.dismiss(); app.router.select(.review); app.router.go(.S22) }
                        M("Record repeat", .sans, 16)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .outlined(AP.control, radius: 14)
                            .contentShape(Rectangle())
                            .onTapGesture { startedAt = .now; app.recStart = app.t; app.rec = true }
                    }
                }
                .padding(.vertical, 30).padding(.horizontal, 22)
            }
        }
        .onAppear { if app.rec { startedAt = .now } }
        .interactiveDismissDisabled()
    }
}
