import SwiftData
import SwiftUI

struct HistoryRecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]

    @State private var typeFilter: RecordTypeFilter = .all
    @State private var statusFilter: RecordStatusFilter = .all

    private var filteredRecords: [ResistRecord] {
        records.filter { record in
            typeFilter.matches(record) && statusFilter.matches(record)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filters

                    if filteredRecords.isEmpty {
                        PunchyCard(fill: .cardBackground) {
                            EmptyStateView(title: "没有符合条件的记录", message: "换个筛选条件看看，或者下一次冲动来临时先记下来。", systemImage: "tray")
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredRecords) { record in
                                NavigationLink {
                                    RecordDetailView(record: record)
                                } label: {
                                    RecordRow(record: record)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        LocalImageStore.delete(record.customImagePath)
                                        modelContext.delete(record)
                                    } label: {
                                        Label("删除记录", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filters: some View {
        PunchyCard(fill: .cream, cornerRadius: 28, padding: 14) {
            VStack(spacing: 12) {
                FilterRow(title: "类型", selection: $typeFilter, options: RecordTypeFilter.allCases)
                FilterRow(title: "状态", selection: $statusFilter, options: RecordStatusFilter.allCases)
            }
        }
    }
}

private struct FilterRow<Option: CaseIterable & Identifiable & Hashable & TitledFilter>: View where Option.AllCases: RandomAccessCollection {
    let title: String
    @Binding var selection: Option
    let options: Option.AllCases

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rounded(13, weight: .black))
                .foregroundStyle(Color.secondaryInk)

            HStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(option.title)
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(selection == option ? .white : .punchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selection == option ? Color.punchBlack : Color.cardBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
        }
    }
}

private protocol TitledFilter {
    var title: String { get }
}

private enum RecordTypeFilter: String, CaseIterable, Identifiable, TitledFilter {
    case all
    case money
    case food
    case time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .money: "金钱"
        case .food: "食物"
        case .time: "时间"
        }
    }

    func matches(_ record: ResistRecord) -> Bool {
        switch self {
        case .all:
            return true
        case .money:
            return record.type == .money
        case .food:
            return record.type == .food
        case .time:
            return record.type == .time
        }
    }
}

private enum RecordStatusFilter: String, CaseIterable, Identifiable, TitledFilter {
    case all
    case resisted
    case pending
    case gaveIn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .resisted: "忍住"
        case .pending: "冷静"
        case .gaveIn: "观察"
        }
    }

    func matches(_ record: ResistRecord) -> Bool {
        switch self {
        case .all:
            return true
        case .resisted:
            return record.status == .resisted
        case .pending:
            return record.status == .pending
        case .gaveIn:
            return record.status == .gaveIn
        }
    }
}
