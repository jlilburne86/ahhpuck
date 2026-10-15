import SwiftUI
import Observation

/// One shared state object, mirroring the prototype's single `Component` state so that every
/// screen reads the same demo data source (design: "All screens share one live demo data source").
/// Field names match the prototype's `state` keys so each screen's port reads like its source.
/// All numbers here are demo data from the prototype's formulas; real telemetry replaces them.
@MainActor
@Observable
final class AppModel {
    // MARK: settings (S32) — apply everywhere
    enum Units: String { case lambda = "Lambda", afr = "AFR" }
    var units: Units = .lambda
    var tuner = false
    var lang: L10n.Language = .en
    var isJA: Bool { lang == .ja }
    func tr(_ s: String) -> String { L10n.t(s, lang) }

    /// The prototype's `live` tweak (off by default): animates demo telemetry every 140 ms.
    var live = false { didSet { live ? startTicker() : stopTicker() } }

    // MARK: prototype state (same keys and initial values as the design's `state`)
    var t = 0
    var mode = "err"
    var cursor: Double = 62
    var dec = 0
    var ack = false
    var pStep = 3
    var prof: [String: String] = ["chassis": "AE86", "engine": "4A-GE 20V Blacktop", "ecu": "FC-03 Ab-1EU", "load": "Unknown", "inj": "Group", "ign": "Direct", "obj": "Drivability"]
    var cal = 1
    var conn = 5
    var pf: [String: Bool] = ["fuel": true, "tyres": false, "route": false, "observer": false]
    var rType = "Candidate"
    var rec = true
    var recStart = 0
    var recEl = 0
    var alertActive = true
    var alertAck = false
    var psel: [String: Bool] = ["1-5": true, "2-5": true]
    var opened: [String: Bool] = ["c1": true]
    var openC: String? = "c1"
    var appr: [Int: Bool] = [0: true, 1: true]
    var hold: Double = 0
    var signed = false
    var q = 0
    var filt = "All"
    var exported = false
    var rawSel = 9
    var nOpen = 0
    var invCause: String? = nil
    var invAct: [String: Bool] = [:]
    var invSigned = false
    var dFlow = 0
    var dDone = false
    var staleAt = 0
    var live2 = false
    var sens = 1
    var inc = 1
    var gMode = 0
    var gCur: Double = 78
    var pgSel = 4
    var ringT: Double = 0
    var wipe: Double = 4
    var wMode = 0
    var rad: [String: Bool] = ["b": true, "e": true, "a": true]
    var hiw = 0
    var perm: [String: Bool] = ["notif": true, "la": false, "loc": false, "mot": false]
    var hw = 0
    var err = 0
    var srcSel = 0
    var cm = 0
    var why: [String: Bool] = [:]
    var gq = ""
    var gOpen = 0
    var capP = 0
    var capT = 0

    // MARK: navigation
    let router = Router()

    // MARK: evidence workspace
    /// Local run records are loaded once at launch. The prototype ledger remains
    /// available when the device has no captured runs yet.
    let runStore = MobileRunStore()
    var persistedRuns: [MobileRunRecord] = []
    var runsLoaded = false
    var runImportError: String?

    var persistedComparison: MobileRunComparison? {
        guard let baseline = persistedRuns.first(where: { $0.kind == .baseline }),
              let candidate = persistedRuns.first(where: { $0.kind == .candidate }) else { return nil }
        let repeatRun = persistedRuns.first(where: { $0.kind == .repeatRun })
        return MobileRunComparison(baseline: baseline, candidate: candidate, repeatRun: repeatRun)
    }

    // MARK: ticker
    private var timer: Timer?
    private func startTicker() {
        stopTicker()
        timer = Timer.scheduledTimer(withTimeInterval: 0.14, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.t += 1
                if self.conn < 5 && self.t % 7 == 0 { self.conn += 1 }
            }
        }
    }
    private func stopTicker() { timer?.invalidate(); timer = nil }

    init() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-ja") { lang = .ja }
        if args.contains("-afr") { units = .afr }
        if args.contains("-tuner") { tuner = true }
        if args.contains("-live") { live = true; startTicker() }
        loadPersistedRuns()
    }

    private func loadPersistedRuns() {
        let store = runStore
        Task { [weak self] in
            let runs = (try? await store.loadAll()) ?? []
            guard let self else { return }
            self.persistedRuns = runs
            self.runsLoaded = true
        }
    }

    func importRun(from url: URL) async {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let run = try decoder.decode(MobileRunRecord.self, from: data)
            guard !run.frames.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
            _ = try await runStore.save(run)
            persistedRuns.removeAll { $0.id == run.id }
            persistedRuns.insert(run, at: 0)
            runsLoaded = true
            runImportError = nil
        } catch {
            runImportError = "IMPORT FAILED · (error.localizedDescription)"
        }
    }

    // MARK: shared demo values (port of the prototype's `baseVals()`)
    var base: BaseVals { BaseVals(model: self) }
}

