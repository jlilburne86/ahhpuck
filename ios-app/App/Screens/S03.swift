import SwiftUI

/// S03 · Phone mount calibration
struct S03View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let s = app.cal, t = Double(app.t)
        let amp = [18.0, 3, 10, 7, 1][s]
        let bubL = 70 + sin(t / 3) * amp, bubT = 70 + cos(t / 4) * amp
        let pitch = jsFixed(sin(t / 3) * amp / 6, 1) + "°", roll = jsFixed(cos(t / 4) * amp / 6, 1) + "°"
        let q = ["None", "Low", "Low", "Medium", "High"][s]
        let qc = [AP.red, AP.amber, AP.amber, AP.amber, AP.green][s]
        let phases = ["Mount the phone in the cradle", "Hold still for 5 seconds", "Drive straight at a steady 40 km/h", "Brake gently to a stop", "Calibrated"]

        PhoneScreen(tab: .garage) {
            AHeader(title: "Phone mount", sub: app.tr("CORE MOTION · GPS"))

            HStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    Circle().fill(Color(hex: 0x101214))
                    Circle().strokeBorder(AP.control, lineWidth: 1)
                    Rectangle().fill(AP.disabled).frame(width: 1, height: 140).offset(x: 80, y: 11)
                    Rectangle().fill(AP.disabled).frame(width: 140, height: 1).offset(x: 11, y: 80)
                    Circle().strokeBorder(Color(hex: 0x4a4f54), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .frame(width: 38, height: 38).offset(x: 63, y: 63)
                    Circle().fill(AP.text).frame(width: 20, height: 20).offset(x: bubL + 1, y: bubT + 1)
                }
                .frame(width: 162, height: 162)
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 0) {
                        M("QUALITY", .mono, 10, color: AP.label)
                        M(q, .barlow, 28, 600, color: qc)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        M("PITCH / ROLL", .mono, 10, color: AP.label)
                        M(pitch + " / " + roll, .mono, 14, translate: false)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        M("GPS ACCURACY", .mono, 10, color: AP.label)
                        M("2.4 m", .mono, 14, translate: false)
                    }
                }
            }
            .apCard()
            .block()

            VStack(spacing: 2) {
                ForEach(Array(phases.enumerated()), id: \.offset) { i, p in
                    MDotRow(label: p,
                            dot: i < s ? AP.green : i == s ? AP.text : AP.disabled,
                            fg: i <= s ? AP.text : AP.faint,
                            state: i < s ? "DONE" : i == s ? "NOW" : "")
                }
            }
            .block()

            M("Below \"High\", any g-force data from this phone is marked low-confidence wherever it appears.", .sans, 13, color: AP.text3, lineHeight: 1.45)
                .block(top: 6)

            Spacer(minLength: 16)
            MButton(label: s < 4 ? "Next step" : "Recalibrate") { app.cal = (app.cal + 1) % 5 }
        }
    }
}
