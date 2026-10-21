/// What a Release build shows. Prototype controls (simulate, reset, preview toggles) and the
/// proposal/approval flow (S15–S18) are DEBUG-only until live FC-03 data drives them.
enum Features {
    #if DEBUG
    static let prototypeControls = true
    static let proposals = true
    #else
    static let prototypeControls = false
    static let proposals = false
    #endif
}