/// Port of `baseVals()`. Strings are untranslated English; pass them through `app.tr` to display.
struct BaseVals {
    struct Gauge {
        let label: String, value: String, unit: String
        /// Band geometry in percent of the track (0–100), as in the prototype.
        let okL: Double, okW: Double, cL: Double, cW: Double, pos: Double
        let status: Status
        let tag: String
        var color: Color { [AP.text, AP.amber, AP.red][status.rawValue] }
        var state: String { ["✓ OK", "! CAUTION", "✕ STOP"][status.rawValue] }
        var stateColor: Color { status.color }
        var tagColor: Color { tag.contains("INFERRED") || tag.contains("UNVERIFIED") ? AP.text3 : AP.faint }
    }
    struct Cell { let bg: Color; let fg: Color; let label: String; let current: Bool; let hits: Int; let err: Double }
    struct Run { let name: String; let hash: String; let err: String; let color: Color }
    struct Decision { let label, kicker, title, body: String; let bg: Color; let inc, cta: String }
    struct Check { let label: String; let v: String; let status: Status }
    struct CursorVal { let k: String; let v: String; let color: Color }

    let afr: Bool
    let clock: String
    let rpmValue: Int
    let rpm: String
    let load: String
    let rpmPct: Double          // 0–100
    let lamLabel: String        // "LAMBDA" | "AFR"
    let lamVal: String
    let lamTarget: String
    let lamErr: String
    let lamColor: Color
    /// Sparkline points in the prototype's 322×44 viewBox.
    let lamSpark: [CGPoint]
    let gauges: [Gauge]
    let frames: String
    /// 10 rows (load 100 → 10) × 12 columns (rpm 800 → 7600), row-major.
    let cells: [Cell]
    let rpmAxis: [String]
    let loadAxis: [Int]
    let legendL: String, legendR: String
    let cellName: String
    let cellHits: Int
    let runs: [Run]
    /// Run overlay series in a 332×170 viewBox (pRpm/pIgn in 332×56).
    let pTarget: [CGPoint], pBase: [CGPoint], pCand: [CGPoint], pRep: [CGPoint], pRpm: [CGPoint], pIgn: [CGPoint]
    let cursor: Double
    let cursorX: Double
    let cursorRpm: String
    let cursorVals: [CursorVal]
    let decisions: [Decision]
    let dec: Decision
    let checks: [Check]

    /// `fmt` in the prototype: λ to 3 dp, or AFR to 1 dp.
    static func fmt(_ v: Double, afr: Bool) -> String { afr ? String(format: "%.1f", v * 14.7) : String(format: "%.3f", v) }

    /// `toLocaleString('en-AU')` for integers.
    static func grouped(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.locale = Locale(identifier: "en_AU")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }

