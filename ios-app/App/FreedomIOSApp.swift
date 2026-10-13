import SwiftUI
#if canImport(FreedomMobileCore)
import FreedomMobileCore
#endif

@main
struct FreedomIOSApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("-engineer") {
            UserDefaults.standard.set(LiveDisplayMode.engineer.rawValue, forKey: "liveDisplayMode")
        }
        if ProcessInfo.processInfo.arguments.contains("-glance") {
            UserDefaults.standard.set(LiveDisplayMode.glance.rawValue, forKey: "liveDisplayMode")
        }
        if ProcessInfo.processInfo.arguments.contains("-japanese") {
            UserDefaults.standard.set("ja", forKey: "appLanguage")
        }
    }

    var body: some Scene { WindowGroup { FreedomRootView() } }
}

struct FreedomRootView: View {
    @State private var selection: AppTab
    @State private var trial: MobileTrialSession
    @State private var approvalChecks = Array(repeating: false, count: 4)
    @State private var toast: String?
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage
    private var locale: Locale { Locale(identifier: appLanguage) }

    init() {
        _selection = State(initialValue: ProcessInfo.processInfo.arguments.contains("-review") ? .review : .live)
        _trial = State(initialValue: ProcessInfo.processInfo.arguments.contains("-loadFixture") ? .demo() : MobileTrialSession())
    }

    var body: some View {
        TabView(selection: $selection) {
            LiveView(trial: $trial).tabItem { Label(appText("Live", locale: locale), systemImage: "waveform.path.ecg") }.tag(AppTab.live)
            CaptureView(trial: $trial, toast: $toast).tabItem { Label(appText("Run", locale: locale), systemImage: "record.circle") }.tag(AppTab.run)
            ReviewView(trial: $trial, approvalChecks: $approvalChecks, toast: $toast).tabItem { Label(appText("Review", locale: locale), systemImage: "checkmark.seal") }.tag(AppTab.review)
            SetupView().tabItem { Label(appText("Setup", locale: locale), systemImage: "gearshape") }.tag(AppTab.setup)
        }
        .id(appLanguage)
        .tint(.orange)
        .environment(\.locale, Locale(identifier: appLanguage))
        .overlay(alignment: .top) { if let toast { Text(toast).font(.footnote.weight(.semibold)).padding(.horizontal, 14).padding(.vertical, 10).background(.thinMaterial, in: Capsule()).padding(.top, 8) } }
    }
}

private enum AppTab { case live, run, review, setup }

