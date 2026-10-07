import SwiftData
import SwiftUI
import UIKit

/// Keeps one backup of the user's records, goals and photos in their own iCloud, so deleting the app
/// or moving to a phone that was not restored from a device backup does not lose them. It is a
/// backup, not sync: one file, rewritten when something has changed, read back only when asked.
///
/// The rule that keeps it safe: a device never writes over a backup it has not seen. A backup written
/// somewhere else (a previous install, another phone) is first offered to the user to take in.
@MainActor
final class CloudBackup: ObservableObject {
    static let shared = CloudBackup()

    static let enabledKey = "cloudBackupEnabled"
    private static let acceptedIdKey = "cloudBackupAcceptedId"
    private static let fingerprintKey = "cloudBackupFingerprint"
    private static let lastDateKey = "cloudBackupLastDate"

    enum Availability {
        case unknown
        /// Not signed in to iCloud, or iCloud Drive is off for this app.
        case unavailable
        case available
    }

    @Published private(set) var availability: Availability = .unknown
    @Published private(set) var lastBackupAt: Date?
    /// What is in iCloud right now, as last read.
    @Published private(set) var cloudArchive: BackupArchive?
    /// A backup this device neither wrote nor took in, waiting for the user to say what to do with it.
    @Published var foreign: BackupArchive?
    @Published private(set) var isWorking = false
    @Published var failed = false

    /// Which of the two the user asked for, so only that button shows it is busy.
    enum Job {
        case backingUp
        case restoring
    }

    @Published private(set) var job: Job?
    /// What the last thing the user asked for came to, in a sentence.
    @Published private(set) var outcome: String?

    private let defaults = UserDefaults.standard

    private init() {
        let stamp = defaults.double(forKey: Self.lastDateKey)
        lastBackupAt = stamp > 0 ? Date(timeIntervalSinceReferenceDate: stamp) : nil
    }

