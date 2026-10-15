import SwiftUI

/// S06 · Live dashboard
struct S06View: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        // Live tab root: coach marks on the first visit (S40), phone-only mode with no ECU (S39).
        if app.router.coachMarksPending && !UserDefaults.standard.bool(forKey: "coachMarksDone") {
            S40View(onFinish: {
                UserDefaults.standard.set(true, forKey: "coachMarksDone")
                app.router.coachMarksPending = false
            })
        } else if app.conn < 5 {
            S39View()
        } else {
            dashboard
        }
    }

    private var dashboard: some View {
        let b = app.base
        return PhoneScreen(tab: .live) {
            ScreenHeader(title: "Live", subtitle: "BASELINE · RUN 03 · " + b.clock) {
                HStack(spacing: 6) { ReadOnlyPill(); DemoDataPill() }
            }

            // RPM hero with the 7k limit bar
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        T(app.tr("RPM"), .mono, 11, 400).apFont(.mono, 11).foregroundStyle(AP.label)
                        Text(b.rpm).apFont(.barlow, 72, 600, lineHeight: 0.9, tabular: true)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        T(app.tr("LOAD (TPS)"), .mono, 11, 400).apFont(.mono, 11).foregroundStyle(AP.label)
                        (Text(b.load) + Text("%").font(APFont.font(.barlow, 18, 600)).foregroundColor(AP.label))
                            .apFont(.barlow, 36, 600, lineHeight: 1)
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(AP.track)
                        Rectangle().fill(AP.text).frame(width: geo.size.width * b.rpmPct / 100)
                        Hatch(a: AP.red, b: .clear, stripe: 3)
                            .opacity(0.7)
                            .frame(width: geo.size.width * 0.125)
                            .offset(x: geo.size.width * 0.875)
                    }
                }
                .frame(height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                HStack {
                    ForEach(["0", "2k", "4k", "6k", "7k LIMIT"], id: \.self) { s in
                        if s != "0" { Spacer() }
                        Text(app.tr(s))
                    }
                }
                .apFont(.mono, 10).foregroundStyle(AP.faint)
            }
            .apCard(vertical: 14, horizontal: 16, radius: 14)
            .block(top: 14)

            // Lambda actual vs target
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(app.tr(b.lamLabel) + app.tr(" · ACTUAL vs TARGET")).apFont(.mono, 11).foregroundStyle(AP.label)
                    Spacer()
                    Tag(text: "ECU O₂ · INFERRED")
                }
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(b.lamVal).apFont(.barlow, 48, 600, lineHeight: 1).foregroundStyle(b.lamColor)
                    Text("→ " + b.lamTarget).apFont(.mono, 14).foregroundStyle(AP.cyan)
                    Spacer(minLength: 0)
                    Text(b.lamErr).apFont(.mono, 14).foregroundStyle(b.lamColor)
                }
                Canvas { ctx, size in
                    let scale = size.width / 322
                    var target = Path()
                    target.move(to: CGPoint(x: 0, y: 22)); target.addLine(to: CGPoint(x: size.width, y: 22))
                    ctx.stroke(target, with: .color(AP.cyan), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    var spark = Path()
                    for (i, point) in b.lamSpark.enumerated() {
                        let scaled = CGPoint(x: point.x * scale, y: point.y)
                        if i == 0 { spark.move(to: scaled) } else { spark.addLine(to: scaled) }
                    }
                    ctx.stroke(spark, with: .color(AP.text), lineWidth: 1.6)
                }
                .frame(maxWidth: .infinity).frame(height: 44)
            }
            .apCard(vertical: 14, horizontal: 16, radius: 14)
            .block()

            // Gauge tiles
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(b.gauges, id: \.label) { g in
                    GaugeTile(g: g).contentShape(Rectangle()).onTapGesture { app.router.go(.S08) }
                }
            }
            .block()

            // Telemetry health strip
            HStack {
                Text(app.tr("FRAMES") + " " + b.frames)
                Spacer(minLength: 0)
                Text(app.tr("DROP 0.4%"))
                Spacer(minLength: 0)
                T(app.tr("KNOCK —"), .mono, 11)
                Spacer(minLength: 0)
                T(app.tr("DEMO DATA · DECODER LOCKED"), .mono, 11).foregroundStyle(AP.amber)
            }
            .apFont(.mono, 11)
            .foregroundStyle(AP.text3)
            .lineLimit(1)
            .padding(.vertical, 11).padding(.horizontal, 13)
            .outlined(AP.border, radius: 12)
            .block()
            .onTapGesture { app.router.go(.S07) }

            Spacer(minLength: 0)
        }
    }
}

/// Gauge tile with a three-band bar (stop / caution / ok) and the white "now" marker.
struct GaugeTile: View {
    @Environment(AppModel.self) private var app
    let g: BaseVals.Gauge

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                T(app.tr(g.label), .mono, 10, 400).apFont(.mono, 10).foregroundStyle(AP.label)
                Spacer(minLength: 2)
                T(app.tr(g.tag), .mono, 9, 400).apFont(.mono, 9).foregroundStyle(g.tagColor).lineLimit(1)
            }
            HStack(alignment: .lastTextBaseline) {
                (Text(g.value).foregroundColor(g.color)
                 + Text(" " + g.unit).font(APFont.font(.barlow, 14, 600)).foregroundColor(AP.label))
                    .apFont(.barlow, 26, 600, lineHeight: 1)
                    .lineLimit(1)
                    .fixedSize()
                Spacer(minLength: 0)
                T(app.tr(g.state), .mono, 9, 600).apFont(.mono, 9, 600).foregroundStyle(g.stateColor).lineLimit(1)
            }
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 3).fill(AP.bandStop).frame(height: 5)
                    Rectangle().fill(AP.bandCaution).frame(width: w * g.cW / 100, height: 5).offset(x: w * g.cL / 100)
                    Rectangle().fill(AP.bandOk).frame(width: w * g.okW / 100, height: 5).offset(x: w * g.okL / 100)
                    // marker: left:pos; top:-3px; width:3px; height:11px; margin-left:-1px
                    RoundedRectangle(cornerRadius: 1).fill(Color.white)
                        .frame(width: 3, height: 11)
                        .offset(x: w * g.pos / 100 - 1, y: -3)
                }
            }
            .frame(height: 5)
        }
        .apCard(vertical: 10, horizontal: 12, radius: 12)
    }
}