private func appText(_ value: String, locale: Locale) -> String {
    guard locale.language.languageCode?.identifier == "ja" else { return value }
    switch value {
    case "Freedom Monitor": return "Freedom モニター"
    case "Live": return "ライブ"
    case "Run": return "走行"
    case "Review": return "レビュー"
    case "Setup": return "設定"
    case "READ-ONLY": return "読み取り専用"
    case "Load first-trial fixture": return "初回トライアルデータを読み込む"
    case "Lambda trace · baseline": return "ラムダ波形 · ベースライン"
    case "Load the first-trial fixture or capture a verified run to view the trace.": return "初回トライアルデータを読み込むか、検証済み走行を取得すると波形を表示します。"
    case "Protection": return "保護"
    case "Engine health": return "エンジン状態"
    case "Phone dynamics": return "車両コンテキスト"
    case "Telemetry healthy": return "テレメトリ正常"
    case "Lambda": return "ラムダ"
    case "Target 0.90": return "目標 0.90"
    case "View": return "表示"
    case "Glance": return "概要"
    case "Engineer": return "エンジニア"
    case "Baseline · candidate · repeat": return "ベースライン · 候補 · 再試行"
    case "RPM × load coverage": return "回転数 × 負荷のカバレッジ"
    case "NO DATA": return "データなし"
    case "LOCAL REPLAY · NO ECU": return "ローカルリプレイ · ECUなし"
    case "READ-ONLY ECU": return "読み取り専用 ECU"
    case "PAUSED": return "一時停止"
    case "STOP": return "停止"
    case "Evidence": return "証拠"
    case "Interpretation": return "解釈"
    case "Proposal": return "提案"
    case "No operating cells observed": return "運転セルが観測されていません"
    case "Cells are observed replay coverage, not a tune-quality score.": return "セルはリプレイの観測範囲であり、チューン品質スコアではありません。"
    case "Phone sensors provide context. They do not replace oil pressure, fuel pressure, lambda, or knock instrumentation.": return "スマートフォンのセンサーはコンテキストを提供します。油圧・燃圧・ラムダ・ノック計測の代わりにはなりません。"
    case "No automatic concerns": return "自動的な懸念事項なし"
    case "Review the affected RPM/load cells and repeat the same test before accepting the smaller step.": return "影響を受けた回転数・負荷セルを確認し、小さな変更を承認する前に同じテストを再試行してください。"
    case "The current evidence does not permit an incremental calibration proposal.": return "現在の証拠では段階的な調整提案を出せません。"
    case "Approval recorded": return "承認を記録しました"
    case "Approve supervised experiment": return "監督付き実験を承認"
    case "Approval unavailable": return "承認できません"
    case "Approval record created. ECU writes remain locked.": return "承認記録を作成しました。ECU 書き込みはロックされたままです。"
    case "I reviewed the experiment": return "実験を確認しました"
    case "I verified the rollback path": return "ロールバック経路を確認しました"
    case "I understand the warnings": return "警告を理解しました"
    case "I will supervise the test": return "テストを監督します"
    case "DECISION · DETERMINISTIC": return "判定 · 決定論的"
    case "What changed": return "何が変わったか"
    case "The candidate moved the measured mixture closer to target in the tested window.": return "候補はテスト範囲で計測された混合気を目標に近づけました。"
    case "Baseline error": return "ベースライン誤差"
    case "Candidate error": return "候補誤差"
    case "Before": return "変更前"
    case "After": return "変更後"
    case "Next": return "次の変更"
    case "Increment visual": return "変更の見える化"
    case "The next step is half the previous bounded step; review the affected cells before testing.": return "次の変更幅は前回の制限付き変更の半分です。テスト前に影響セルを確認してください。"
    case "Next action": return "次の操作"
    case "Missing": return "不足"
    case "Optimization paused": return "最適化は一時停止中"
    case "Ready for a low-load test": return "低負荷テストの準備完了"
    case "Required identity, calibration, sensor, protection, and baseline evidence is present.": return "必要な識別情報・調整・センサー・保護機能・ベースライン証拠が揃っています。"
    case "Run one bounded test and stop if any protection or data-quality alert appears.": return "制限付きテストを1回実施し、保護またはデータ品質の警告が出たら停止してください。"
    case "The current evidence is insufficient to distinguish a calibration issue from a hardware or sensor issue.": return "現在の証拠だけでは、調整の問題とハードウェアまたはセンサーの問題を区別できません。"
    case "Verify the FC-03 identity and option configuration.": return "FC-03 の識別情報とオプション構成を確認してください。"
    case "Stop and investigate": return "停止して調査"
    case "A protection or data-integrity fault makes the current evidence unsafe for testing.": return "保護機能またはデータ整合性の異常があるため、現在の証拠でテストを続けるのは危険です。"
    case "Remove load, preserve the capture, and investigate the listed fault before another run.": return "負荷を下げ、キャプチャを保存し、次の走行前に表示された異常を調査してください。"
    case "ECU identity": return "ECU 識別情報"
    case "FC-03 protocol": return "FC-03 プロトコル"
    case "Original map backup": return "元マップのバックアップ"
    case "RPM": return "回転数"
    case "Coolant": return "冷却水"
    case "Run capture": return "走行キャプチャ"
    case "First-trial mode uses local fixture data. Real ECU capture remains read-only until FC-03 protocol verification.": return "初回トライアルはローカルデータを使用します。FC-03 プロトコル検証までは実 ECU 取得は読み取り専用です。"
    case "Run type": return "走行タイプ"
    case "Baseline": return "ベースライン"
    case "Candidate": return "候補"
    case "Repeat": return "再試行"
    case "Experiment": return "実験"
    case "Objective": return "目的"
    case "Drivability": return "運転性"
    case "RPM range": return "回転数範囲"
    case "Load range": return "負荷範囲"
    case "Context": return "コンテキスト"
    case "Route · test loop A": return "ルート · テストループ A"
    case "Capturing fixture": return "フィクスチャを取得中"
    case "Ready": return "準備完了"
    case "Tap to stop": return "タップして停止"
    case "Tap to run first trial": return "タップして初回トライアルを開始"
    case "Trial capture preserved locally": return "走行キャプチャをローカルに保存しました"
    case "Read-only trial started": return "読み取り専用トライアルを開始しました"
    case "No assessment": return "評価なし"
    case "Run the first-trial fixture from Live or Run.": return "ライブまたは走行から初回トライアルデータを読み込んでください。"
    case "First-trial assessment loaded": return "初回トライアル評価を読み込みました"
    case "Concerns": return "懸念事項"
    case "Next bounded proposal": return "次の制限付き提案"
    case "Fuel only": return "燃料のみ"
    case "Proposal locked": return "提案はロックされています"
    case "Approval": return "承認"
    case "Human review required · ECU writes remain disabled": return "人による確認が必要 · ECU 書き込みは無効です"
    case "Safety": return "安全"
    case "Language": return "言語"
    case "App language": return "アプリの言語"
    case "Vehicle": return "車両"
    case "Connection": return "接続"
    case "Freedom FC-03": return "Freedom FC-03"
    case "Profile": return "プロファイル"
    case "Transport": return "通信"
    case "Access": return "アクセス"
    case "Writes": return "書き込み"
    case "Locked": return "ロック"
    case "The exact FC-03 protocol and map semantics must be verified before adding a write path.": return "書き込み経路を追加する前に、FC-03 の正確なプロトコルとマップ仕様を検証する必要があります。"
    case "Frames": return "フレーム"
    case "Sequence": return "シーケンス"
    case "Load": return "負荷"
    case "RPM × load relationship": return "回転数 × 負荷の関係"
    case "Observed lambda": return "観測ラムダ"
    case "Incomplete": return "不完全"
    case "Protection event": return "保護イベント"
    case "Unvisited": return "未観測"
    case "Scrub the trace to inspect one frame": return "波形をスクラブしてフレームを確認"
    case "Evidence quality": return "証拠の品質"
    case "Causal interpretation": return "因果関係の解釈"
    case "Observed": return "観測済み"
    case "Next check": return "次の確認"
    case "Frames are contiguous and suitable for this replay.": return "フレームは連続しており、このリプレイに適しています。"
    case "Frame gaps make this run unsuitable for learning.": return "フレームの欠落があるため、この走行は学習に適していません。"
    case "Replay evidence only · not a live vehicle conclusion": return "リプレイ証拠のみ · 実車の結論ではありません"
    case "Knock event observed": return "ノックイベントを観測"
    case "Protection evidence overrides optimization": return "保護証拠が最適化より優先されます"
    case "Stop, preserve the run, and inspect knock, fuel, ignition, and mechanical causes.": return "停止して走行データを保存し、ノック・燃料・点火・機械系の原因を確認してください。"
    case "Lambda unavailable": return "ラムダが利用できません"
    case "The causal chain is incomplete": return "因果関係の連鎖が不完全です"
    case "Verify wideband calibration and capture a complete run before interpreting mixture.": return "混合気を解釈する前に、ワイドバンド校正を確認し、完全な走行を取得してください。"
    case "Lambda is above target": return "ラムダが目標より高い"
    case "The mixture is leaner than the 0.90 target in this replay": return "このリプレイでは混合気が目標 0.90 より薄い"
    case "Verify fuel pressure, injector data, sensor calibration, and air leaks before proposing fuel.": return "燃料を提案する前に、燃圧・インジェクターデータ・センサー校正・エア漏れを確認してください。"
    case "Lambda is below target": return "ラムダが目標より低い"
    case "The mixture is richer than the 0.90 target in this replay": return "このリプレイでは混合気が目標 0.90 より濃い"
    case "Check fuel pressure, injector characterization, enrichment, and sensor calibration.": return "燃圧・インジェクター特性・増量補正・センサー校正を確認してください。"
    case "Lambda is near target": return "ラムダは目標付近"
    case "No mixture correction is supported by this evidence": return "この証拠からは混合気補正を支持できません"
    case "Repeat the same operating window and confirm sensor plausibility.": return "同じ運転範囲を再試行し、センサーの妥当性を確認してください。"
    case "Accept candidate": return "候補を承認"
    case "Repeat the experiment": return "実験を再試行"
    case "Rollback and investigate": return "ロールバックして調査"
    case "Stop and abort": return "停止して中止"
    case "A critical protection or data-integrity concern blocks further testing.": return "重大な保護またはデータ整合性の懸念により、テストを続行できません。"
    case "The candidate improved the objective with repeatable evidence.": return "候補は再現性のある証拠で目的を改善しました。"
    case "The evidence is not strong enough to accept this calibration.": return "この調整を承認するには証拠が不十分です。"
    case "Knock detected": return "ノックを検出"
    case "Stop the test and investigate before learning from this change.": return "テストを停止し、この変更から学習する前に調査してください。"
    case "Telemetry incomplete": return "テレメトリが不完全"
    case "Dropped or missing frames mean this run cannot be used for learning.": return "フレームの欠落があるため、この走行は学習に使用できません。"
    case "Repeatability not proven": return "再現性が未確認"
    case "Repeat the same test condition before accepting the candidate.": return "候補を承認する前に同じ条件でテストを再試行してください。"
    default: return value
    }
}