    var isEnabled: Bool {
        defaults.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    private var acceptedId: String? {
        defaults.string(forKey: Self.acceptedIdKey)
    }

    // MARK: What the app calls

    /// Looks at what is in iCloud. Run at launch and whenever the app comes to the front.
    func refresh() async {
        guard isEnabled else { return }
        let found = await Task.detached { Files.read() }.value
        availability = found.isAvailable ? .available : .unavailable
        cloudArchive = found.archive
        if let archive = found.archive, !archive.isEmpty, archive.id.uuidString != acceptedId {
            foreign = archive
        }
    }

    /// Writes a backup if there is something new to say. Run when the app leaves the front.
    func backUp(force: Bool = false) async {
        guard isEnabled, !isWorking else { return }
        let context = AppStore.container.mainContext
        guard let records = try? context.fetch(FetchDescriptor<ResistRecord>()),
              let goals = try? context.fetch(FetchDescriptor<Goal>())
        else { return }

        let archive = BackupArchive(
            records: records, goals: goals, settings: .current(), deviceName: UIDevice.current.name
        )
        // An empty device has nothing worth keeping, and must never replace a backup that has.
        guard !archive.isEmpty else { return }
        let fingerprint = archive.fingerprint
        if !force, fingerprint == defaults.string(forKey: Self.fingerprintKey), lastBackupAt != nil { return }

        isWorking = true
        defer { isWorking = false }
        let task = UIApplication.shared.beginBackgroundTask(withName: "cloud-backup")
        defer { UIApplication.shared.endBackgroundTask(task) }

        let accepted = acceptedId
        let outcome = await Task.detached { Files.write(archive, acceptedId: accepted) }.value
        switch outcome {
        case .unavailable:
            availability = .unavailable
        case .foreign(let other):
            availability = .available
            cloudArchive = other
            foreign = other
        case .written:
            availability = .available
            cloudArchive = archive
            lastBackupAt = archive.createdAt
            defaults.set(archive.id.uuidString, forKey: Self.acceptedIdKey)
            defaults.set(fingerprint, forKey: Self.fingerprintKey)
            defaults.set(archive.createdAt.timeIntervalSinceReferenceDate, forKey: Self.lastDateKey)
        case .failed:
            failed = true
        }
    }

    /// Takes a backup in: adds what this device does not have, photos included, and from then on this
    /// device may write over it.
    @discardableResult
    func restore(_ archive: BackupArchive) async -> BackupArchive.MergeResult? {
        isWorking = true
        let paths = archive.imagePaths
        await Task.detached { Files.copyImagesDown(paths) }.value
        let context = AppStore.container.mainContext
        do {
            let added = try archive.merge(into: context)
            // Things that came back still waiting get their reminder back too.
            let pending = (try? context.fetch(FetchDescriptor<ResistRecord>()))?.filter { $0.status == .pending } ?? []
            for record in pending where (record.cooldownUntil ?? .distantPast) > .now {
                CooldownCoordinator.schedule(for: record)
            }
            defaults.set(archive.id.uuidString, forKey: Self.acceptedIdKey)
            foreign = nil
            isWorking = false
            // What is in iCloud now matches this phone, so the next thing to change gets backed up
            // without being mistaken for someone else's.
            await backUp(force: true)
            return added
        } catch {
            isWorking = false
            failed = true
            return nil
        }
    }

    /// "现在备份" on the backup page.
    func backUpNow() async {
        job = .backingUp
        outcome = nil
        let before = lastBackupAt
        await backUp(force: true)
        job = nil
        if foreign != nil {
            outcome = "iCloud 里有一份别处的备份，先决定要不要恢复它。"
        } else if lastBackupAt != before {
            outcome = "已备份。"
        } else if availability == .unavailable {
            outcome = "没有登录 iCloud，或没有打开 iCloud 云盘。"
        } else if !failed {
            outcome = "还没有可以备份的内容。"
        }
    }

    /// "从备份恢复" on the backup page.
    func restoreNow(_ archive: BackupArchive) async {
        job = .restoring
        outcome = nil
        let added = await restore(archive)
        job = nil
        guard let added else { return }
        outcome = added.records == 0 && added.goals == 0
            ? "这台手机上已经都有了，没有需要补的。"
            : "补上了 \(added.records) 条记录、\(added.goals) 个目标。"
    }

    /// Leaves the backup alone for now; this device's own data will replace it at the next backup.
    func decline(_ archive: BackupArchive) {
        defaults.set(archive.id.uuidString, forKey: Self.acceptedIdKey)
        foreign = nil
    }

    func setEnabled(_ enabled: Bool) async {
        defaults.set(enabled, forKey: Self.enabledKey)
        objectWillChange.send()
        if enabled {
            await refresh()
            if foreign == nil { await backUp(force: true) }
        }
    }

    var statusText: String {
        if !isEnabled { return "已关闭" }
        switch availability {
        case .unavailable: return "没有登录 iCloud，或没有打开 iCloud 云盘"
        case .unknown, .available:
            guard let lastBackupAt else { return availability == .available ? "还没有备份" : "正在检查" }
            return "上次备份 \(Self.dateText(lastBackupAt))"
        }
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "今天 HH:mm" : "M月d日 HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Files, off the main thread

    private enum Files {
        enum WriteOutcome {
            case unavailable
            case foreign(BackupArchive)
            case written
            case failed
        }

        private static let fileName = "backup.json"
        private static let previousName = "backup.previous.json"

        /// `…/Documents/Backup` in the app's iCloud container; nil when iCloud is not there to use.
        private static func directory() -> URL? {
            #if DEBUG
            // Lets the backup be exercised in the simulator, which has no iCloud account.
            if let path = UserDefaults.standard.string(forKey: "cloudBackupDebugDirectory") {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
            #endif
            guard FileManager.default.ubiquityIdentityToken != nil,
                  let container = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            else { return nil }
            return container.appendingPathComponent("Documents/Backup", isDirectory: true)
        }

        private static var documents: URL? {
            try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }

        static func read() -> (isAvailable: Bool, archive: BackupArchive?) {
            guard let directory = directory() else { return (false, nil) }
            return (true, readArchive(in: directory))
        }

        private static func readArchive(in directory: URL) -> BackupArchive? {
            let url = directory.appendingPathComponent(fileName)
            // On a new install the file may be known to iCloud but not on the phone yet.
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
            for _ in 0..<20 where !FileManager.default.isReadableFile(atPath: url.path) {
                guard isInCloud(url) else { break }
                Thread.sleep(forTimeInterval: 0.5)
            }
            var result: BackupArchive?
            var coordinationError: NSError?
            NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readURL in
                guard let data = try? Data(contentsOf: readURL) else { return }
                result = try? BackupArchive.decode(data)
            }
            return result
        }

        /// True while iCloud knows of the file, downloaded or not.
        private static func isInCloud(_ url: URL) -> Bool {
            if FileManager.default.fileExists(atPath: url.path) { return true }
            let placeholder = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).icloud")
            return FileManager.default.fileExists(atPath: placeholder.path)
        }

        static func write(_ archive: BackupArchive, acceptedId: String?) -> WriteOutcome {
            guard let directory = directory() else { return .unavailable }
            let manager = FileManager.default
            do {
                try manager.createDirectory(at: directory, withIntermediateDirectories: true)
                let url = directory.appendingPathComponent(fileName)

                if let existing = readArchive(in: directory) {
                    if !existing.isEmpty, existing.id.uuidString != acceptedId {
                        return .foreign(existing)
                    }
                    // Yesterday's backup is kept beside today's, in case today's turns out wrong.
                    if !Calendar.current.isDate(existing.createdAt, inSameDayAs: archive.createdAt) {
                        let previous = directory.appendingPathComponent(previousName)
                        try? manager.removeItem(at: previous)
                        try? manager.copyItem(at: url, to: previous)
                    }
                }

                copyImagesUp(archive.imagePaths, to: directory)

                let data = try archive.encoded()
                var coordinationError: NSError?
                var writeError: Error?
                NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { writeURL in
                    do {
                        try data.write(to: writeURL, options: .atomic)
                    } catch {
                        writeError = error
                    }
                }
                if coordinationError != nil || writeError != nil { return .failed }
                return .written
            } catch {
                return .failed
            }
        }

        private static func copyImagesUp(_ paths: [String], to directory: URL) {
            guard let documents else { return }
            let manager = FileManager.default
            for path in paths {
                let source = documents.appendingPathComponent(path)
                let target = directory.appendingPathComponent("images").appendingPathComponent(path)
                guard manager.fileExists(atPath: source.path), !isInCloud(target) else { continue }
                try? manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? manager.copyItem(at: source, to: target)
            }
        }

        static func copyImagesDown(_ paths: [String]) {
            guard let directory = directory(), let documents else { return }
            let manager = FileManager.default
            for path in paths {
                let source = directory.appendingPathComponent("images").appendingPathComponent(path)
                let target = documents.appendingPathComponent(path)
                guard !manager.fileExists(atPath: target.path) else { continue }
                try? manager.startDownloadingUbiquitousItem(at: source)
                for _ in 0..<20 where !manager.isReadableFile(atPath: source.path) {
                    guard isInCloud(source) else { break }
                    Thread.sleep(forTimeInterval: 0.5)
                }
                try? manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? manager.copyItem(at: source, to: target)
            }
        }
    }
}

/// "备份与恢复" under 我的 → 数据与帮助.
struct CloudBackupView: View {
    @ObservedObject private var backup = CloudBackup.shared

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PunchyCard(fill: .cardBackground, cornerRadius: 24, padding: 16) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("自动备份到 iCloud")
                                        .font(.rounded(17, weight: .black))
                                        .foregroundStyle(Color.ink)
                                    Text(backup.statusText)
                                        .font(.rounded(13, weight: .bold))
                                        .foregroundStyle(Color.secondaryInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 8)

