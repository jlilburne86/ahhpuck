import SwiftUI
import UIKit

/// S31 · Session detail & export — file list with hashes, operator notes, and Export
/// (a zip handed to the iOS share sheet; nothing leaves the phone unless the user shares it).
struct S31View: View {
    @Environment(AppModel.self) private var app
    @State private var share: DShareItem?
    @State private var exportError: String?

    static let files: [(n: String, h: String, s: String)] = [
        ("profile.json", "a91c…", "2 KB"), ("baseline.raw", "3f9a…", "1.2 MB"), ("baseline.jsonl", "77b2…", "840 KB"),
        ("candidate.raw", "81d0…", "1.1 MB"), ("candidate-repeat.jsonl", "a6e2…", "790 KB"), ("assessment.json", "c0d4…", "6 KB"),
        ("approval.json", "5e18…", "3 KB"), ("operator-notes.md", "02ab…", "1 KB"),
    ]
    static let notes = "Pull 2 hit traffic at 5.2k, so it was partly 2nd gear. Repeat needed."

    var body: some View {
        PhoneScreen(tab: .runs, status: "OFFLINE", statusStyle: .dim) {
            ScreenHeader(title: app.persistedRuns.isEmpty ? "Session 0412" : "Evidence export",
                         subtitle: app.persistedRuns.isEmpty
                            ? "13 OCT · EXP-04 · 8 FILES · LOCAL ONLY"
                            : "\(app.persistedRuns.count) RUNS · REAL CAPTURES · LOCAL ONLY")

            VStack(spacing: 0) {
                ForEach(displayFiles, id: \.n) { f in
                    HStack(spacing: 8) {
                        DT(f.n, .mono, 12).frame(maxWidth: .infinity, alignment: .leading)
                        DT(f.h, .mono, 10).foregroundStyle(AP.label).frame(width: 70, alignment: .leading)
                        DT(app.tr(f.s), .mono, 11).foregroundStyle(AP.text3).frame(width: 54, alignment: .trailing)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .padding(.bottom, 1)
                    .overlay(alignment: .bottom) { DDivider() }
                }
            }
            .padding(1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .outlined(AP.border, radius: 12)
            .block(top: 12)

            VStack(alignment: .leading, spacing: 8) {
                DT(app.tr("OPERATOR NOTES"), .mono, 10).foregroundStyle(AP.label)
                DT(app.tr(app.persistedRuns.isEmpty ? S31View.notes : "Raw frames and derived summaries stay on this device. Export is read-only; ECU writes are never included."), .sans, 13, lh: 1.45).foregroundStyle(AP.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .apCard()
            .block()

            if app.exported {
                DT(app.tr("session-0412.zip · 3.9 MB · ready to share"), .sans, 13, 600)
                    .foregroundStyle(AP.ink)
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AP.green))
                    .block()
            }
            if let exportError {
                DT(exportError, .mono, 10).foregroundStyle(AP.red).block()
            }

            Spacer(minLength: 0)
            PrimaryButton(label: "Export bundle") { export() }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 16)
            Spacer(minLength: 0)
        }
        .sheet(item: $share) { item in
            DShareSheet(items: [item.url]).ignoresSafeArea()
        }
    }

    private var displayFiles: [(n: String, h: String, s: String)] {
        guard !app.persistedRuns.isEmpty else { return S31View.files }
        let runFiles = app.persistedRuns.map { run in
            (n: "run-\(run.id.uuidString.prefix(8)).json",
             h: "stored",
             s: "\(run.frames.count) frames")
        }
        let hasAssessment = app.persistedComparison != nil
        return runFiles + (hasAssessment ? [(n: "assessment.json", h: "derived", s: "read-only")] : [])
            + [(n: "manifest.json", h: "derived", s: "read-only")]
    }

    /// Writes the session bundle to a temporary folder and zips it with the system archiver.
    private func export() {
        do {
            let url = try S31View.makeBundle(runs: app.persistedRuns)
            exportError = nil
            app.exported = true
            share = DShareItem(url: url)
        } catch {
            // Never hide a failed export: say so on screen and in the log.
            exportError = "EXPORT FAILED · \(error.localizedDescription)"
            NSLog("S31 export failed: \(error)")
        }
    }

    static func makeBundle(runs: [MobileRunRecord] = []) throws -> URL {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("export-\(UUID().uuidString)")
        let dir = root.appendingPathComponent("session-0412")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        if runs.isEmpty {
            for f in files {
                let body = f.n == "operator-notes.md" ? notes + "\n" : "\(f.n) · \(f.h) · demo placeholder (\(f.s))\n"
                try Data(body.utf8).write(to: dir.appendingPathComponent(f.n))
            }
        } else {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            for run in runs {
                let data = try encoder.encode(run)
                try data.write(to: dir.appendingPathComponent("run-\(run.id.uuidString).json"), options: .atomic)
            }
            if let baseline = runs.first(where: { $0.kind == .baseline }),
               let candidate = runs.first(where: { $0.kind == .candidate }) {
                let repeatRun = runs.first(where: { $0.kind == .repeatRun })
                let assessment = MobileRunComparison(baseline: baseline, candidate: candidate, repeatRun: repeatRun)
                try encoder.encode(assessment).write(to: dir.appendingPathComponent("assessment.json"), options: .atomic)
            }
            let manifest = [
                "runCount": String(runs.count),
                "exportedAt": ISO8601DateFormatter().string(from: Date()),
                "writeAuthorization": "never",
                "source": "AhhPuck local evidence workspace"
            ]
            try encoder.encode(manifest).write(to: dir.appendingPathComponent("manifest.json"), options: .atomic)
        }
        // NSFileCoordinator's .forUploading read of a directory yields a zip archive of it.
        var zipped: URL?
        var coordError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(readingItemAt: dir, options: .forUploading, error: &coordError) { tmp in
            let out = root.appendingPathComponent("session-0412.zip")
            do { try fm.copyItem(at: tmp, to: out); zipped = out } catch { copyError = error }
        }
        if let coordError { throw coordError }
        if let copyError { throw copyError }
        guard let zipped else { throw CocoaError(.fileWriteUnknown) }
        return zipped
    }
}

struct DShareItem: Identifiable { let url: URL; var id: String { url.absoluteString } }

/// UIActivityViewController for the export zip.
struct DShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