private let defaultAppLanguage = Locale.current.language.languageCode?.identifier == "ja" ? "ja" : "en"

private enum LiveDisplayMode: String { case glance, engineer }

struct LiveView: View {
    @Binding var trial: MobileTrialSession
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage
    @AppStorage("liveDisplayMode") private var liveDisplayModeRaw = LiveDisplayMode.glance.rawValue
    @State private var selectedFrameIndex = 0
    private var locale: Locale { Locale(identifier: appLanguage) }
    private var displayMode: LiveDisplayMode { LiveDisplayMode(rawValue: liveDisplayModeRaw) ?? .glance }
    private var latestFrame: MobileTelemetryFrame? { trial.baseline.last }
    private var rpmValue: String { latestFrame.map { $0.rpm.formatted(.number.precision(.fractionLength(0))) } ?? "—" }
    private var lambdaValue: String { latestFrame?.lambda.map { $0.formatted(.number.precision(.fractionLength(3))) } ?? "—" }
    private var coolantValue: String { latestFrame?.coolantC.map { "\($0.formatted(.number.precision(.fractionLength(0))))°C" } ?? "—" }

    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack { Label("FC-03 · 9600 8N1", systemImage: "lock.shield"); Spacer(); Text(appText("READ-ONLY", locale: locale)).font(.caption2.monospaced()).foregroundStyle(.orange) }.foregroundStyle(.secondary)
            Text(appText("Live", locale: locale)).font(.largeTitle.bold())
            HStack {
                Picker(appText("View", locale: locale), selection: $liveDisplayModeRaw) {
                    Text(appText("Glance", locale: locale)).tag(LiveDisplayMode.glance.rawValue)
                    Text(appText("Engineer", locale: locale)).tag(LiveDisplayMode.engineer.rawValue)
                }
                .pickerStyle(.segmented)
            }
            ProvenanceBadge(source: trial.source, locale: locale)
            ReadinessCard(assessment: trial.readiness)
            if !trial.baseline.isEmpty && displayMode == .glance {
                CausalPanel(frames: trial.baseline, locale: locale)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Button(appText("Load first-trial fixture", locale: locale)) { trial = .demo() }.buttonStyle(.borderedProminent)
            HStack(spacing: 10) { Metric(title: "RPM", value: rpmValue); Metric(title: "λ", value: lambdaValue); Metric(title: "Coolant", value: coolantValue) }
            ZStack(alignment: .topLeading) {
                if displayMode == .engineer {
                    engineerContent.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    glanceContent.transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                }
            }
            .animation(.easeInOut(duration: 0.32), value: liveDisplayModeRaw)
            GroupBox(appText("Protection", locale: locale)) { Label(appText("Telemetry healthy", locale: locale), systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
            GroupBox(appText("Engine health", locale: locale)) { VStack(alignment: .leading, spacing: 10) { KeyValue("Oil pressure", "3.8 bar"); KeyValue("Fuel pressure", "3.0 bar"); KeyValue("Battery", "13.8 V"); KeyValue("Knock", "0 events") } }
            GroupBox(appText("Phone dynamics", locale: locale)) { VStack(alignment: .leading, spacing: 10) { KeyValue("Speed", "64 km/h"); KeyValue("Longitudinal", "0.42 g"); KeyValue("Lateral", "0.18 g"); KeyValue("GPS", "±2.4 m") } }
            Text(appText("Phone sensors provide context. They do not replace oil pressure, fuel pressure, lambda, or knock instrumentation.", locale: locale)).font(.caption).foregroundStyle(.secondary)
        }.padding() }.navigationTitle(appText("Freedom Monitor", locale: locale)).toolbar { ToolbarItem(placement: .topBarTrailing) { LanguageToggle() } } }
    }

    @ViewBuilder private var glanceContent: some View {
        GroupBox(appText("Lambda trace · baseline", locale: locale)) {
            if trial.baseline.isEmpty {
                Text(appText("Load the first-trial fixture or capture a verified run to view the trace.", locale: locale)).foregroundStyle(.secondary)
            } else {
                LinkedTelemetryPlot(frames: trial.baseline, selectedIndex: $selectedFrameIndex, locale: locale).frame(height: 170)
            }
        }
    }

    @ViewBuilder private var engineerContent: some View {
        if trial.baseline.isEmpty {
            Text(appText("Load the first-trial fixture or capture a verified run to view the trace.", locale: locale)).foregroundStyle(.secondary)
        } else {
            LinkedTelemetryPlot(frames: trial.baseline, selectedIndex: $selectedFrameIndex, locale: locale).frame(height: 185)
            GroupBox(appText("Baseline · candidate · repeat", locale: locale)) {
                ComparisonPlot(baseline: trial.baseline, candidate: trial.candidate, repeatRun: trial.repeatCandidate, selectedIndex: $selectedFrameIndex).frame(height: 180)
            }
            GroupBox(appText("RPM × load coverage", locale: locale)) {
                CoverageHeatmap(frames: trial.baseline, locale: locale).frame(height: 170)
            }
            GroupBox(appText("Evidence quality", locale: locale)) { EvidenceQualityPanel(frames: trial.baseline, locale: locale) }
            CausalPanel(frames: trial.baseline, locale: locale)
        }
    }
}

