import Foundation
import SwiftData
import SwiftUI

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

    var tint: Color {
        switch self {
        case .money: Color(red: 0.20, green: 0.62, blue: 0.39)
        case .food: Color(red: 0.91, green: 0.36, blue: 0.30)
        case .time: Color(red: 0.39, green: 0.42, blue: 0.86)
        }
    }

    var reasons: [String] {
        switch self {
        case .money: ["好看", "解压", "跟风", "奖励自己", "其他"]
        case .food: ["馋了", "压力大", "无聊", "社交场景", "其他"]
        case .time: ["累了", "逃避", "无聊", "习惯性打开", "其他"]
        }
    }

    var gentleHint: String {
        switch self {
        case .money: "这是需要，还是此刻想被安慰？"
        case .food: "先等等，身体可能只是有点累。"
        case .time: "这段时间，要交给它，还是留给自己？"
        }
    }

    var cooldownSeconds: TimeInterval {
        switch self {
        case .money: 24 * 60 * 60
        case .food: 10 * 60
        case .time: 15 * 60
        }
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
        case .gaveIn: "观察中"
        }
    }
}

@Model
final class ResistRecord {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var title: String
    var value: Double
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
}

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    var typeRaw: String
    var targetValue: Double
    var deadline: Date?
    var icon: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        type: ResistType,
        targetValue: Double,
        deadline: Date? = nil,
        icon: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.typeRaw = type.rawValue
        self.targetValue = targetValue
        self.deadline = deadline
        self.icon = icon
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
