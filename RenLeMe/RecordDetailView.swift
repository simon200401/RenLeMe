import SwiftData
import SwiftUI

struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let record: ResistRecord

    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    private var template: PropTemplate? {
        PropTemplate.matching(record: record)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    detailsCard
                    noteCard
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") {
                    isEditing = true
                }
                .font(.rounded(15, weight: .black))
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                EditRecordView(record: record)
            }
        }
        .confirmationDialog("删除这条记录？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                LocalImageStore.delete(record.customImagePath)
                modelContext.delete(record)
                dismiss()
            }

            Button("取消", role: .cancel) {}
        }
    }

    private var summaryCard: some View {
        PunchyCard(fill: Color.blockColor(for: record.type), cornerRadius: 34, padding: 20) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    StatusChip(title: record.status.title, fill: .punchBlack)

                    Text(record.title)
                        .font(.rounded(34, weight: .black))
                        .foregroundStyle(textColor)
                        .lineLimit(3)
                        .minimumScaleFactor(0.76)

                    Text(record.value.displayValue(for: record.type))
                        .font(.rounded(36, weight: .black))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }

                Spacer()

                ZStack(alignment: .bottomTrailing) {
                    RecordPropIconView(record: record, size: 92)
                    MascotMomentView(moment: record.status.mascotMoment, size: 36)
                        .offset(x: 8, y: 8)
                }
            }
        }
    }

    private var detailsCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("记录线索")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)

                DetailLine(title: "类型", value: record.type.title)
                DetailLine(title: "状态", value: record.status.title)
                DetailLine(title: "原因", value: record.reason)
                DetailLine(title: "创建时间", value: fullDateText(record.createdAt))

                if let resolvedAt = record.resolvedAt {
                    DetailLine(title: "决定时间", value: fullDateText(resolvedAt))
                }

                if let cooldownUntil = record.cooldownUntil {
                    DetailLine(title: "冷静到期", value: fullDateText(cooldownUntil))
                }

                if record.type == .food {
                    if let grams = record.foodServingGrams {
                        DetailLine(title: "份量", value: "\(grams.cleanString)g")
                    }
                    if let energy = record.foodEnergyKcalPer100g {
                        DetailLine(title: "数据库热量", value: "\(energy.cleanString) kcal / 100g")
                    }
                    if let source = record.foodSourceName {
                        DetailLine(title: "来源", value: source)
                    }
                }

                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("删除记录", systemImage: "trash")
                        .font(.rounded(16, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
    }

    private var noteCard: some View {
        PunchyCard(fill: .cream, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("备注")
                    .font(.rounded(22, weight: .black))
                    .foregroundStyle(Color.ink)

                Text(record.note.isEmpty ? "没有备注。" : record.note)
                    .font(.rounded(16, weight: .bold))
                    .foregroundStyle(Color.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var textColor: Color {
        record.type == .time ? .punchBlack : .white
    }

    private func fullDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct DetailLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.rounded(14, weight: .black))
                .foregroundStyle(Color.secondaryInk)
                .frame(width: 78, alignment: .leading)

            Text(value)
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(12)
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