struct ReadinessCard: View {
    let assessment: MobileReadinessAssessment
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(appText(assessment.title, locale: locale), systemImage: assessment.state == .stop ? "stop.circle.fill" : "pause.circle.fill")
                        .font(.headline)
                    Spacer()
                    Text(appText(assessment.state == .stop ? "STOP" : "PAUSED", locale: locale))
                        .font(.caption2.monospaced().bold())
                        .foregroundStyle(assessment.state == .stop ? .red : .orange)
                }
                Text(appText(assessment.explanation, locale: locale)).font(.subheadline).foregroundStyle(.secondary)
                Text(appText("Next action", locale: locale)).font(.caption.bold()).foregroundStyle(.secondary)
                Text(appText(assessment.nextAction, locale: locale)).font(.subheadline)
                if !assessment.missingEvidence.isEmpty {
                    let missing = assessment.missingEvidence.prefix(3).map { appText($0, locale: locale) }.joined(separator: ", ")
                    Text("\(appText("Missing", locale: locale)): \(missing)\(assessment.missingEvidence.count > 3 ? "…" : "")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CaptureView: View {
    @Binding var trial: MobileTrialSession
    @Binding var toast: String?
    @State private var recording = false
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage
    private var locale: Locale { Locale(identifier: appLanguage) }
    var body: some View {
        NavigationStack { VStack(alignment: .leading, spacing: 18) {
            Text(appText("Run capture", locale: locale)).font(.largeTitle.bold())
            ProvenanceBadge(source: trial.source, locale: locale)
            Text(appText("First-trial mode uses local fixture data. Real ECU capture remains read-only until FC-03 protocol verification.", locale: locale)).foregroundStyle(.secondary)
            Picker(appText("Run type", locale: locale), selection: .constant("Candidate")) { Text(appText("Baseline", locale: locale)).tag("Baseline"); Text(appText("Candidate", locale: locale)).tag("Candidate"); Text(appText("Repeat", locale: locale)).tag("Repeat") }.pickerStyle(.segmented)
            GroupBox(appText("Experiment", locale: locale)) { VStack(alignment: .leading, spacing: 10) { KeyValue("Objective", appText("Drivability", locale: locale)); KeyValue("RPM range", "2,500–5,500"); KeyValue("Load range", "30–70%"); KeyValue("Context", appText("Route · test loop A", locale: locale)) } }
            Spacer()
            VStack(spacing: 12) {
                Text(appText(recording ? "Capturing fixture" : "Ready", locale: locale)).font(.title.monospacedDigit())
                Button {
                    recording.toggle()
                    if !recording {
                        if trial.stage == .setup { trial = .demo() }
                        toast = appText("Trial capture preserved locally", locale: locale)
                    } else { toast = appText("Read-only trial started", locale: locale) }
                } label: { Circle().fill(recording ? .red : .orange).frame(width: 82, height: 82).overlay(Circle().stroke(.primary.opacity(0.15), lineWidth: 4)) }.buttonStyle(.plain)
                Text(appText(recording ? "Tap to stop" : "Tap to run first trial", locale: locale)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity)
        }.padding().navigationTitle(appText("Run", locale: locale)).toolbar { ToolbarItem(placement: .topBarTrailing) { LanguageToggle() } } }
        .environment(\.locale, locale)
    }
}

struct ReviewView: View {
    @Binding var trial: MobileTrialSession
    @Binding var approvalChecks: [Bool]
    @Binding var toast: String?
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage
    private var locale: Locale { Locale(identifier: appLanguage) }
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack { Text(appText("Review", locale: locale)).font(.largeTitle.bold()); Spacer(); Text(decisionLabel).font(.caption2.monospaced().bold()).foregroundStyle(trial.assessment?.hasCriticalConcern == true ? .red : .orange) }
            ReviewRail(trial: trial, locale: locale)
            ProvenanceBadge(source: trial.source, locale: locale)
            if let assessment = trial.assessment { assessmentView(assessment) } else { ContentUnavailableView(appText("No assessment", locale: locale), systemImage: "doc.text.magnifyingglass", description: Text(appText("Run the first-trial fixture from Live or Run.", locale: locale))); Button(appText("Load first-trial fixture", locale: locale)) { trial = .demo(); toast = appText("First-trial assessment loaded", locale: locale) }.buttonStyle(.borderedProminent) }
        }.padding() }.navigationTitle(appText("Experiment", locale: locale)).toolbar { ToolbarItem(placement: .topBarTrailing) { LanguageToggle() } } }
        .environment(\.locale, locale)
    }
    private var decisionLabel: String { guard let assessment = trial.assessment else { return "UNASSESSED" }; switch assessment.decision { case .acceptCandidate: return "ACCEPT"; case .repeatExperiment: return "REPEAT"; case .rollbackAndInvestigate: return "ROLLBACK"; case .stopAndAbort: return "ABORT" } }
    @ViewBuilder private func assessmentView(_ value: MobileExperimentAssessment) -> some View {
        DecisionCard(assessment: value)
        HStack(spacing: 10) { Metric(title: "Improvement", value: value.improvementFraction.map { "\(($0 * 100).formatted(.number.precision(.fractionLength(1))))%" } ?? "—"); Metric(title: "Repeat", value: value.repeatable == true ? "PASS" : "FAIL"); Metric(title: "Knock", value: "\(value.knockEvents)") }
        GroupBox(appText("Concerns", locale: locale)) { if value.concerns.isEmpty { Label(appText("No automatic concerns", locale: locale), systemImage: "checkmark.circle").foregroundStyle(.green) } else { VStack(alignment: .leading, spacing: 12) { ForEach(value.concerns, id: \.code) { ConcernRow(concern: $0) } } } }
        if value.decision == .acceptCandidate {
            IncrementChangeCard(assessment: value, baseline: trial.baseline, candidate: trial.candidate, locale: locale)
        }
        GroupBox(appText("Next bounded proposal", locale: locale)) {
            VStack(alignment: .leading, spacing: 8) {
                if value.decision == .acceptCandidate {
                    Label(appText("Fuel only", locale: locale), systemImage: "fuelpump.fill").font(.headline)
                    Text(appText("Review the affected RPM/load cells and repeat the same test before accepting the smaller step.", locale: locale))
                    KeyValue("Maximum next change", "\((value.nextChangeFractionLimit * 100).formatted(.number.precision(.fractionLength(2))))%")
                    KeyValue("Ignition", "Locked")
                } else {
                    Label(appText("Proposal locked", locale: locale), systemImage: "lock.fill").font(.headline)
                    Text(appText("The current evidence does not permit an incremental calibration proposal.", locale: locale))
                }
                Text(appText("Human review required · ECU writes remain disabled", locale: locale)).font(.caption).foregroundStyle(.secondary)
            }
        }
            GroupBox(appText("Approval", locale: locale)) { VStack(alignment: .leading, spacing: 10) { ApprovalCheck("I reviewed the experiment", index: 0); ApprovalCheck("I verified the rollback path", index: 1); ApprovalCheck("I understand the warnings", index: 2); ApprovalCheck("I will supervise the test", index: 3); Button(appText(value.decision == .acceptCandidate ? (trial.approvalRecorded ? "Approval recorded" : "Approve supervised experiment") : "Approval unavailable", locale: locale)) { if trial.recordApproval() { toast = appText("Approval record created. ECU writes remain locked.", locale: locale) } }.buttonStyle(.borderedProminent).disabled(value.decision != .acceptCandidate || trial.approvalRecorded || !approvalChecks.allSatisfy { $0 }) } }
    }
    private func ApprovalCheck(_ text: String, index: Int) -> some View { Toggle(appText(text, locale: locale), isOn: Binding(get: { approvalChecks[index] }, set: { approvalChecks[index] = $0 })) }
}

