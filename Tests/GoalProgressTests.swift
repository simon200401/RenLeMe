import Foundation
import SwiftData
import SwiftUI

// Palette dependencies of PropTemplates; the statistics tests do not render UI.
extension Color {
    static let punchBlue = Color.blue
    static let punchPink = Color.pink
    static let punchYellow = Color.yellow
    static let punchGreen = Color.green
}

@main
@MainActor
struct GoalProgressTests {
    static func main() throws {
        let container = try ModelContainer(
            for: Goal.self, ResistRecord.self, FoodNutritionItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let money = Goal(title: "旅行", type: .money, targetValue: 1000, icon: "wallet")
        let otherMoney = Goal(title: "相机", type: .money, targetValue: 3000, icon: "camera")
        let food = Goal(title: "少喝奶茶", type: .food, targetValue: 900, icon: "milkTea")
        let time = Goal(title: "拿回时间", type: .time, targetValue: 120, icon: "clock")
        let goals = [money, food, time]
        for goal in goals { context.insert(goal) }


        let foodAhead = record(.food, value: 2000, goalId: food.id)
        let linked = record(.money, value: 100, goalId: money.id)
        let unlinked = record(.money, value: 200)
        let cooling = record(.money, value: 50, status: .pending, goalId: money.id)
        let gaveIn = record(.money, value: 75, status: .gaveIn, goalId: money.id)
        let unknown = record(.money, value: 500, goalId: money.id, estimated: false)
        let mismatched = record(.food, value: 420, goalId: money.id)
        expect(StatsCalculator.suggestedGoalId(for: .food, goals: goals, records: []) == food.id,
               "A single same-type goal is still the suggestion")
        expect(StatsCalculator.suggestedGoalId(for: .money, goals: goals + [otherMoney], records: [linked]) == money.id,
               "With several goals the one closest to completion is suggested")
        expect(StatsCalculator.suggestedGoalId(
            for: .money, goals: goals + [otherMoney], records: [record(.money, value: 1000, goalId: money.id)]
        ) == otherMoney.id, "A finished goal is not suggested")
        expect(StatsCalculator.suggestedGoalId(for: .money, goals: [food], records: []) == nil,
               "No suggestion without a goal of that type")
        // Goals of one kind fill one at a time, and what goes past a target passes to the next.
        let pair = [money, otherMoney]
        let big = record(.money, value: 1300, goalId: money.id)
        let spill = GoalLedger(goals: pair, records: [big], preferred: [:])
        expect(spill.value(for: money) == 1000 && spill.value(for: otherMoney) == 300,
               "Whatever passes a target moves on to the next goal")
        expect(spill.isFinished(money) && spill.focusId(for: .money) == otherMoney.id,
               "A finished goal hands over to the next in line")
        let chosen = GoalLedger(goals: pair, records: [linked], preferred: [.money: otherMoney.id])
        expect(chosen.focusId(for: .money) == otherMoney.id && chosen.isFocus(otherMoney) && !chosen.isFocus(money),
               "The chosen goal is the one being saved towards")
        expect(chosen.value(for: money) == 100, "Choosing a goal does not move what is already saved")
        let full = GoalLedger(goals: pair, records: [record(.money, value: 5000, goalId: money.id)], preferred: [:])
        expect(full.value(for: money) + full.value(for: otherMoney) == 5000 && full.focusId(for: .money) == nil,
               "Nothing is lost when every goal is full, and nothing is in line")
        expect(GoalLedger(goals: [money], records: [big], preferred: [:]).focusId(for: .money) == money.id,
               "A single goal keeps receiving records after it is done")

        // Taking a finished goal down to the shelf keeps its amount and stops it receiving records.
        money.achievedAt = .now
        let shelved = GoalLedger(goals: pair, records: [big], preferred: [.money: money.id])
        expect(shelved.value(for: money) == 1000 && shelved.value(for: otherMoney) == 300,
               "A shelved goal keeps what it holds and still passes the rest on")
        expect(shelved.focusId(for: .money) == otherMoney.id && !shelved.canBecomeFocus(money),
               "New records never go to a shelved goal, even a chosen one")
        expect(GoalLedger(goals: [money], records: [big], preferred: [:]).focusId(for: .money) == nil,
               "With only a shelved goal left, nothing is in line")
        expect(pair.active.map(\.id) == [otherMoney.id] && pair.achieved.map(\.id) == [money.id],
               "Lists show goals on the board; the shelf shows the rest")
        money.achievedAt = nil
        expect(GoalLedger(goals: goals, records: [foodAhead], preferred: [:]).value(for: money) == 0,
               "Overflow never crosses between kinds of urge")

        // Insights stay quiet until there is enough to go on.
        let thin = RecordInsights(records: [linked, unlinked])
        expect(thin.peakTime == nil, "Two records are not a pattern")
        let cooledWin = record(.money, value: 10)
        cooledWin.enteredCooldown = true
        let cooledLoss = record(.food, value: 10, status: .gaveIn)
        cooledLoss.enteredCooldown = true
        let insights = RecordInsights(records: [linked, unlinked, cooling, gaveIn, cooledWin, cooledLoss])
        expect(insights.peakTime?.counts.reduce(0, +) == 6, "Every urge is counted by time of day")
        if let peak = insights.peakTime {
            expect(peak.hourCounts.reduce(0, +) == 6, "Every urge lands in an hour of the day")
            expect(abs((peak.curve.max() ?? 0) - 1) < 0.0001 && peak.curve.allSatisfy { $0 >= 0 },
                   "The curve is scaled to its highest point")
            expect((peak.peakIndex * 3..<peak.peakIndex * 3 + 3).contains(peak.peakHour),
                   "The marker sits inside the block named in the title")
        }
        expect(RecordInsights.daysTogether(records: []) == 0 && RecordInsights.daysTogether(records: [linked]) == 1,
               "The first day together is day one")
        expect(RecordInsights.csv(records: [linked], goals: goals).contains("旅行"), "Export names the linked goal")
        expect(AppSettings.durationText(ResistType.money.defaultCooldownSeconds) == "24 小时"
               && AppSettings.durationText(600) == "10 分钟" && AppSettings.durationText(259_200) == "3 天",
               "Cooldown lengths read naturally")
        expect(AppSettings.durationText(45 * 60) == "45 分钟" && AppSettings.durationText(36 * 3600) == "36 小时",
               "Hand-set lengths read naturally too")
        expect(AppSettings.cooldownRange.contains(60) && !AppSettings.cooldownRange.contains(30)
               && !AppSettings.cooldownRange.contains(31 * 86_400), "Hand-set lengths stay between a minute and thirty days")
        let foodRecord = record(.food, value: 420, goalId: food.id)
        let timeRecord = record(.time, value: 30, goalId: time.id)
        for record in [linked, unlinked, cooling, gaveIn, unknown, mismatched, foodRecord, timeRecord] {
            context.insert(record)
        }
        try context.save()

        func value(_ goal: Goal) throws -> Double {
            StatsCalculator.currentValue(for: goal, records: try context.fetch(FetchDescriptor<ResistRecord>()))
        }
        expect(try value(money) == 100, "Only linked resisted records with matching type and a value count")
        expect(try value(food) == 420, "Food calories contribute to the selected food goal")
        expect(try value(time) == 30, "Time remains stored and aggregated in minutes")
        expect(unlinked.goalId == nil, "Old unlinked records remain untouched")

        cooling.status = .resisted
        cooling.resolvedAt = .now
        try context.save()
        expect(try value(money) == 150, "Resolving a linked cooling record increases progress")
        linked.value = 125
        try context.save()
        expect(try value(money) == 175, "Editing the value updates progress")
        linked.status = .gaveIn
        try context.save()
        expect(try value(money) == 50, "Changing to gave-in removes progress")
        unlinked.goalId = money.id
        try context.save()
        expect(try value(money) == 250, "Explicitly linking an old record adds progress")

        context.insert(otherMoney)
        unlinked.goalId = otherMoney.id
        try context.save()
        expect(try value(money) == 50 && value(otherMoney) == 200, "Moving a record never double counts it")
        context.delete(cooling)
        try context.save()
        expect(try value(money) == 0, "Deleting a record removes its contribution")
        // A backup carries everything across, and taking one in only ever adds.
        let archive = BackupArchive(
            records: try context.fetch(FetchDescriptor<ResistRecord>()), goals: try context.fetch(FetchDescriptor<Goal>()),
            settings: .init(focusGoalIds: [:], cooldownSeconds: ["food": 1200]), deviceName: "测试"
        )
        let copy = try BackupArchive.decode(try archive.encoded())
        expect(copy.records.count == archive.records.count && copy.goals.count == archive.goals.count && copy.id == archive.id,
               "A backup reads back as it was written")
        expect(copy.fingerprint == archive.fingerprint, "The same contents have the same fingerprint")
        let fresh = try ModelContainer(
            for: Goal.self, ResistRecord.self, FoodNutritionItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let defaults = UserDefaults(suiteName: "backup-test-\(UUID().uuidString)")!
        let first = try copy.merge(into: fresh.mainContext, defaults: defaults)
        expect(first.records == archive.records.count && first.goals == archive.goals.count,
               "Onto an empty device everything is restored")
        expect(defaults.double(forKey: AppSettings.cooldownKey(for: .food)) == 1200,
               "An empty device takes the backup's settings")
        let again = try copy.merge(into: fresh.mainContext, defaults: defaults)
        expect(again == .init(records: 0, goals: 0), "Restoring twice adds nothing the second time")
        let restoredGoal = try fresh.mainContext.fetch(FetchDescriptor<Goal>()).first { $0.id == money.id }
        let restoredValue = StatsCalculator.currentValue(
            for: restoredGoal!, records: try fresh.mainContext.fetch(FetchDescriptor<ResistRecord>())
        )
        expect(try restoredValue == value(money), "A restored goal has the progress it had")
        let extra = record(.money, value: 5)
        context.insert(extra)
        let later = BackupArchive(
            records: try context.fetch(FetchDescriptor<ResistRecord>()), goals: try context.fetch(FetchDescriptor<Goal>()),
            settings: .init(focusGoalIds: [:], cooldownSeconds: ["food": 300]), deviceName: "测试"
        )
        expect(later.fingerprint != archive.fingerprint, "A new record changes the fingerprint")
        let third = try later.merge(into: fresh.mainContext, defaults: defaults)
        expect(third == .init(records: 1, goals: 0) && defaults.double(forKey: AppSettings.cooldownKey(for: .food)) == 1200,
               "Merging into a device with data adds what is missing and leaves its settings alone")
        context.delete(extra)

        print("PASS: goal ledger and shelf, backup and restore, three value types, saved records, cooling resolution, edits, reassignment, and deletion")
    }

    private static func record(
        _ type: ResistType, value: Double, status: ResistStatus = .resisted,
        goalId: UUID? = nil, estimated: Bool = true
    ) -> ResistRecord {
        ResistRecord(type: type, title: "测试", value: value, hasEstimatedValue: estimated,
                     status: status, reason: "", goalId: goalId)
    }

    private static func expect(_ condition: Bool, _ message: String) {
        precondition(condition, message)
    }
}
