import SwiftUI

/// S07 · Live · stale / lost telemetry. Under 1 s live · 1–3 s greyed with age · over 3 s hidden,
/// last value kept, run paused. The prototype ages data with its demo tick; here the age runs on
/// real time from the simulated drop so the states actually progress.
struct S07View: View {
    @Environment(AppModel.self) private var app
    @State private var droppedAt: Date?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { ctx in
            content(age: app.live2 ? 0 : droppedAt.map { ctx.date.timeIntervalSince($0) } ?? 0)
        }
    }

    @ViewBuilder private func content(age: Double) -> some View {
        let b = app.base
        let ph = app.live2 || age < 1 ? 0 : age < 3 ? 1 : 2
        let bg = [AP.card, AP.amber, AP.red][ph], fg = [AP.text, AP.ink, Color.white][ph]
        let title = ["✓ Live · 31 Hz", "! Data stale", "✕ Telemetry lost · run paused"][ph]
        let ageS = ph > 0 ? jsFixed(age, 1) + " s" : "< 0.1 s"
        let sub = ["Every value is under 1 s old.", "Values are greyed. Assessment ignores samples older than 1 s.", "Values are hidden after 3 s. The gap is marked in the run, and a critical alert fires if you were recording."][ph]
        let valC = [AP.text, AP.label, Color(hex: 0x4a4f54)][ph]
        let snap = (rpm: "4,210", lam: b.lamLabel == "AFR" ? "13.3" : "0.902", cool: "97", oil: "3.9")
        let cv = ph == 0 ? (rpm: b.rpm, lam: b.lamVal, cool: b.gauges[0].value, oil: b.gauges[2].value) : snap
        let rpmSub = ph == 2 ? "LAST \(snap.rpm) · \(jsFixed(age, 1)) S AGO" : ph == 1 ? "\(jsFixed(age, 1)) S OLD" : "LIVE"
        let tiles: [(String, String, String)] = [(b.lamLabel, cv.lam, ""), ("COOLANT", cv.cool, "°C"), ("OIL PRESS", cv.oil, "bar"), ("FRAMES", ph > 0 ? "stopped" : b.frames, "")]

        PhoneScreen(tab: .live) {
            AHeader(title: "Live", sub: app.tr("BASELINE · RUN 03"))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    M(title, .sans, 15, 600)
                    Spacer()
                    M(ageS, .mono, 13)
                }
                M(sub, .sans, 12, lineHeight: 1.4)
            }
            .foregroundStyle(fg)
            .apCard(fill: bg, stroke: AP.control)
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                M("RPM", .mono, 10, color: AP.label)
                M(ph == 2 ? "—" : cv.rpm, .barlow, 72, 600, color: valC, lineHeight: 0.9, translate: false)
                M(rpmSub, .mono, 10, color: AP.label)
            }
            .apCard()
            .block()

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(tiles, id: \.0) { k, val, u in
                    VStack(alignment: .leading, spacing: 4) {
                        M(k, .mono, 10, color: AP.label)
                        (T(ph == 2 ? "—" : app.tr(val), .barlow, 26, 600).foregroundColor(valC)
                         + T(" " + (ph == 2 ? "" : u), .barlow, 14, 600).foregroundColor(AP.faint))
                            .apFont(.barlow, 26, 600, lineHeight: 1)
                            .lineLimit(1)
                        M(ph == 2 ? "LAST " + val + (u.isEmpty ? "" : " " + u) : ph == 1 ? "\(jsFixed(age, 1)) S OLD" : "LIVE", .mono, 9, color: AP.faint)
                    }
                    .apCard(vertical: 10, horizontal: 12)
                }
            }
            .block()

            VStack(alignment: .leading, spacing: 8) {
                M("RULES", .mono, 10, color: AP.label)
                M("Under 1 s: live · 1–3 s: greyed with age · over 3 s: hidden, last value kept, run paused. Never shows a frozen value as if it were current.", .sans, 12, color: AP.text3, lineHeight: 1.55)
            }
            .apCard()
            .block()

            Spacer(minLength: 16)
            Group {
                if Features.prototypeControls {
                    MButton(label: app.live2 ? "Simulate: drop connection" : "Reconnect", bg: .clear, fg: AP.text, border: AP.control, bottom: 14) {
                        if app.live2 {
                            app.live2 = false; app.staleAt = app.t; droppedAt = .now
                        } else {
                            app.live2 = true; droppedAt = nil
                        }
                    }
                }
            }
            .onChange(of: ph) { _, new in
                // Losing telemetry while recording raises the critical alert (README · S07).
                if new == 2 && app.rec { app.alertActive = true }
            }
        }
    }
}