struct ReviewRail: View {
    let trial: MobileTrialSession
    let locale: Locale

    private var activeStep: Int { trial.assessment == nil ? (trial.baseline.isEmpty ? 0 : 1) : (trial.approvalRecorded ? 3 : 2) }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(["Evidence", "Interpretation", "Proposal", "Approval"].enumerated()), id: \.offset) { index, title in
                VStack(spacing: 4) {
                    Circle().fill(index <= activeStep ? Color.orange : Color.secondary.opacity(0.2)).frame(width: 10, height: 10)
                    Text(appText(title, locale: locale)).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                }.frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: activeStep)
    }
}

struct IncrementChangeCard: View {
    let assessment: MobileExperimentAssessment
    let baseline: [MobileTelemetryFrame]
    let candidate: [MobileTelemetryFrame]
    let locale: Locale

    private var baselineLambda: Double? { meanLambda(baseline) }
    private var candidateLambda: Double? { meanLambda(candidate) }
    private var rpmWindow: String {
        let frames = baseline + candidate
        guard let low = frames.map(\.rpm).min(), let high = frames.map(\.rpm).max() else { return "—" }
        return "\(low.formatted(.number.precision(.fractionLength(0))))–\(high.formatted(.number.precision(.fractionLength(0)))) RPM"
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(appText("What changed", locale: locale), systemImage: "arrow.down.right.circle.fill").font(.headline)
                    Spacer()
                    Text(appText("Fuel only", locale: locale)).font(.caption.monospaced().bold()).foregroundStyle(.orange)
                }
                Text(appText("The candidate moved the measured mixture closer to target in the tested window.", locale: locale)).font(.subheadline).foregroundStyle(.secondary)
                Text(rpmWindow).font(.caption.monospacedDigit()).foregroundStyle(.secondary)

                ChangeBar(label: appText("Baseline error", locale: locale), value: assessment.baselineLambdaError ?? 0, maximum: 0.12, color: .secondary)
                ChangeBar(label: appText("Candidate error", locale: locale), value: assessment.candidateLambdaError ?? 0, maximum: 0.12, color: .orange)

                HStack(spacing: 10) {
                    ValuePill(label: appText("Before", locale: locale), value: baselineLambda?.formatted(.number.precision(.fractionLength(3))) ?? "—", color: .secondary)
                    Image(systemName: "arrow.right").foregroundStyle(.green)
                    ValuePill(label: appText("After", locale: locale), value: candidateLambda?.formatted(.number.precision(.fractionLength(3))) ?? "—", color: .green)
                    Image(systemName: "arrow.right").foregroundStyle(.orange)
                    ValuePill(label: appText("Next", locale: locale), value: "\((assessment.nextChangeFractionLimit * 100).formatted(.number.precision(.fractionLength(2))))%", color: .orange)
                }
                Text(appText("The next step is half the previous bounded step; review the affected cells before testing.", locale: locale)).font(.caption).foregroundStyle(.secondary)
            }
        } label: {
            Text(appText("Increment visual", locale: locale))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func meanLambda(_ frames: [MobileTelemetryFrame]) -> Double? {
        let values = frames.compactMap(\.lambda)
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}

struct ChangeBar: View {
    let label: String
    let value: Double
    let maximum: Double
    let color: Color
    @State private var animatedValue = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack { Text(label).font(.caption); Spacer(); Text(value.formatted(.number.precision(.fractionLength(3)))).font(.caption.monospacedDigit()) }
            GeometryReader { proxy in
                Capsule().fill(Color.secondary.opacity(0.14)).overlay(alignment: .leading) {
                Capsule().fill(color).frame(width: max(4, proxy.size.width * min(1, animatedValue / maximum)))
                }
            }.frame(height: 8)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.65).delay(0.08)) { animatedValue = value } }
        .onChange(of: value) { _, newValue in withAnimation(.easeOut(duration: 0.45)) { animatedValue = newValue } }
    }
}