                                Toggle("自动备份到 iCloud", isOn: Binding(
                                    get: { backup.isEnabled },
                                    set: { enabled in Task { await backup.setEnabled(enabled) } }
                                ))
                                .labelsHidden()
                                .tint(Color.punchGreen)
                                .accessibilityIdentifier("cloudBackupDetailToggle")
                            }

                            if backup.isEnabled, backup.availability == .available {
                                actionButton(backup.job == .backingUp ? "正在备份…" : "现在备份", isPrimary: true, isBusy: backup.job == .backingUp) {
                                    Task { await backup.backUpNow() }
                                }
                                .accessibilityIdentifier("cloudBackupNowButton")

                                if let archive = backup.cloudArchive, !archive.isEmpty {
                                    actionButton(backup.job == .restoring ? "正在恢复…" : "从备份恢复", isPrimary: false, isBusy: backup.job == .restoring) {
                                        Task { await backup.restoreNow(archive) }
                                    }
                                    .accessibilityIdentifier("cloudBackupRestoreButton")
                                }

                                if let outcome = backup.outcome {
                                    Text(outcome)
                                        .font(.rounded(13, weight: .black))
                                        .foregroundStyle(Color.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    if let archive = backup.cloudArchive, !archive.isEmpty {
                        Text("iCloud 里的备份：\(CloudBackup.dateText(archive.createdAt))，来自“\(archive.deviceName)”，\(archive.records.count) 条记录、\(archive.goals.count) 个目标。")
                            .font(.rounded(13, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 6)
                    }

                    Text("记录、目标和你拍的照片会存一份到你自己的 iCloud，我们看不到。删掉 App 重装，或者换了新手机，打开时会问你要不要恢复。恢复只会补上这台手机没有的，不会改动或删除已有的。")
                        .font(.rounded(13, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 6)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
            .appScrollDefaults()
        }
        .navigationTitle("备份与恢复")
        .navigationBarTitleDisplayMode(.inline)
        .task { await backup.refresh() }
        .alert("没有成功，请稍后再试", isPresented: $backup.failed) {
            Button("知道了", role: .cancel) {}
        }
    }

    /// While one of them is at work the other waits, greyed; the one at work stays lit and says so.
    private func actionButton(_ title: String, isPrimary: Bool, isBusy: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.rounded(16, weight: .black))
                .foregroundStyle(isPrimary ? Color.white : .punchBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isPrimary ? Color.punchBlack : Color.punchBlack.opacity(0.07))
                .clipShape(Capsule())
        }
        .buttonStyle(PressableScaleStyle())
        .disabled(backup.job != nil || backup.isWorking)
        .opacity(backup.job != nil && !isBusy ? 0.4 : 1)
    }
}
