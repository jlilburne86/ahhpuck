import SwiftUI
import FreedomMobileCore

@main
struct FreedomIOSApp: App { var body: some Scene { WindowGroup { FreedomRootView() } } }

struct FreedomRootView: View {
    @State private var selection: AppTab = .live
    @State private var assessment: MobileExperimentAssessment?
    @State private var approvalChecks = Array(repeating: false, count: 4)
    @State private var toast: String?

    var body: some View {
        TabView(selection: $selection) {
            LiveView().tabItem { Label("Live", systemImage: "waveform.path.ecg") }.tag(AppTab.live)
            CaptureView(toast: $toast).tabItem { Label("Run", systemImage: "record.circle") }.tag(AppTab.run)
            ReviewView(assessment: $assessment, approvalChecks: $approvalChecks, toast: $toast).tabItem { Label("Review", systemImage: "checkmark.seal") }.tag(AppTab.review)
            SetupView().tabItem { Label("Setup", systemImage: "gearshape") }.tag(AppTab.setup)
        }.tint(.orange).overlay(alignment: .top) { if let toast { Text(toast).font(.footnote.weight(.semibold)).padding(.horizontal, 14).padding(.vertical, 10).background(.thinMaterial, in: Capsule()).padding(.top, 8) } }
    }
}

private enum AppTab { case live, run, review, setup }

struct LiveView: View {
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack { Label("FC-03 · 9600 8N1", systemImage: "lock.shield"); Spacer(); Text("READ-ONLY").font(.caption2.monospaced()).foregroundStyle(.orange) }.foregroundStyle(.secondary)
            Text("Live").font(.largeTitle.bold())
            HStack(spacing: 10) { Metric(title: "RPM", value: "3,820"); Metric(title: "λ", value: "0.912"); Metric(title: "Coolant", value: "86°C") }
            GroupBox("Protection") { Label("Telemetry healthy", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
            GroupBox("Engine health") { VStack(alignment: .leading, spacing: 10) { KeyValue("Oil pressure", "3.8 bar"); KeyValue("Fuel pressure", "3.0 bar"); KeyValue("Battery", "13.8 V"); KeyValue("Knock", "0 events") } }
            GroupBox("Phone dynamics") { VStack(alignment: .leading, spacing: 10) { KeyValue("Speed", "64 km/h"); KeyValue("Longitudinal", "0.42 g"); KeyValue("Lateral", "0.18 g"); KeyValue("GPS", "±2.4 m") } }
            Text("Phone sensors provide context. They do not replace oil pressure, fuel pressure, lambda, or knock instrumentation.").font(.caption).foregroundStyle(.secondary)
        }.padding() }.navigationTitle("Freedom Monitor") }
    }
}

struct CaptureView: View {
    @Binding var toast: String?
    @State private var recording = false
    var body: some View {
        NavigationStack { VStack(alignment: .leading, spacing: 18) {
            Text("Run capture").font(.largeTitle.bold())
            Text("Create a baseline, candidate, or repeat capture. ECU and phone data are stored together.").foregroundStyle(.secondary)
            Picker("Run type", selection: .constant("Candidate")) { Text("Baseline").tag("Baseline"); Text("Candidate").tag("Candidate"); Text("Repeat").tag("Repeat") }.pickerStyle(.segmented)
            GroupBox("Experiment") { VStack(alignment: .leading, spacing: 10) { KeyValue("Objective", "Drivability"); KeyValue("RPM range", "2,500–5,500"); KeyValue("Load range", "30–70%"); KeyValue("Context", "Route · test loop A") } }
            Spacer()
            VStack(spacing: 12) { Text(recording ? "00:12.4" : "Ready").font(.title.monospacedDigit()); Button { recording.toggle(); toast = recording ? "Capture started" : "Capture stopped and preserved" } label: { Circle().fill(recording ? .red : .orange).frame(width: 82, height: 82).overlay(Circle().stroke(.primary.opacity(0.15), lineWidth: 4)) }.buttonStyle(.plain); Text(recording ? "Tap to stop" : "Tap to record candidate").foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
        }.padding().navigationTitle("Run") }
    }
}

struct ReviewView: View {
    @Binding var assessment: MobileExperimentAssessment?
    @Binding var approvalChecks: [Bool]
    @Binding var toast: String?
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack { Text("Review").font(.largeTitle.bold()); Spacer(); Text(decisionLabel).font(.caption2.monospaced().bold()).foregroundStyle(assessment?.hasCriticalConcern == true ? .red : .orange) }
            if let assessment { assessmentView(assessment) } else { ContentUnavailableView("No assessment", systemImage: "doc.text.magnifyingglass", description: Text("Load three telemetry runs, or load the demo assessment.")); Button("Load demo assessment") { assessment = DemoAssessment.make(); toast = "Demo assessment loaded" }.buttonStyle(.borderedProminent) }
        }.padding() }.navigationTitle("Experiment") }
    }
    private var decisionLabel: String { guard let assessment else { return "UNASSESSED" }; switch assessment.decision { case .acceptCandidate: return "ACCEPT"; case .repeatExperiment: return "REPEAT"; case .rollbackAndInvestigate: return "ROLLBACK"; case .stopAndAbort: return "ABORT" } }
    @ViewBuilder private func assessmentView(_ value: MobileExperimentAssessment) -> some View {
        DecisionCard(assessment: value)
        HStack(spacing: 10) { Metric(title: "Improvement", value: value.improvementFraction.map { "\(($0 * 100).formatted(.number.precision(.fractionLength(1))))%" } ?? "—"); Metric(title: "Repeat", value: value.repeatable == true ? "PASS" : "FAIL"); Metric(title: "Knock", value: "\(value.knockEvents)") }
        GroupBox("Concerns") { if value.concerns.isEmpty { Label("No automatic concerns", systemImage: "checkmark.circle").foregroundStyle(.green) } else { VStack(alignment: .leading, spacing: 12) { ForEach(value.concerns, id: \.code) { ConcernRow(concern: $0) } } } }
        GroupBox("Approval") { VStack(alignment: .leading, spacing: 10) { ApprovalCheck("I reviewed the experiment", index: 0); ApprovalCheck("I verified the rollback path", index: 1); ApprovalCheck("I understand the warnings", index: 2); ApprovalCheck("I will supervise the test", index: 3); Button(value.decision == .acceptCandidate ? "Approve supervised experiment" : "Approval unavailable") { toast = "Approval record created. ECU writes remain locked." }.buttonStyle(.borderedProminent).disabled(value.decision != .acceptCandidate || !approvalChecks.allSatisfy { $0 }) } }
    }
    private func ApprovalCheck(_ text: String, index: Int) -> some View { Toggle(text, isOn: Binding(get: { approvalChecks[index] }, set: { approvalChecks[index] = $0 })) }
}