struct ValuePill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit()).foregroundStyle(color)
        }.frame(maxWidth: .infinity).padding(.vertical, 7).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct DecisionCard: View {
    let assessment: MobileExperimentAssessment
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage
    private var locale: Locale { Locale(identifier: appLanguage) }
    var body: some View { VStack(alignment: .leading, spacing: 8) { Text("DECISION · DETERMINISTIC").font(.caption2.monospaced().bold()).foregroundStyle(assessment.hasCriticalConcern ? .red : .orange); Text(appText(title, locale: locale)).font(.title2.bold()); Text(appText(reason, locale: locale)).foregroundStyle(.secondary); Divider(); KeyValue("Next change limit", assessment.nextChangeFractionLimit == 0 ? appText("Locked", locale: locale) : "\((assessment.nextChangeFractionLimit * 100).formatted(.number.precision(.fractionLength(2))))%") }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18)) }
    private var title: String { switch assessment.decision { case .acceptCandidate: return "Accept candidate"; case .repeatExperiment: return "Repeat the experiment"; case .rollbackAndInvestigate: return "Rollback and investigate"; case .stopAndAbort: return "Stop and abort" } }
    private var reason: String { assessment.hasCriticalConcern ? "A critical protection or data-integrity concern blocks further testing." : assessment.decision == .acceptCandidate ? "The candidate improved the objective with repeatable evidence." : "The evidence is not strong enough to accept this calibration." }
}

struct ConcernRow: View { let concern: MobileExperimentConcern; @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage; private var locale: Locale { Locale(identifier: appLanguage) }; var body: some View { VStack(alignment: .leading, spacing: 4) { Text(concern.severity.rawValue.uppercased()).font(.caption2.monospaced().bold()).foregroundStyle(concern.severity == .critical ? .red : .orange); Text(appText(concern.title, locale: locale)).font(.headline); Text(appText(concern.detail, locale: locale)).font(.caption).foregroundStyle(.secondary) } } }

struct ProvenanceBadge: View {
    let source: MobileEvidenceSource
    let locale: Locale

    var body: some View {
        Label(appText(source.badge, locale: locale), systemImage: source == .ecuReadOnly ? "antenna.radiowaves.left.and.right" : "internaldrive")
            .font(.caption.monospaced().bold())
            .foregroundStyle(source == .ecuReadOnly ? .green : .orange)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.22), value: source)
    }
}

struct LinkedTelemetryPlot: View {
    let frames: [MobileTelemetryFrame]
    @Binding var selectedIndex: Int
    let locale: Locale

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Label(appText("Observed lambda", locale: locale), systemImage: "waveform.path.ecg")
                    .font(.caption.weight(.semibold)).foregroundStyle(.orange)
                Label(appText("Target 0.90", locale: locale), systemImage: "line.diagonal")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(appText("Scrub the trace to inspect one frame", locale: locale))
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
            }
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    TelemetryPlot(frames: frames)
                    if !frames.isEmpty {
                        let index = min(max(selectedIndex, 0), frames.count - 1)
                        let x = proxy.size.width * CGFloat(index) / CGFloat(max(frames.count - 1, 1))
                        Rectangle().fill(.orange.opacity(0.7)).frame(width: 2).offset(x: x)
                        if let value = frames[index].lambda {
                            let y = proxy.size.height * (1 - CGFloat(max(0, min(1, (value - 0.75) / 0.45))))
                            Circle().fill(.orange).frame(width: 10, height: 10)
                                .overlay(Circle().stroke(.black.opacity(0.45), lineWidth: 2))
                                .position(x: x, y: y)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("λ (value.formatted(.number.precision(.fractionLength(3))))")
                                    .font(.caption.monospacedDigit().bold())
                                Text("Δ (((value - 0.90)).formatted(.number.precision(.fractionLength(3))))")
                                    .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
                            .offset(x: min(max(x - 34, 0), max(proxy.size.width - 82, 0)), y: max(y - 48, 4))
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    guard frames.count > 1 else { return }
                    selectedIndex = min(max(Int((value.location.x / proxy.size.width) * CGFloat(frames.count - 1)), 0), frames.count - 1)
                })
            }
            if let frame = frames.indices.contains(min(max(selectedIndex, 0), max(frames.count - 1, 0))) ? frames[min(max(selectedIndex, 0), max(frames.count - 1, 0))] : nil {
                HStack(spacing: 12) {
                    Text("RPM \(frame.rpm.formatted(.number.precision(.fractionLength(0))))")
                    Text("\(appText("Load", locale: locale)) \(frame.loadKPa.formatted(.number.precision(.fractionLength(0)))) kPa")
                    Text("λ \(frame.lambda?.formatted(.number.precision(.fractionLength(3))) ?? "—")")
                }.font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            HStack { Text("0").font(.caption2.monospacedDigit()); Spacer(); Text("run end").font(.caption2) }
                .foregroundStyle(.secondary)
        }
    }
}

struct ComparisonPlot: View {
    let baseline: [MobileTelemetryFrame]
    let candidate: [MobileTelemetryFrame]
    let repeatRun: [MobileTelemetryFrame]
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                comparisonLegend("Baseline", color: .secondary)
                comparisonLegend("Candidate", color: .orange)
                comparisonLegend("Repeat", color: .blue)
                Spacer()
                Text("λ target 0.90").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                Canvas { context, size in
                    for fraction in stride(from: 0.0, through: 1.0, by: 0.25) {
                        var grid = Path(); let y = size.height * fraction
                        grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(grid, with: .color(.secondary.opacity(0.15)), lineWidth: 1)
                    }
                    let targetY = size.height * (1 - CGFloat((0.90 - 0.75) / 0.45))
                    var target = Path(); target.move(to: CGPoint(x: 0, y: targetY)); target.addLine(to: CGPoint(x: size.width, y: targetY))
                    context.stroke(target, with: .color(.orange.opacity(0.55)), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    draw(frames: baseline, size: size, color: .secondary, context: &context)
                    draw(frames: candidate, size: size, color: .orange, context: &context)
                    draw(frames: repeatRun, size: size, color: .blue, context: &context)
                    if !baseline.isEmpty {
                        let x = size.width * CGFloat(min(max(selectedIndex, 0), baseline.count - 1)) / CGFloat(max(baseline.count - 1, 1))
                        var cursor = Path(); cursor.move(to: CGPoint(x: x, y: 0)); cursor.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(cursor, with: .color(.primary.opacity(0.55)), lineWidth: 2)
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let count = max(baseline.count, candidate.count, repeatRun.count)
                    guard count > 1 else { return }
                    selectedIndex = min(max(Int((value.location.x / proxy.size.width) * CGFloat(count - 1)), 0), count - 1)
                })
            }
        }
    }

    private func comparisonLegend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 7, height: 7); Text(title).font(.caption2) }
            .foregroundStyle(color)
    }

    private func draw(frames: [MobileTelemetryFrame], size: CGSize, color: Color, context: inout GraphicsContext) {
        let values = frames.compactMap(\.lambda)
        guard values.count > 1 else { return }
        var path = Path()
        for (index, value) in values.enumerated() {
            let point = CGPoint(x: size.width * CGFloat(index) / CGFloat(values.count - 1), y: size.height * (1 - CGFloat(max(0, min(1, (value - 0.75) / 0.45)))))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        context.stroke(path, with: .color(color), lineWidth: 3)
    }
}