    @MainActor init(model s: AppModel) {
        let t = Double(s.t)
        let afr = s.units == .afr
        self.afr = afr
        let rpm = Int((3820 + sin(t / 9) * 1100 + sin(t / 3.1) * 120).rounded())
        let load = max(8, min(98, 54 + sin(t / 9 + 0.6) * 26))
        let target = load > 65 ? 0.88 : 0.92
        let lam = target + 0.022 + sin(t / 5) * 0.02
        let errPct = (lam - target) / target * 100
        let fmt = { (v: Double) in BaseVals.fmt(v, afr: afr) }

        lamSpark = (0..<60).map { i in
            let tt = t - 59 + Double(i)
            let e = 0.022 + sin(tt / 5) * 0.02
            return CGPoint(x: (Double(i) * 322 / 59 * 10).rounded() / 10, y: ((22 - e * 500) * 10).rounded() / 10)
        }

        func g(_ label: String, _ v: Double, _ unit: String, _ min: Double, _ max: Double, _ okA: Double, _ okB: Double, _ cA: Double, _ cB: Double, _ tag: String) -> Gauge {
            let p = { (x: Double) in Swift.max(0, Swift.min(100, (x - min) / (max - min) * 100)) }
            let st: Status = v >= okA && v <= okB ? .ok : v >= cA && v <= cB ? .caution : .stop
            return Gauge(label: label, value: String(format: unit == "°C" || unit == "°" ? "%.0f" : "%.1f", v), unit: unit,
                         okL: p(okA), okW: p(okB) - p(okA), cL: p(cA), cW: p(cB) - p(cA), pos: p(v), status: st, tag: tag)
        }
        gauges = [
            g("COOLANT", 96 + sin(t / 14) * 6, "°C", 40, 120, 75, 100, 65, 105, "ECU · INFERRED"),
            g("INTAKE", 38 + sin(t / 30), "°C", 0, 80, 0, 50, 0, 55, "ECU · INFERRED"),
            g("OIL PRESS", 3.8 + sin(t / 9) * 0.6, "bar", 0, 7, 1.5, 6, 1.0, 6.5, "EXT · OBSERVED"),
            g("FUEL PRESS", 3.0, "bar", 0, 5, 2.7, 3.3, 2.5, 3.5, "EXT · OBSERVED"),
            g("BATTERY", 13.8 + sin(t / 13) * 0.1, "V", 10, 16, 12.5, 14.8, 12.0, 15.2, "ECU · OBSERVED"),
            g("IGNITION", 24 + sin(t / 9) * 6, "°", 0, 45, 0, 40, 0, 42, "ECU · UNVERIFIED"),
        ]

        // map
        let rpmBins: [Double] = [800, 1200, 1600, 2000, 2500, 3000, 3500, 4000, 5000, 6000, 7000, 7600]
        let loadBins = [100, 90, 80, 70, 60, 50, 40, 30, 20, 10]
        var ci = 0, ri = 0
        for (i, v) in rpmBins.enumerated() where abs(v - Double(rpm)) < abs(rpmBins[ci] - Double(rpm)) { ci = i }
        for (i, v) in loadBins.enumerated() where abs(Double(v) - load) < abs(Double(loadBins[ri]) - load) { ri = i }
        var cells: [Cell] = []
        var curHits = 0
        for r in 0..<10 {
            for c in 0..<12 {
                let d = abs(Double(c) / 11 - (1 - Double(r) / 9) * 0.85 - 0.05)
                let h = (sin(Double(c) * 12.9 + Double(r) * 78.2) * 43758.5).truncatingRemainder(dividingBy: 1)
                let hits = d < 0.28 ? Int((60 * (1 - d / 0.28) * (0.45 + 0.55 * abs(h))).rounded()) : 0
                let e = sin(Double(c) * 1.3 + Double(r) * 0.7) * 3.2 + (c > 6 && r < 4 ? 3 : 0)
                let cur = r == ri && c == ci
                if cur { curHits = hits }
                var bg: Color, fg = AP.text, label: String
                if hits == 0 {
                    bg = AP.mapNoData; fg = AP.hatchA; label = "·"
                } else if s.mode == "err" {
                    let m = abs(e)
                    if m <= 1.5 { bg = AP.mapOnTarget }
                    else if e < 0 { let a = min(1, (m - 1.5) / 4.5); bg = .oklch(0.40 + a * 0.18, 0.07 + a * 0.10, 245) }
                    else if e <= 3.5 { bg = AP.mapLean; fg = AP.ink }
                    else { bg = AP.mapVeryLean }
                    label = (e > 0 ? "+" : "") + String(format: "%.1f", e)
                } else {
                    let a = min(1, Double(hits) / 50)
                    bg = .oklch(0.24 + a * 0.62, 0.01, 250); fg = a > 0.5 ? AP.ink : AP.text; label = String(hits)
                }
                cells.append(Cell(bg: bg, fg: fg, label: label, current: cur, hits: hits, err: e))
            }
        }
        self.cells = cells
        rpmAxis = rpmBins.map { v in v < 1000 ? ".8" : String(format: v.truncatingRemainder(dividingBy: 1000) != 0 ? "%.1f" : "%.0f", v / 1000) }
        loadAxis = loadBins
        legendL = s.mode == "err" ? "RICH" : "0"
        legendR = s.mode == "err" ? "LEAN" : "50+ HITS"
        cellName = "\(String(format: "%.1f", rpmBins[ci] / 1000))k / \(loadBins[ri])%"
        cellHits = curHits

        // runs
        let N = 110
        func ser(_ h: Double, _ fn: (Double) -> Double) -> [CGPoint] {
            (0..<N).map { i in
                let x = Double(i) / Double(N - 1)
                let y = max(2, min(h - 2, fn(x)))
                return CGPoint(x: (Double(i) * 332 / Double(N - 1) * 10).rounded() / 10, y: (y * 10).rounded() / 10)
            }
        }
        let ly = { (l: Double) in 170 - (l - 0.80) / 0.20 * 170 }
        let tgt = { (x: Double) in x < 0.45 ? 0.92 : 0.88 }
        let base = { (x: Double) in tgt(x) + 0.045 * sin(x * 7) + (x > 0.7 ? 0.04 : 0.01) }
        let cand = { (x: Double) in tgt(x) + 0.018 * sin(x * 9 + 1) + 0.006 }
        let rep = { (x: Double) in tgt(x) + 0.02 * sin(x * 9 + 1.4) + 0.008 }
        let cx = s.cursor / 100
        runs = [
            Run(name: "Baseline", hash: "sha 3f9a…c21e", err: afr ? "±0.71 AFR" : "4.8 %", color: AP.baseline),
            Run(name: "Candidate", hash: "sha 81d0…4b07", err: afr ? "±0.31 AFR" : "2.1 %", color: AP.candidate),
            Run(name: "Repeat", hash: "sha a6e2…90f3", err: afr ? "±0.34 AFR" : "2.3 %", color: AP.repeatTrace),
        ]
        pTarget = ser(170) { ly(tgt($0)) }
        pBase = ser(170) { ly(base($0)) }
        pCand = ser(170) { ly(cand($0)) }
        pRep = ser(170) { ly(rep($0)) }
        pRpm = ser(56) { 52 - $0 * 46 }
        pIgn = ser(56) { 46 - sin($0 * 3) * 22 - $0 * 8 }
        cursor = s.cursor
        cursorX = (cx * 332 * 10).rounded() / 10
        cursorRpm = BaseVals.grouped(Int((2500 + cx * 4500).rounded()))
        cursorVals = [
            CursorVal(k: "BASE", v: fmt(base(cx)), color: AP.text3),
            CursorVal(k: "CAND", v: fmt(cand(cx)), color: AP.candidate),
            CursorVal(k: "TARGET", v: fmt(tgt(cx)), color: AP.cyan),
        ]

        let decs = [
            Decision(label: "Accept", kicker: "RECOMMENDED · EVIDENCE COMPLETE", title: "Accept, prepare a smaller step", body: "Candidate cut lambda error 56% and the repeat landed within tolerance. Keep it as the working reference.", bg: AP.green, inc: "Fuel ±1.5 %", cta: "Record acceptance"),
            Decision(label: "Repeat", kicker: "NOT PROVEN", title: "Repeat the experiment", body: "Same calibration, same gear and RPM band. No new change until repeatability is shown.", bg: AP.amber, inc: "None", cta: "Start repeat run"),
            Decision(label: "Rollback", kicker: "REGRESSION", title: "Rollback and investigate", body: "Return to the last accepted state and preserve evidence before another experiment.", bg: AP.rollback, inc: "None", cta: "Open rollback plan"),
            Decision(label: "Abort", kicker: "CRITICAL · CANNOT OVERRIDE", title: "Stop and abort", body: "Knock, lean-under-load, or telemetry loss detected. Tuning is locked until a human investigation is recorded.", bg: AP.red, inc: "Locked", cta: "Log investigation"),
        ]
        decisions = decs
        let di = s.dec
        dec = decs[di]
        checks = [
            Check(label: "Lambda error vs baseline", v: "4.8 → 2.1 %", status: .ok),
            Check(label: "Repeatability", v: "Δ 0.2 %", status: di == 1 ? .caution : .ok),
            Check(label: "Telemetry completeness", v: "99.2 %", status: .ok),
            Check(label: "Cell coverage", v: "38 / 120", status: .caution),
            Check(label: "Knock events", v: di == 3 ? "2" : "0", status: di == 3 ? .stop : .ok),
            Check(label: "Sensor plausibility", v: di == 2 ? "IAT drift" : "Pass", status: di == 2 ? .caution : .ok),
        ]

        let secs = Int(t * 0.14)
        clock = String(format: "00:%02d:%02d", secs / 60, secs % 60)
        rpmValue = rpm
        self.rpm = BaseVals.grouped(rpm)
        self.load = String(format: "%.0f", load)
        rpmPct = (Double(rpm) / 8000 * 1000).rounded() / 10
        lamLabel = afr ? "AFR" : "LAMBDA"
        lamVal = fmt(lam)
        lamTarget = fmt(target)
        lamErr = (errPct > 0 ? "+" : "") + String(format: "%.1f", errPct) + "%"
        lamColor = abs(errPct) > 3.5 ? AP.red : abs(errPct) > 2 ? AP.amber : AP.green
        frames = BaseVals.grouped(18420 + s.t * 3)
    }
}
