import Foundation
import SwiftData

enum ResistType: String, CaseIterable, Identifiable, Codable {
    case money
    case food
    case time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .money: "金钱"
        case .food: "食物"
        case .time: "时间"
        }
    }

    var assetTitle: String {
        switch self {
        case .money: "省下的钱"
        case .food: "守住的热量"
        case .time: "拿回的时间"
        }
    }

    var fieldTitle: String {
        switch self {
        case .money: "物品名称"
        case .food: "食物名称"
        case .time: "行为名称"
        }
    }

    var valueTitle: String {
        switch self {
        case .money: "金额"
        case .food: "热量"
        case .time: "时长"
        }
    }

    var unit: ValueUnit {
        switch self {
        case .money: .cny
        case .food: .kcal
        case .time: .minute
        }
    }

    var symbolName: String {
        switch self {
        case .money: "yensign.circle.fill"
        case .food: "fork.knife.circle.fill"
        case .time: "clock.circle.fill"
        }
    }

    var reasons: [String] {
        switch self {
        case .money: ["好看", "解压", "跟风", "奖励自己", "其他"]
        case .food: ["馋了", "压力大", "无聊", "社交场景", "其他"]
        case .time: ["累了", "逃避", "无聊", "习惯性打开", "其他"]
        }
    }

    var defaultCooldownSeconds: TimeInterval {
        switch self {
        case .money: 24 * 60 * 60
        case .food: 10 * 60
        case .time: 15 * 60
        }
    }

    /// The lengths offered in settings for this kind of urge.
    var cooldownOptions: [TimeInterval] {
        switch self {
        case .money: [60 * 60, 6 * 60 * 60, 24 * 60 * 60, 3 * 24 * 60 * 60]
        case .food: [5 * 60, 10 * 60, 20 * 60, 30 * 60]
        case .time: [5 * 60, 15 * 60, 30 * 60, 60 * 60]
        }
    }

    /// How long something of this kind waits in the cooldown box: the user's choice, or the default.
    var cooldownSeconds: TimeInterval {
        let chosen = UserDefaults.standard.double(forKey: AppSettings.cooldownKey(for: self))
        return AppSettings.cooldownRange.contains(chosen) ? chosen : defaultCooldownSeconds
    }

    var cooldownDurationText: String {
        AppSettings.durationText(cooldownSeconds)
    }
}

/// Preferences set on the "我的" page.
enum AppSettings {
    static let hapticsKey = "hapticsEnabled"
    static let cooldownReminderKey = "cooldownReminderEnabled"

    /// Any length from a minute to thirty days can be set by hand.
    static let cooldownRange: ClosedRange<TimeInterval> = 60...(30 * 24 * 60 * 60)

    static func cooldownKey(for type: ResistType) -> String {
        "cooldownSeconds.\(type.rawValue)"
    }

    /// Both switches are on until the user turns them off.
    static var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true
    }

    static var cooldownReminderEnabled: Bool {
        UserDefaults.standard.object(forKey: cooldownReminderKey) as? Bool ?? true
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded())
        // A single day reads better as "24 小时".
        if minutes % (24 * 60) == 0, minutes > 24 * 60 { return "\(minutes / (24 * 60)) 天" }
        if minutes % 60 == 0 { return "\(minutes / 60) 小时" }
        return "\(minutes) 分钟"
    }
}

enum ValueUnit: String, Codable {
    case cny
    case kcal
    case minute
}

enum ResistStatus: String, CaseIterable, Identifiable, Codable {
    case resisted
    case pending
    case gaveIn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .resisted: "忍住了"
        case .pending: "冷静箱"
        case .gaveIn: "没忍住"
        }
    }
}

@Model
final class ResistRecord {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var title: String
    var value: Double
    var hasEstimatedValue: Bool = true
    var unitRaw: String
    var statusRaw: String
    var reason: String
    var createdAt: Date
    var resolvedAt: Date?
    var cooldownUntil: Date?
    var enteredCooldown: Bool
    var note: String
    var goalId: UUID?
    var foodNutritionItemId: UUID?
    var foodSourceName: String?
    var foodSourceVersion: String?
    var foodServingGrams: Double?
    var foodEnergyKcalPer100g: Double?
    var propTemplateId: String?
    var propIconKeyRaw: String?
    var customImagePath: String?