struct CoverageHeatmap: View {
    let frames: [MobileTelemetryFrame]
    let locale: Locale

    var body: some View {
        let cells = MobileEvidenceAnalyzer.coverage(frames: frames)
        let rpmBands = Array(Set(cells.map(\.rpmBand))).sorted()
        let loadBands = Array(Set(cells.map(\.loadBand))).sorted()
        return VStack(alignment: .leading, spacing: 8) {
            if cells.isEmpty {
                Text(appText("No operating cells observed", locale: locale)).foregroundStyle(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    VStack(spacing: 4) {
                        Text("RPM").font(.caption2.monospaced().bold()).rotationEffect(.degrees(-90))
                        Spacer(minLength: 4)
                    }.frame(width: 22)
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(loadBands, id: \.self) { load in
                            VStack(spacing: 4) {
                                ForEach(rpmBands, id: \.self) { rpm in
                                    let cell = cells.first { $0.rpmBand == rpm && $0.loadBand == load }
                                    RoundedRectangle(cornerRadius: 4).fill(cellColor(cell?.state)).frame(maxWidth: .infinity).overlay(Text(cell.map { "\($0.frameCount)" } ?? "").font(.caption2.monospacedDigit()))
                                        .transition(.scale.combined(with: .opacity))
                                        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: cell?.state)
                                }
                                Text("\(load)").font(.caption2.monospacedDigit())
                            }
                        }
                    }
                }
                HStack(spacing: 10) {
                    coverageLegend("Observed", state: .observed)
                    coverageLegend("Incomplete", state: .incomplete)
                    coverageLegend("Protection event", state: .protectionEvent)
                    coverageLegend("Unvisited", state: .unvisited)
                }.font(.caption2)
                Text(appText("Cells are observed replay coverage, not a tune-quality score.", locale: locale)).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func coverageLegend(_ title: String, state: MobileCoverageState) -> some View {
        HStack(spacing: 4) { RoundedRectangle(cornerRadius: 2).fill(cellColor(state)).frame(width: 10, height: 10); Text(appText(title, locale: locale)) }
            .foregroundStyle(.secondary)
    }

    private func cellColor(_ state: MobileCoverageState?) -> Color {
        switch state {
        case .observed: return .green.opacity(0.65)
        case .incomplete: return .orange.opacity(0.65)
        case .protectionEvent: return .red.opacity(0.7)
        default: return .secondary.opacity(0.15)
        }
    }
}

struct TelemetryPlot: View {
    let frames: [MobileTelemetryFrame]
    private let target = 0.90
    @State private var reveal = 0.0

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let horizontal = Path { path in
                    for fraction in stride(from: 0.0, through: 1.0, by: 0.25) {
                        let y = size.height * fraction
                        path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                }
                context.stroke(horizontal, with: .color(.secondary.opacity(0.18)), lineWidth: 1)
                let targetPath = Path { path in
                    let y = yPosition(target, height: size.height)
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(targetPath, with: .color(.orange.opacity(0.65)), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                let values = frames.compactMap(\.lambda)
                guard values.count > 1 else { return }
                let visibleCount = max(2, min(values.count, Int(CGFloat(values.count) * reveal)))
                let trace = Path { path in
                    for (index, value) in values.prefix(visibleCount).enumerated() {
                        let x = size.width * CGFloat(index) / CGFloat(max(visibleCount - 1, 1))
                        let point = CGPoint(x: x, y: yPosition(value, height: size.height))
                        if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    }
                }
                context.stroke(trace, with: .color(.orange), lineWidth: 3)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.75)) { reveal = 1 } }
        .onChange(of: frames) { _, _ in
            reveal = 0
            withAnimation(.easeOut(duration: 0.75)) { reveal = 1 }
        }
    }

    private func yPosition(_ value: Double, height: CGFloat) -> CGFloat {
        let normalized = max(0, min(1, (value - 0.75) / 0.45))
        return height * (1 - CGFloat(normalized))
    }
}

struct RpmLoadPlot: View {
    let frames: [MobileTelemetryFrame]

    var body: some View {
        Canvas { context, size in
            for fraction in stride(from: 0.0, through: 1.0, by: 0.25) {
                let y = size.height * fraction
                var grid = Path(); grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(grid, with: .color(.secondary.opacity(0.16)), lineWidth: 1)
            }
            trace(values: frames.map { min(max($0.rpm / 8000, 0), 1) }, size: size, color: .orange, context: &context)
            trace(values: frames.map { min(max($0.loadKPa / 100, 0), 1) }, size: size, color: .blue, context: &context)
        }
    }

    private func trace(values: [Double], size: CGSize, color: Color, context: inout GraphicsContext) {
        guard values.count > 1 else { return }
        var path = Path()
        for (index, value) in values.enumerated() {
            let point = CGPoint(x: size.width * CGFloat(index) / CGFloat(values.count - 1), y: size.height * (1 - CGFloat(value)))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        context.stroke(path, with: .color(color), lineWidth: 3)
    }
}

struct EvidenceQualityPanel: View {
    let frames: [MobileTelemetryFrame]
    let locale: Locale

