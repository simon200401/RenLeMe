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

        for type in ResistType.allCases {
            let expected = goals.first { $0.type == type }!
            expect(StatsCalculator.defaultGoalId(for: type, goals: goals) == expected.id,
                   "A single same-type goal is selected by default")
        }
        expect(StatsCalculator.defaultGoalId(for: .money, goals: []) == nil, "No default without a goal")
        expect(StatsCalculator.defaultGoalId(for: .money, goals: goals + [otherMoney]) == nil,
               "Multiple same-type goals require a choice")

        let linked = record(.money, value: 100, goalId: StatsCalculator.defaultGoalId(for: .money, goals: goals))
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
        // Insights stay quiet until there is enough to go on.
        let thin = RecordInsights(records: [linked, unlinked])
        expect(thin.peakTime == nil && thin.typeRates == nil && thin.cooldownEffect == nil,
               "Two records are not a pattern")
        expect(thin.topItem?.title == "测试" && thin.topItem?.count == 2, "A repeated item is the one wanted most")
        expect(RecordInsights(records: [linked]).topItem == nil, "One mention is not a favourite")
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
        let byType = insights.peakTime?.typeCounts.reduce(into: [ResistType: Int]()) { total, block in
            for (type, count) in block { total[type, default: 0] += count }
        }
        expect(byType?[.money] == 5 && byType?[.food] == 1, "Time-of-day blocks keep the kind of urge")
        let moneyRate = insights.typeRates?.first { $0.type == .money }
        expect(moneyRate?.resisted == 3 && moneyRate?.decided == 4, "Pending records are left out of the rate")
        expect(insights.cooldownEffect?.resisted == 1 && insights.cooldownEffect?.decided == 2,
               "Cooldown effect only looks at records that waited")
        expect(RecordInsights.daysTogether(records: []) == 0 && RecordInsights.daysTogether(records: [linked]) == 1,
               "The first day together is day one")
        expect(RecordInsights.csv(records: [linked], goals: goals).contains("旅行"), "Export names the linked goal")
        expect(AppSettings.durationText(ResistType.money.defaultCooldownSeconds) == "24 小时"
               && AppSettings.durationText(600) == "10 分钟" && AppSettings.durationText(259_200) == "3 天",
               "Cooldown lengths read naturally")
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
        print("PASS: default goal selection, three value types, saved records, cooling resolution, edits, reassignment, and deletion")
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
