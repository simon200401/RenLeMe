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
                            EmptyStateView(title: "还没有目标", message: "", systemImage: "target")
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
                                            deleteGoal(goal)
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
                }

                Spacer()

                AnimatedXiaoRenView(
                    color: Color(red: 1.0, green: 0.949, blue: 0.839),
                    expression: goals.contains(where: { goalProgress(for: $0) > 0 }) ? .sparkle : .curious,
                    size: 76,
                    reduceMotion: reduceMotion
                )
            }
        }
    }

    private func goalProgress(for goal: Goal) -> Double {
        let current = StatsCalculator.currentValue(for: goal, records: records)
        return current / max(goal.targetValue, 1)
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

    private func deleteGoal(_ goal: Goal) {
        let imagePath = goal.customImagePath
        modelContext.delete(goal)
        do {
            try modelContext.save()
            LocalImageStore.delete(imagePath)
        } catch {
            modelContext.rollback()
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

    private var current: Double {
        StatsCalculator.currentValue(for: goal, records: records)
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
            PunchyCard(fill: cardColor, cornerRadius: 32, padding: 18) {
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

                            Text(isCompleted ? "已完成" : goal.type.assetTitle)
                                .font(.rounded(14, weight: .black))
                                .foregroundStyle(textColor.opacity(0.72))
                        }

                        Spacer()

                        ZStack(alignment: .bottomTrailing) {
                            GoalIconView(goal: goal, size: 78)

                            AnimatedXiaoRenView(
                                color: cardColor,
                                expression: goalMascotExpression,
                                size: 54,
                                reduceMotion: reduceMotion
                            )
                            .offset(x: 8, y: 10)
                            .scaleEffect(isCompleted && pulse ? 1.08 : 0.94)
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

    private var goalSeed: Int {
        goal.title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }

    private var goalMascotExpression: DynamicMascotExpression {
        if isCompleted { return .celebrate }
        if progress >= 0.66 { return .proud }
        if progress > 0 {
            return [.sparkle, .relieved, .hello][goalSeed % 3]
        }
        return [.curious, .thinking, .sparkle][goalSeed % 3]
    }

    private var cardColor: Color {
        Color.blockColor(for: goal.type)
    }
}

private enum GoalTimeInputUnit: String, CaseIterable, Identifiable {
    case minute
    case hour

    var id: String { rawValue }
    var title: String { self == .minute ? "min" : "hour" }
    var minuteMultiplier: Double { self == .minute ? 1 : 60 }
}

private extension ResistType {
    var defaultGoalSystemIcon: String {
        switch self {
        case .money: "wallet.pass.fill"
        case .food: "fork.knife"
        case .time: "clock.fill"
        }
    }
}

private struct GoalValueInput: View {
    @Binding var text: String
    let type: ResistType
    @Binding var timeUnit: GoalTimeInputUnit

    var body: some View {
        VStack(spacing: 10) {
            if type == .time {
                Picker("时间单位", selection: $timeUnit) {
                    ForEach(GoalTimeInputUnit.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)
            }

            HStack(spacing: 10) {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.fieldPlaceholderInk)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $text)
                        .appInputTextStyle()
                        .keyboardType(.decimalPad)
                }

                Text(displayUnit)
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.fieldPlaceholderInk)
            }
            .padding(14)
            .background(Color.cream)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var placeholder: String {
        switch type {
        case .money: "例如 3000"
        case .food: "例如 900"
        case .time: timeUnit == .minute ? "例如 30" : "例如 5"
        }
    }

    private var displayUnit: String {
        switch type {
        case .money: "元"
        case .food: "kcal"
        case .time: timeUnit.title
        }
    }
}

private struct GoalImagePickerSection: View {
    let type: ResistType
    let image: UIImage?
    let onPhotoLibrary: () -> Void
    let onCamera: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("目标图片")
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.secondaryInk)

            HStack(spacing: 14) {
                preview

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        sourceButton(title: "相册", systemImage: "photo.fill", action: onPhotoLibrary)

                        sourceButton(
                            title: UIImagePickerController.isSourceTypeAvailable(.camera) ? "拍照" : "真机拍照",
                            systemImage: "camera.fill",
                            action: onCamera
                        )
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        .opacity(UIImagePickerController.isSourceTypeAvailable(.camera) ? 1 : 0.45)
                    }

                    if image != nil {
                        Button("移除照片", role: .destructive, action: onRemove)
                            .font(.rounded(13, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.punchBlack, lineWidth: 3)
                }
        } else {
            PropIconView(template: PropTemplate.defaultTemplate(for: type), size: 82)
        }
    }

    private func sourceButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.rounded(13, weight: .black))
                .foregroundStyle(Color.punchBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.softBlockColor(for: type))
                .clipShape(Capsule())
        }
        .buttonStyle(PressableScaleStyle())
    }
}

private struct GoalTypePicker: View {
    @Binding var type: ResistType

    var body: some View {
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
    }
}

private struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var type: ResistType = .money
    @State private var targetValue = ""
    @State private var timeUnit: GoalTimeInputUnit = .hour
    @State private var goalImage: UIImage?
    @State private var imageSource: CustomImageSource?
    @State private var saveFailed = false

    private var parsedTarget: Double {
        let rawValue = Double(targetValue.replacingOccurrences(of: ",", with: "")) ?? 0
        return type == .time ? rawValue * timeUnit.minuteMultiplier : rawValue
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedTarget > 0
    }

    var body: some View {
        goalForm(titleText: "New goal", mascot: MascotMomentView(moment: .idle, size: 74))
            .navigationTitle("新目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.rounded(15, weight: .black))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: saveGoal)
                        .disabled(!canSave)
                        .font(.rounded(15, weight: .black))
                }
            }
            .sheet(item: $imageSource) { source in
                CameraImagePicker(image: $goalImage, sourceType: source.sourceType)
            }
            .alert("目标保存失败", isPresented: $saveFailed) {
                Button("知道了", role: .cancel) {}
            }
    }

    private func goalForm<Mascot: View>(titleText: String, mascot: Mascot) -> some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PunchyCard(fill: Color.blockColor(for: type), cornerRadius: 34, padding: 20) {
                        HStack(alignment: .top) {
                            Text(titleText)
                                .font(.rounded(38, weight: .black))
                                .foregroundStyle(type == .time ? Color.punchBlack : .white)
                            Spacer()
                            mascot
                        }
                    }

                    PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            labeledField("目标标题") {
                                AppTextField(placeholder: "比如：旅行基金", text: $title)
                            }
                            GoalTypePicker(type: $type)
                            labeledField("目标值") {
                                GoalValueInput(text: $targetValue, type: type, timeUnit: $timeUnit)
                            }
                            GoalImagePickerSection(
                                type: type,
                                image: goalImage,
                                onPhotoLibrary: { openImageSource(.photoLibrary) },
                                onCamera: { openImageSource(.camera) },
                                onRemove: { goalImage = nil }
                            )
                        }
                    }
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
    }

    private func saveGoal() {
        let imagePath = LocalImageStore.save(goalImage)
        guard goalImage == nil || imagePath != nil else {
            saveFailed = true
            return
        }

        let goal = Goal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            targetValue: parsedTarget,
            icon: type.defaultGoalSystemIcon,
            customImagePath: imagePath
        )
        modelContext.insert(goal)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            LocalImageStore.delete(imagePath)
            saveFailed = true
        }
    }

    private func openImageSource(_ source: CustomImageSource) {
        guard UIImagePickerController.isSourceTypeAvailable(source.sourceType) else { return }
        imageSource = source
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

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let goal: Goal

    @State private var title: String
    @State private var type: ResistType
    @State private var targetValue: String
    @State private var timeUnit: GoalTimeInputUnit
    @State private var goalImage: UIImage?
    @State private var imageSource: CustomImageSource?
    @State private var imageWasChanged = false
    @State private var saveFailed = false

    init(goal: Goal) {
        self.goal = goal
        let storesHours = goal.type == .time
            && goal.targetValue >= 60
            && goal.targetValue.truncatingRemainder(dividingBy: 60) == 0
        _title = State(initialValue: goal.title)
        _type = State(initialValue: goal.type)
        _timeUnit = State(initialValue: storesHours ? .hour : .minute)
        _targetValue = State(initialValue: (storesHours ? goal.targetValue / 60 : goal.targetValue).cleanString)
        _goalImage = State(initialValue: LocalImageStore.image(at: goal.customImagePath))
    }

    private var parsedTarget: Double {
        let rawValue = Double(targetValue.replacingOccurrences(of: ",", with: "")) ?? 0
        return type == .time ? rawValue * timeUnit.minuteMultiplier : rawValue
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
                            Text("Edit goal")
                                .font(.rounded(38, weight: .black))
                                .foregroundStyle(type == .time ? Color.punchBlack : .white)
                            Spacer()
                            AnimatedXiaoRenView(color: type.v2MascotColor, expression: .thinking, size: 74)
                        }
                    }

                    PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            labeledField("目标标题") {
                                AppTextField(placeholder: "比如：旅行基金", text: $title)
                            }
                            GoalTypePicker(type: $type)
                            labeledField("目标值") {
                                GoalValueInput(text: $targetValue, type: type, timeUnit: $timeUnit)
                            }
                            GoalImagePickerSection(
                                type: type,
                                image: goalImage,
                                onPhotoLibrary: { openImageSource(.photoLibrary) },
                                onCamera: { openImageSource(.camera) },
                                onRemove: {
                                    goalImage = nil
                                    imageWasChanged = true
                                }
                            )
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
                Button("取消") { dismiss() }
                    .font(.rounded(15, weight: .black))
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: saveChanges)
                    .disabled(!canSave)
                    .font(.rounded(15, weight: .black))
            }
        }
        .sheet(item: $imageSource) { source in
            CameraImagePicker(image: $goalImage, sourceType: source.sourceType) {
                imageWasChanged = true
            }
        }
        .alert("目标保存失败", isPresented: $saveFailed) {
            Button("知道了", role: .cancel) {}
        }
    }

    private func saveChanges() {
        let oldImagePath = goal.customImagePath
        var newImagePath: String?

        if imageWasChanged, let goalImage {
            guard let savedPath = LocalImageStore.save(goalImage) else {
                saveFailed = true
                return
            }
            newImagePath = savedPath
        }

        goal.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.type = type
        goal.targetValue = parsedTarget
        goal.icon = type.defaultGoalSystemIcon
        if imageWasChanged {
            goal.customImagePath = newImagePath
        }

        do {
            try modelContext.save()
            if imageWasChanged, oldImagePath != newImagePath {
                LocalImageStore.delete(oldImagePath)
            }
            dismiss()
        } catch {
            modelContext.rollback()
            LocalImageStore.delete(newImagePath)
            saveFailed = true
        }
    }

    private func openImageSource(_ source: CustomImageSource) {
        guard UIImagePickerController.isSourceTypeAvailable(source.sourceType) else { return }
        imageSource = source
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