struct DecisionCard: View { let assessment: MobileExperimentAssessment; var body: some View { VStack(alignment: .leading, spacing: 8) { Text("DECISION · DETERMINISTIC").font(.caption2.monospaced().bold()).foregroundStyle(assessment.hasCriticalConcern ? .red : .orange); Text(title).font(.title2.bold()); Text(reason).foregroundStyle(.secondary); Divider(); KeyValue("Next change limit", assessment.nextChangeFractionLimit == 0 ? "Locked" : "\((assessment.nextChangeFractionLimit * 100).formatted(.number.precision(.fractionLength(2))))%") }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18)) }
    private var title: String { switch assessment.decision { case .acceptCandidate: return "Accept candidate"; case .repeatExperiment: return "Repeat the experiment"; case .rollbackAndInvestigate: return "Rollback and investigate"; case .stopAndAbort: return "Stop and abort" } }
    private var reason: String { assessment.hasCriticalConcern ? "A critical protection or data-integrity concern blocks further testing." : assessment.decision == .acceptCandidate ? "The candidate improved the objective with repeatable evidence." : "The evidence is not strong enough to accept this calibration." }
}

struct ConcernRow: View { let concern: MobileExperimentConcern; var body: some View { VStack(alignment: .leading, spacing: 4) { Text(concern.severity.rawValue.uppercased()).font(.caption2.monospaced().bold()).foregroundStyle(concern.severity == .critical ? .red : .orange); Text(concern.title).font(.headline); Text(concern.detail).font(.caption).foregroundStyle(.secondary) } } }
struct SetupView: View { var body: some View { NavigationStack { List { Section("Vehicle") { KeyValue("Profile", "AE86 · 4A-GE 20V Blacktop"); KeyValue("ECU", "Freedom FC-03"); KeyValue("Identity", "Inferred") }; Section("Connection") { KeyValue("Transport", "USB-C → RS-232"); KeyValue("Baud", "9600 · 8N1"); KeyValue("Access", "Read-only"); KeyValue("Writes", "Locked") }; Section("Safety") { Text("The exact FC-03 protocol and map semantics must be verified before adding a write path.").font(.caption).foregroundStyle(.secondary) } }.navigationTitle("Setup") } } }
struct Metric: View { let title: String; let value: String; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.monospacedDigit().bold()) }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12)) } }
struct KeyValue: View { let title: String; let value: String; init(_ title: String, _ value: String) { self.title = title; self.value = value }; var body: some View { HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value).monospacedDigit() } }
enum DemoAssessment { static func make() -> MobileExperimentAssessment { let base = [1.0, 0.99, 1.0].map { MobileTelemetryFrame(rpm: 3000, loadKPa: 50, lambda: $0) }; let candidate = [0.93, 0.92, 0.91].map { MobileTelemetryFrame(rpm: 3000, loadKPa: 50, lambda: $0) }; let repeatRun = [0.925, 0.915, 0.905].map { MobileTelemetryFrame(rpm: 3000, loadKPa: 50, lambda: $0) }; return MobileExperimentAssessor.assess(baseline: base, candidate: candidate, repeatRun: repeatRun) } }