    private var sequences: [Int] { frames.compactMap(\.sequence) }
    private var contiguous: Bool { sequences.count == frames.count && zip(sequences, sequences.dropFirst()).allSatisfy { $1 == $0 + 1 } }
    private var lambdas: [Double] { frames.compactMap(\.lambda) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                QualityBadge(label: appText("Frames", locale: locale), value: "\(frames.count)", systemImage: "square.stack.3d.up")
                QualityBadge(label: appText("Sequence", locale: locale), value: contiguous ? "OK" : "GAP", systemImage: contiguous ? "checkmark.circle" : "exclamationmark.triangle")
                QualityBadge(label: appText("Lambda", locale: locale), value: "\(lambdas.count)/\(frames.count)", systemImage: "waveform")
            }
            Text(appText(contiguous ? "Frames are contiguous and suitable for this replay." : "Frame gaps make this run unsuitable for learning.", locale: locale))
                .font(.caption).foregroundStyle(contiguous ? Color.secondary : Color.orange)
        }
    }
}

struct QualityBadge: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: systemImage).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct CausalPanel: View {
    let frames: [MobileTelemetryFrame]
    let locale: Locale

    init(frames: [MobileTelemetryFrame], locale: Locale) {
        self.frames = frames
        self.locale = locale
    }

    private var target = 0.90
    private var meanLambda: Double { let values = frames.compactMap(\.lambda); return values.isEmpty ? .nan : values.reduce(0, +) / Double(values.count) }
    private var explanation: (String, String, String) {
        if frames.contains(where: { ($0.knockLevel ?? 0) > 0.15 }) {
            return ("Knock event observed", "Protection evidence overrides optimization", "Stop, preserve the run, and inspect knock, fuel, ignition, and mechanical causes.")
        }
        if meanLambda.isNaN { return ("Lambda unavailable", "The causal chain is incomplete", "Verify wideband calibration and capture a complete run before interpreting mixture.") }
        if meanLambda > target + 0.03 {
            return ("Lambda is above target", "The mixture is leaner than the 0.90 target in this replay", "Verify fuel pressure, injector data, sensor calibration, and air leaks before proposing fuel.")
        }
        if meanLambda < target - 0.03 {
            return ("Lambda is below target", "The mixture is richer than the 0.90 target in this replay", "Check fuel pressure, injector characterization, enrichment, and sensor calibration.")
        }
        return ("Lambda is near target", "No mixture correction is supported by this evidence", "Repeat the same operating window and confirm sensor plausibility.")
    }

    var body: some View {
        let chain = explanation
        return GroupBox(appText("Causal interpretation", locale: locale)) {
            VStack(alignment: .leading, spacing: 10) {
                CausalRow(step: appText("Observed", locale: locale), value: appText(chain.0, locale: locale), color: Color.orange)
                CausalRow(step: appText("Interpretation", locale: locale), value: appText(chain.1, locale: locale), color: Color.blue)
                CausalRow(step: appText("Next check", locale: locale), value: appText(chain.2, locale: locale), color: Color.green)
                Text(appText("Replay evidence only · not a live vehicle conclusion", locale: locale)).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct CausalRow: View {
    let step: String
    let value: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step.uppercased()).font(.caption2.monospaced().bold()).foregroundStyle(color).frame(width: 104, alignment: .leading)
            Text(value).font(.subheadline)
        }
    }
}
struct SetupView: View {
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        NavigationStack {
            List {
                Section(appText("Vehicle", locale: locale)) { KeyValue("Profile", "AE86 · 4A-GE 20V Blacktop"); KeyValue("ECU", "Freedom FC-03"); KeyValue("Identity", "Inferred") }
                Section(appText("Connection", locale: locale)) { KeyValue("Transport", "USB-C → RS-232"); KeyValue("Baud", "9600 · 8N1"); KeyValue("Access", "Read-only"); KeyValue("Writes", "Locked") }
                Section(appText("Language", locale: locale)) {
                    Picker(appText("App language", locale: locale), selection: $appLanguage) {
                        Text("English").tag("en")
                        Text("日本語").tag("ja")
                    }
                    .pickerStyle(.segmented)
                }
                Section(appText("Safety", locale: locale)) { Text(appText("The exact FC-03 protocol and map semantics must be verified before adding a write path.", locale: locale)).font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle(appText("Setup", locale: locale))
            .toolbar { ToolbarItem(placement: .topBarTrailing) { LanguageToggle() } }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
    }
}
struct LanguageToggle: View {
    @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage

    var body: some View {
        Button {
            appLanguage = appLanguage == "ja" ? "en" : "ja"
        } label: {
            Text(appLanguage == "ja" ? "English" : "日本語")
                .font(.caption.weight(.semibold))
        }
        .accessibilityLabel(appLanguage == "ja" ? "Switch to English" : "日本語に切り替える")
    }
}
struct Metric: View { let title: String; let value: String; @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage; private var locale: Locale { Locale(identifier: appLanguage) }; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(appText(title, locale: locale)).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.monospacedDigit().bold()) }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12)) } }
struct KeyValue: View { let title: String; let value: String; @AppStorage("appLanguage") private var appLanguage = defaultAppLanguage; private var locale: Locale { Locale(identifier: appLanguage) }; init(_ title: String, _ value: String) { self.title = title; self.value = value }; var body: some View { HStack { Text(appText(title, locale: locale)).foregroundStyle(.secondary); Spacer(); Text(value).monospacedDigit() } } }
enum DemoAssessment { static func make() -> MobileExperimentAssessment { let base = [1.0, 0.99, 1.0].map { MobileTelemetryFrame(rpm: 3000, loadKPa: 50, lambda: $0) }; let candidate = [0.93, 0.92, 0.91].map { MobileTelemetryFrame(rpm: 3000, loadKPa: 50, lambda: $0) }; let repeatRun = [0.925, 0.915, 0.905].map { MobileTelemetryFrame(rpm: 3000, loadKPa: 50, lambda: $0) }; return MobileExperimentAssessor.assess(baseline: base, candidate: candidate, repeatRun: repeatRun) } }
