import SwiftData
import SwiftUI

struct GoalsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @State private var isAddingGoal = false
    @State private var editingGoal: Goal?
    @State private var completedGoalMoment: MascotMoment?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if goals.isEmpty {
                        PunchyCard(fill: .punchYellow) {
                            EmptyStateView(title: "还没有目标", message: "可以从一个小目标开始，比如少买一件衣服，或拿回一小时。", systemImage: "target")
                        }
                    } else {
                        VStack(spacing: 14) {
                            ForEach(goals) { goal in
                                GoalDetailCard(goal: goal, records: records) {
                                    editingGoal = goal
                                } onCelebrate: { moment in
                                    showGoalCelebration(moment)
                                }
                                    .contextMenu {
                                        Button {
                                            editingGoal = goal
                                        } label: {
                                            Label("编辑目标", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            modelContext.delete(goal)
                                        } label: {
                                            Label("删除目标", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .appScrollDefaults()

            if let completedGoalMoment {
                MascotFeedbackPopup(moment: completedGoalMoment) {
                    hideGoalCelebration()
                }
            }
        }
        .navigationTitle("目标")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingGoal = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.rounded(22, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                }
            }
        }
        .sheet(isPresented: $isAddingGoal) {
            NavigationStack {
                AddGoalView()
            }
        }
        .sheet(item: $editingGoal) { goal in
            NavigationStack {
                EditGoalView(goal: goal)
            }
        }
    }

    private var header: some View {
        PunchyCard(fill: .cream, cornerRadius: 34, padding: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Goals")
                        .font(.rounded(42, weight: .black))
                        .foregroundStyle(Color.ink)
                    Text("把忍住的价值，投向真正想要的生活。")
                        .font(.rounded(17, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                MascotMomentView(moment: .idle, size: 76)
            }
        }
    }

    private func showGoalCelebration(_ moment: MascotMoment) {
        if reduceMotion {
            completedGoalMoment = moment
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                completedGoalMoment = moment
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            hideGoalCelebration()
        }
    }

    private func hideGoalCelebration() {
        if reduceMotion {
            completedGoalMoment = nil
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                completedGoalMoment = nil
            }
        }
    }
}

private struct GoalDetailCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let goal: Goal
    let records: [ResistRecord]
    var onEdit: () -> Void = {}
    var onCelebrate: (MascotMoment) -> Void = { _ in }
    @State private var pulse = false

    private var template: PropTemplate? {
        PropTemplate.matching(goal: goal)
    }

    private var current: Double {
        let targeted = StatsCalculator.currentValue(for: goal, records: records)
        if targeted > 0 { return targeted }
        return StatsCalculator.totalValue(for: goal.type, records: records)
    }

    private var progress: Double {
        current / max(goal.targetValue, 1)
    }

    private var isCompleted: Bool {
        progress >= 1
    }

    var body: some View {
        Button {
            isCompleted ? onCelebrate(.goalCompleted(goal.type)) : onEdit()
        } label: {
            PunchyCard(fill: Color.blockColor(for: goal.type), cornerRadius: 32, padding: 18) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(goal.title)
                                    .font(.rounded(27, weight: .black))
                                    .foregroundStyle(textColor)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.72)

                                if isCompleted {
                                    Image(systemName: "sparkles")
                                        .font(.rounded(18, weight: .black))
                                        .foregroundStyle(textColor)
                                        .scaleEffect(pulse ? 1.18 : 0.92)
                                }
                            }

                            Text(isCompleted ? "目标达成，点一下庆祝" : goal.type.assetTitle)
                                .font(.rounded(14, weight: .black))
                                .foregroundStyle(textColor.opacity(0.72))
                        }

                        Spacer()

                        ZStack(alignment: .bottomTrailing) {
                            if let template {
                                PropIconView(template: template, size: 78)
                            } else {
                                PropIconView(template: PropTemplate.defaultTemplate(for: goal.type), size: 78)
                            }

                            if isCompleted {
                                AnimatedXiaoRenView(
                                    color: goal.type == .time ? .punchGreen : Color(red: 1.0, green: 0.949, blue: 0.839),
                                    expression: .proud,
                                    size: 52,
                                    reduceMotion: reduceMotion
                                )
                                .offset(x: 8, y: 10)
                                .scaleEffect(pulse ? 1.08 : 0.94)
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            let filled = Double(index + 1) / 7 <= min(progress, 1)
                            Circle()
                                .fill(filled ? Color.punchBlack : Color.punchBlack.opacity(0.16))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if filled {
                                        Image(systemName: "checkmark")
                                            .font(.rounded(12, weight: .black))
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                .scaleEffect(isCompleted && pulse ? 1.08 : 1)
                        }
                    }

                    ProgressLine(progress: progress, tint: .punchBlack)

                    HStack(alignment: .lastTextBaseline) {
                        Text(current.displayValue(for: goal.type))
                            .font(.rounded(24, weight: .black))
                            .foregroundStyle(textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                        Text("/ \(goal.targetValue.displayValue(for: goal.type))")
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(textColor.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                        Spacer()
                        StatusChip(title: "\(Int(min(progress, 1) * 100))%", fill: .punchBlack)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            guard isCompleted, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var textColor: Color {
        goal.type == .time ? .punchBlack : .white
    }
}

private struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var type: ResistType = .money
    @State private var targetValue = ""
    @State private var icon = "target"

    private var parsedTarget: Double {
        Double(targetValue.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedTarget > 0
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PunchyCard(fill: Color.blockColor(for: type), cornerRadius: 34, padding: 20) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New goal")
                                    .font(.rounded(38, weight: .black))
                                    .foregroundStyle(type == .time ? Color.punchBlack : .white)
                                Text(type.gentleHint)
                                    .font(.rounded(15, weight: .black))
                                    .foregroundStyle((type == .time ? Color.punchBlack : .white).opacity(0.76))
                            }
                            Spacer()
                            MascotMomentView(moment: .idle, size: 74)
                        }
                    }

                    PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            labeledField("目标标题") {
                                TextField("比如：旅行基金", text: $title)
                                    .appInputTextStyle()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("类型")
                                    .font(.rounded(15, weight: .black))
                                    .foregroundStyle(Color.secondaryInk)

                                HStack(spacing: 10) {
                                    ForEach(ResistType.allCases) { option in
                                        Button {
                                            type = option
                                        } label: {
                                            Text(option.title)
                                                .font(.rounded(15, weight: .black))
                                                .foregroundStyle(Color.punchBlack)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(type == option ? Color.softBlockColor(for: option) : Color.cream)
                                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                        .stroke(Color.punchBlack, lineWidth: type == option ? 2 : 0)
                                                }
                                        }
                                        .buttonStyle(PressableScaleStyle())
                                    }
                                }
                            }

                            labeledField("目标值") {
                                TextField("例如 3000", text: $targetValue)
                                    .appInputTextStyle()
                                    .keyboardType(.decimalPad)
                            }

                            Picker("图标", selection: $icon) {
                                Text("目标").tag("target")
                                Text("相机").tag("camera.fill")
                                Text("杯子").tag("cup.and.saucer.fill")
                                Text("月亮").tag("moon.stars.fill")
                                Text("书").tag("book.fill")
                            }
                        }
                    }
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("新目标")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
                .font(.rounded(15, weight: .black))
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    modelContext.insert(Goal(title: title, type: type, targetValue: parsedTarget, icon: icon))
                    dismiss()
                }
                .disabled(!canSave)
                .font(.rounded(15, weight: .black))
            }
        }
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.secondaryInk)

            content()
                .padding(14)
                .background(Color.cream)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss

    let goal: Goal

    @State private var title: String
    @State private var type: ResistType
    @State private var targetValue: String
    @State private var icon: String

    init(goal: Goal) {
        self.goal = goal
        _title = State(initialValue: goal.title)
        _type = State(initialValue: goal.type)
        _targetValue = State(initialValue: goal.targetValue.cleanString)
        _icon = State(initialValue: goal.icon)
    }

    private var parsedTarget: Double {
        Double(targetValue.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedTarget > 0
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PunchyCard(fill: Color.blockColor(for: type), cornerRadius: 34, padding: 20) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Edit goal")
                                    .font(.rounded(38, weight: .black))
                                    .foregroundStyle(type == .time ? Color.punchBlack : .white)
                                Text("目标可以调整，方向不用一次就完美。")
                                    .font(.rounded(15, weight: .black))
                                    .foregroundStyle((type == .time ? Color.punchBlack : .white).opacity(0.76))
                            }
                            Spacer()
                            AnimatedXiaoRenView(color: type.v2MascotColor, expression: .thinking, size: 74)
                        }
                    }

                    PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            labeledField("目标标题") {
                                AppTextField(placeholder: "比如：旅行基金", text: $title)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("类型")
                                    .font(.rounded(15, weight: .black))
                                    .foregroundStyle(Color.secondaryInk)

                                HStack(spacing: 10) {
                                    ForEach(ResistType.allCases) { option in
                                        Button {
                                            type = option
                                        } label: {
                                            Text(option.title)
                                                .font(.rounded(15, weight: .black))
                                                .foregroundStyle(Color.punchBlack)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(type == option ? Color.softBlockColor(for: option) : Color.cream)
                                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                        .stroke(Color.punchBlack, lineWidth: type == option ? 2 : 0)
                                                }
                                        }
                                        .buttonStyle(PressableScaleStyle())
                                    }
                                }
                            }

                            labeledField("目标值") {
                                AppTextField(placeholder: "例如 3000", text: $targetValue, keyboardType: .decimalPad)
                            }

                            Picker("图标", selection: $icon) {
                                Text("目标").tag("target")
                                Text("相机").tag("camera.fill")
                                Text("杯子").tag("cup.and.saucer.fill")
                                Text("月亮").tag("moon.stars.fill")
                                Text("书").tag("book.fill")
                            }
                        }
                    }
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("编辑目标")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
                .font(.rounded(15, weight: .black))
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    goal.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    goal.type = type
                    goal.targetValue = parsedTarget
                    goal.icon = icon
                    dismiss()
                }
                .disabled(!canSave)
                .font(.rounded(15, weight: .black))
            }
        }
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.secondaryInk)

            content()
        }
    }
}