    init(
        id: UUID = UUID(),
        type: ResistType,
        title: String,
        value: Double,
        hasEstimatedValue: Bool = true,
        status: ResistStatus,
        reason: String,
        createdAt: Date = .now,
        resolvedAt: Date? = nil,
        cooldownUntil: Date? = nil,
        enteredCooldown: Bool = false,
        note: String = "",
        goalId: UUID? = nil,
        foodNutritionItemId: UUID? = nil,
        foodSourceName: String? = nil,
        foodSourceVersion: String? = nil,
        foodServingGrams: Double? = nil,
        foodEnergyKcalPer100g: Double? = nil,
        propTemplateId: String? = nil,
        propIconKey: PropIconKey? = nil,
        customImagePath: String? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.title = title
        self.value = value
        self.hasEstimatedValue = hasEstimatedValue
        self.unitRaw = type.unit.rawValue
        self.statusRaw = status.rawValue
        self.reason = reason
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
        self.cooldownUntil = cooldownUntil
        self.enteredCooldown = enteredCooldown
        self.note = note
        self.goalId = goalId
        self.foodNutritionItemId = foodNutritionItemId
        self.foodSourceName = foodSourceName
        self.foodSourceVersion = foodSourceVersion
        self.foodServingGrams = foodServingGrams
        self.foodEnergyKcalPer100g = foodEnergyKcalPer100g
        self.propTemplateId = propTemplateId
        self.propIconKeyRaw = propIconKey?.rawValue
        self.customImagePath = customImagePath
    }

    var type: ResistType {
        get { ResistType(rawValue: typeRaw) ?? .money }
        set {
            typeRaw = newValue.rawValue
            unitRaw = newValue.unit.rawValue
        }
    }

    var unit: ValueUnit {
        get { ValueUnit(rawValue: unitRaw) ?? type.unit }
        set { unitRaw = newValue.rawValue }
    }

    var status: ResistStatus {
        get { ResistStatus(rawValue: statusRaw) ?? .resisted }
        set { statusRaw = newValue.rawValue }
    }

    var propIconKey: PropIconKey? {
        get {
            guard let propIconKeyRaw else { return nil }
            return PropIconKey(rawValue: propIconKeyRaw)
        }
        set { propIconKeyRaw = newValue?.rawValue }
    }

    var displayValueText: String {
        hasEstimatedValue ? value.displayValue(for: type) : "待补充"
    }
}

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    var typeRaw: String
    var targetValue: Double
    var deadline: Date?
    var icon: String
    var customImagePath: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        type: ResistType,
        targetValue: Double,
        deadline: Date? = nil,
        icon: String,
        customImagePath: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.typeRaw = type.rawValue
        self.targetValue = targetValue
        self.deadline = deadline
        self.icon = icon
        self.customImagePath = customImagePath
        self.createdAt = createdAt
    }

    var type: ResistType {
        get { ResistType(rawValue: typeRaw) ?? .money }
        set { typeRaw = newValue.rawValue }
    }
}

@Model
final class FoodNutritionItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var aliasesText: String
    var category: String
    var energyKcalPer100g: Double
    var defaultServingName: String?
    var defaultServingGrams: Double?
    var sourceName: String
    var sourceVersion: String
    var sourceFoodId: String?
    var state: String?
    var isVerified: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        aliases: [String] = [],
        category: String,
        energyKcalPer100g: Double,
        defaultServingName: String? = nil,
        defaultServingGrams: Double? = nil,
        sourceName: String,
        sourceVersion: String,
        sourceFoodId: String? = nil,
        state: String? = nil,
        isVerified: Bool,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.aliasesText = aliases.joined(separator: "|")
        self.category = category
        self.energyKcalPer100g = energyKcalPer100g
        self.defaultServingName = defaultServingName
        self.defaultServingGrams = defaultServingGrams
        self.sourceName = sourceName
        self.sourceVersion = sourceVersion
        self.sourceFoodId = sourceFoodId
        self.state = state
        self.isVerified = isVerified
        self.updatedAt = updatedAt
    }

    var aliases: [String] {
        aliasesText
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    var searchableText: String {
        var components = [name, category, sourceName]
        if let state {
            components.append(state)
        }
        components.append(contentsOf: aliases)
        return components.joined(separator: " ").lowercased()
    }

    func calories(for grams: Double) -> Double {
        energyKcalPer100g * grams / 100
    }
}
