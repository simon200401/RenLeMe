import Foundation

/// 小忍 grows with the total number of resisted impulses. It never shrinks and never depends on
/// streaks, so staying away for a while costs nothing.
struct MascotGrowth: Equatable {
    struct Stage: Equatable {
        let threshold: Int
        let title: String
        let symbolName: String?
    }

    static let stages = [
        Stage(threshold: 0, title: "小忍", symbolName: nil),
        Stage(threshold: 3, title: "发芽", symbolName: "leaf.fill"),
        Stage(threshold: 10, title: "开花", symbolName: "camera.macro"),
        Stage(threshold: 25, title: "闪亮", symbolName: "star.fill"),
        Stage(threshold: 50, title: "戴冠", symbolName: "crown.fill"),
        Stage(threshold: 100, title: "传说", symbolName: "trophy.fill")
    ]

    let resistedCount: Int

    init(resistedCount: Int) {
        self.resistedCount = max(resistedCount, 0)
    }

    init(records: [ResistRecord]) {
        self.init(resistedCount: records.filter { $0.status == .resisted }.count)
    }

    /// 1-based, so the first stage reads as Lv.1.
    var level: Int {
        (Self.stages.lastIndex { $0.threshold <= resistedCount } ?? 0) + 1
    }

    var stage: Stage {
        Self.stages[level - 1]
    }

    var nextStage: Stage? {
        level < Self.stages.count ? Self.stages[level] : nil
    }

    var remainingToNextStage: Int? {
        nextStage.map { $0.threshold - resistedCount }
    }

    var progressToNextStage: Double {
        guard let nextStage else { return 1 }
        let span = nextStage.threshold - stage.threshold
        return Double(resistedCount - stage.threshold) / Double(max(span, 1))
    }
}
