import Foundation
import SwiftData

/// Everything a backup holds: the user's records and goals, and the few choices that are kept in
/// settings rather than in the database. The food table is not in it — every install has its own.
///
/// Restoring only ever adds what a device does not have. It never changes or removes anything that is
/// already there, so a restore cannot make things worse.
struct BackupArchive: Codable {
    static let currentVersion = 1

    /// New for every backup written; a device remembers the last one it wrote or took in, which is how
    /// it can tell a backup that came from somewhere else.
    var id: UUID
    var version: Int
    var createdAt: Date
    var deviceName: String
    var records: [Record]
    var goals: [GoalEntry]
    var settings: Settings

    struct Record: Codable {
        var id: UUID
        var typeRaw: String
        var title: String
        var value: Double
        var hasEstimatedValue: Bool
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
    }

    struct GoalEntry: Codable {
        var id: UUID
        var title: String
        var typeRaw: String
        var targetValue: Double
        var deadline: Date?
        var icon: String
        var customImagePath: String?
        var createdAt: Date
        var achievedAt: Date?
    }

    /// Choices that shape the numbers: which goal comes first, and how long things cool down.
    struct Settings: Codable, Equatable {
        /// `ResistType` raw value → goal id.
        var focusGoalIds: [String: String]
        /// `ResistType` raw value → seconds, only where the user changed it.
        var cooldownSeconds: [String: Double]

        static func current(defaults: UserDefaults = .standard) -> Settings {
            var focus: [String: String] = [:]
            for (type, id) in GoalFocus.stored() {
                focus[type.rawValue] = id.uuidString
            }
            var cooldowns: [String: Double] = [:]
            for type in ResistType.allCases {
                let seconds = defaults.double(forKey: AppSettings.cooldownKey(for: type))
                if AppSettings.cooldownRange.contains(seconds) { cooldowns[type.rawValue] = seconds }
            }
            return Settings(focusGoalIds: focus, cooldownSeconds: cooldowns)
        }

        func apply(defaults: UserDefaults = .standard) {
            for type in ResistType.allCases {
                if let seconds = cooldownSeconds[type.rawValue], AppSettings.cooldownRange.contains(seconds) {
                    defaults.set(seconds, forKey: AppSettings.cooldownKey(for: type))
                }
                if let raw = focusGoalIds[type.rawValue] {
                    defaults.set(raw, forKey: "focusGoalId.\(type.rawValue)")
                }
            }
            defaults.set(defaults.integer(forKey: GoalFocus.versionKey) + 1, forKey: GoalFocus.versionKey)
        }
    }

    init(records: [ResistRecord], goals: [Goal], settings: Settings, deviceName: String, now: Date = .now) {
        id = UUID()
        version = Self.currentVersion
        createdAt = now
        self.deviceName = deviceName
        self.settings = settings
        self.records = records.map { record in
            Record(
                id: record.id, typeRaw: record.typeRaw, title: record.title, value: record.value,
                hasEstimatedValue: record.hasEstimatedValue, unitRaw: record.unitRaw, statusRaw: record.statusRaw,
                reason: record.reason, createdAt: record.createdAt, resolvedAt: record.resolvedAt,
                cooldownUntil: record.cooldownUntil, enteredCooldown: record.enteredCooldown, note: record.note,
                goalId: record.goalId, foodNutritionItemId: record.foodNutritionItemId,
                foodSourceName: record.foodSourceName, foodSourceVersion: record.foodSourceVersion,
                foodServingGrams: record.foodServingGrams, foodEnergyKcalPer100g: record.foodEnergyKcalPer100g,
                propTemplateId: record.propTemplateId, propIconKeyRaw: record.propIconKeyRaw,
                customImagePath: record.customImagePath
            )
        }
        self.goals = goals.map { goal in
            GoalEntry(
                id: goal.id, title: goal.title, typeRaw: goal.typeRaw, targetValue: goal.targetValue,
                deadline: goal.deadline, icon: goal.icon, customImagePath: goal.customImagePath,
                createdAt: goal.createdAt, achievedAt: goal.achievedAt
            )
        }
    }

    var isEmpty: Bool {
        records.isEmpty && goals.isEmpty
    }

    /// The photos this backup refers to, as paths relative to the app's Documents folder.
    var imagePaths: [String] {
        Array(Set(records.compactMap(\.customImagePath) + goals.compactMap(\.customImagePath))).sorted()
    }

    /// The same for two backups with the same contents, whenever and wherever they were written, so a
    /// device can skip writing one that would say nothing new.
    var fingerprint: String {
        var copy = self
        copy.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        copy.createdAt = Date(timeIntervalSinceReferenceDate: 0)
        copy.deviceName = ""
        copy.records.sort { $0.id.uuidString < $1.id.uuidString }
        copy.goals.sort { $0.id.uuidString < $1.id.uuidString }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(copy) else { return UUID().uuidString }
        // A plain, stable hash; this is for telling "same" from "different", not for security.
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in data {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    func encoded() throws -> Data {
        // Dates are written as plain numbers so they come back exactly as they were.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        try JSONDecoder().decode(BackupArchive.self, from: data)
    }

    struct MergeResult: Equatable {
        var records: Int
        var goals: Int
    }

    /// Adds the records and goals this device does not have. Settings come along only onto a device
    /// that had nothing, since otherwise the device's own choices are the newer ones.
    @MainActor
    func merge(into context: ModelContext, defaults: UserDefaults = .standard) throws -> MergeResult {
        let existingRecords = try context.fetch(FetchDescriptor<ResistRecord>())
        let existingGoals = try context.fetch(FetchDescriptor<Goal>())
        let wasEmpty = existingRecords.isEmpty && existingGoals.isEmpty
        let recordIds = Set(existingRecords.map(\.id))
        let goalIds = Set(existingGoals.map(\.id))
        var result = MergeResult(records: 0, goals: 0)

        for entry in goals where !goalIds.contains(entry.id) {
            context.insert(Goal(
                id: entry.id, title: entry.title, type: ResistType(rawValue: entry.typeRaw) ?? .money,
                targetValue: entry.targetValue, deadline: entry.deadline, icon: entry.icon,
                customImagePath: entry.customImagePath, createdAt: entry.createdAt, achievedAt: entry.achievedAt
            ))
            result.goals += 1
        }

        for entry in records where !recordIds.contains(entry.id) {
            let record = ResistRecord(
                id: entry.id, type: ResistType(rawValue: entry.typeRaw) ?? .money, title: entry.title,
                value: entry.value, hasEstimatedValue: entry.hasEstimatedValue,
                status: ResistStatus(rawValue: entry.statusRaw) ?? .resisted, reason: entry.reason,
                createdAt: entry.createdAt, resolvedAt: entry.resolvedAt, cooldownUntil: entry.cooldownUntil,
                enteredCooldown: entry.enteredCooldown, note: entry.note, goalId: entry.goalId,
                foodNutritionItemId: entry.foodNutritionItemId, foodSourceName: entry.foodSourceName,
                foodSourceVersion: entry.foodSourceVersion, foodServingGrams: entry.foodServingGrams,
                foodEnergyKcalPer100g: entry.foodEnergyKcalPer100g, propTemplateId: entry.propTemplateId,
                customImagePath: entry.customImagePath
            )
            record.propIconKeyRaw = entry.propIconKeyRaw
            context.insert(record)
            result.records += 1
        }

        try context.save()
        if wasEmpty {
            settings.apply(defaults: defaults)
        }
        return result
    }
}
