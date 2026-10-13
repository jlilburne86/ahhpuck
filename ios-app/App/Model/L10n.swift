import Foundation

/// Port of `ahhpuck-i18n.js` `t()`. The prototype keys strings on their English text and
/// translates every rendered value; this does the same. The fixed strings live in
/// `Resources/ja.lproj/Localizable.strings` (generated from the catalog), and strings with
/// numbers in them go through `rules`, the catalog's `rx` table.
enum L10n {
    enum Language: String { case en = "EN", ja = "JA" }

    private static let jaBundle: Bundle? = Bundle.main.path(forResource: "ja", ofType: "lproj").flatMap(Bundle.init(path:))
    private static let missing = "\u{0}__missing__"

    static func ja(_ key: String) -> String? {
        guard let bundle = jaBundle else { return nil }
        let v = bundle.localizedString(forKey: key, value: missing, table: nil)
        return v == missing ? nil : v
    }

    static func t(_ s: String, _ lang: Language) -> String {
        guard lang == .ja else { return s }
        // Keep leading/trailing whitespace, translate the trimmed core (as the JS does).
        let lead = String(s.prefix { $0.isWhitespace })
        let rest = s.dropFirst(lead.count)
        let trail = String(rest.reversed().prefix { $0.isWhitespace }.reversed())
        let core = String(rest.dropLast(trail.count))
        if core.isEmpty { return s }
        if let v = ja(core) { return lead + v + trail }
        for rule in rules {
            if let m = match(rule.pattern, core, caseInsensitive: rule.caseInsensitive), let r = rule.make(m) {
                return lead + r + trail
            }
        }
        return s
    }

    private struct Rule {
        let pattern: String
        var caseInsensitive = false
        let make: ([String]) -> String?
    }

    private static func lamJa(_ x: String) -> String { x.lowercased().contains("lambda") ? "ラムダ" : "空燃比" }

    private static let rules: [Rule] = [
        Rule(pattern: #"^TIP (\d) OF 3$"#) { "ガイド \($0[1]) / 3" },
        Rule(pattern: #"^(\d) to clear · proposals locked$"#) { "残り\($0[1])件 · 提案はロック中" },
        Rule(pattern: #"^(\d+) of (\d+) terms$"#) { "\($0[2])語中\($0[1])語" },
        Rule(pattern: #"^USED ON (.+)$"#) { "使用画面: \($0[1])" },
        Rule(pattern: #"^STEP (\d+) OF 7$"#) { "ステップ \($0[1]) / 7" },
        Rule(pattern: #"^(\d)/7 KNOWN$"#) { "\($0[1])/7 確認済み" },
        Rule(pattern: #"^(\d+) unknown fields? block proposals until confirmed\.$"#) { "不明な項目が\($0[1])件あるため、確認されるまで提案はできません。" },
        Rule(pattern: #"^(\d+) manual checks? left$"#) { "手動チェック 残り\($0[1])件" },
        Rule(pattern: #"^Open each concern to continue \((\d)/4\)$"#) { "すべての懸念事項を開いてください（\($0[1])/4）" },
        Rule(pattern: #"^(\d+) confirmations left$"#) { "確認 残り\($0[1])件" },
        Rule(pattern: #"^Tick at least 2 checks \((\d)/2\)\.$"#) { "2項目以上チェックしてください（\($0[1])/2）。" },
        Rule(pattern: #"^(\d+) SHOWN$"#) { "\($0[1])件表示" },
        Rule(pattern: #"^LAST (.+) · ([\d.]+) S AGO$"#) { "最終値 \($0[1]) · \($0[2])秒前" },
        Rule(pattern: #"^LAST (.+)$"#) { "最終値 \($0[1])" },
        Rule(pattern: #"^([\d.]+) S OLD$"#) { "\($0[1])秒前" },
        Rule(pattern: #"^([\d.]+) s$"#) { "\($0[1])秒" },
        Rule(pattern: #"^< 0\.1 s$"#) { _ in "0.1秒未満" },
        Rule(pattern: #"^TARGET (.+)$"#) { "目標 \($0[1])" },
        Rule(pattern: #"^Avg (lambda|afr) error$"#, caseInsensitive: true) { "平均\(lamJa($0[1]))誤差" },
        Rule(pattern: #"^(\d) of 7 landed in range$"#) { "7項目中\($0[1])項目が予測範囲内" },
        Rule(pattern: #"^! NEAR (\d+)% LIMIT$"#) { "! 上限\($0[1])%に接近" },
        Rule(pattern: #"^ABS (LAMBDA|AFR) ERROR · %$"#) { "\(lamJa($0[1]))誤差（絶対値） · %" },
        Rule(pattern: #"^(\d+) sel$"#) { "\($0[1]) 選択" },
        Rule(pattern: #"^(.+) error$"#) { m in ja(m[1]).map { $0 + "誤差" } },
        Rule(pattern: #"^EXP-0(\d) · ([\d.]+%)$"#) { "EXP-0\($0[1]) · \($0[2])" },
        Rule(pattern: #"^BASE · ([\d.]+%)$"#) { "基準 · \($0[1])" },
        Rule(pattern: #"^NEXT · (.+)$"#) { "次回 · \($0[1])" },
    ]

    private static func match(_ pattern: String, _ s: String, caseInsensitive: Bool) -> [String]? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : []),
              let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else { return nil }
        return (0..<m.numberOfRanges).map { i in
            Range(m.range(at: i), in: s).map { String(s[$0]) } ?? ""
        }
    }
}
