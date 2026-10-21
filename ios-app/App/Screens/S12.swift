import SwiftUI

/// S12 · Critical alert (full-screen modal). Can't be acknowledged while the condition is active;
/// after acknowledging, tuning stays locked until the investigation (S13) is signed.
struct S12View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let b = app.base, t = Double(app.t), afr = app.units == .afr
        let fl = { (x: Double) in afr ? jsFixed(x * 14.7, 1) : jsFixed(x, 2) }
        let active = app.alertActive, acked = app.alertAck
        let deep = Color(hex: 0x7a1414)

        PhoneScreen(tab: nil, background: .oklch(0.45, 0.17, 25), foreground: .white, scrolls: false) {
            VStack(alignment: .leading, spacing: 16) {
                M("CRITICAL · SAFETY GATE", .mono, 12).apTracking(0.1, size: 12)
                M("STOP\nTHE RUN", .barlow, 64, 700, lineHeight: 0.9)
                M("Lean under load", .sans, 18, 600)
                HStack(spacing: 8) {
                    tile(b.lamLabel, fl(1.08 + sin(t / 2) * 0.01), app.tr("LIMIT") + " " + fl(0.95))
                    tile("LOAD", "82%", nil)
                    tile("RPM", "5,900", nil)
                }
                M(active ? "CONDITION ACTIVE" : "CONDITION CLEARED", .mono, 12, 600, color: active ? deep : .white)
                    .padding(.vertical, 7).padding(.horizontal, 11)
                    .background(RoundedRectangle(cornerRadius: 6).fill(active ? Color.white : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white, lineWidth: 1))
                M("Back off the throttle and bring the engine to idle. This alert comes from fixed rules and works even if the analyst is off.", .sans, 14, lineHeight: 1.5)
                Spacer(minLength: 0)
                M(acked ? "Acknowledged · tuning locked until investigated" : active ? "Can't acknowledge while active" : "Acknowledge",
                  .sans, 16, 600, color: acked ? .white : active ? Color.white.opacity(0.65) : deep)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 14).fill(acked ? .clear : active ? Color.black.opacity(0.25) : .white))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if acked { app.router.dismiss(); app.router.go(.S13) }      // next step: log the investigation
                        else if !active { app.alertAck = true }
                    }
                if Features.prototypeControls {
                    M(active ? "Simulate: condition clears" : "Simulate: condition returns", .sans, 12)
                        .underline().opacity(0.8)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { app.alertActive.toggle(); app.alertAck = false }
                }
            }
            .padding(.top, 20).padding(.horizontal, 22).padding(.bottom, 30)
        }
        .interactiveDismissDisabled()
        .sensoryFeedback(.error, trigger: active)
    }

    private func tile(_ k: String, _ v: String, _ sub: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            M(k, .mono, 10)
            M(v, .barlow, 30, 600, translate: false)
            if let sub { M(sub, .mono, 10, translate: false) }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.22)))
    }
}
