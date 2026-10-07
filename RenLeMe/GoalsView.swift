import SwiftData
import SwiftUI

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]
    @State private var isAddingGoal = false
    @State private var editingGoal: Goal?
    @State private var achievingGoal: Goal?
    @AppStorage(GoalFocus.versionKey) private var focusVersion = 0

    private var ledger: GoalLedger {
        _ = focusVersion
        return GoalLedger(goals: goals, records: records)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if goals.active.isEmpty {
                        PunchyCard(fill: .cardBackground, cornerRadius: 24) {
                            EmptyStateView(title: "还没有目标", message: "", systemImage: "target")
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(goals.active) { goal in
                                GoalProgressCard(goal: goal, ledger: ledger) {
                                    if ledger.isFinished(goal) {
                                        achievingGoal = goal
                                    } else {
                                        editingGoal = goal
                                    }
                                }
                                    .contextMenu {
                                        Button {
                                            editingGoal = goal
                                        } label: {
                                            Label("编辑目标", systemImage: "pencil")
                                        }

                                        if ledger.canBecomeFocus(goal) {
                                            Button {
                                                GoalFocus.set(goal)
                                            } label: {
                                                Label("先攒这个", systemImage: "arrow.up.to.line")
                                            }
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
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
            .appScrollDefaults()
        }
        .navigationTitle("目标")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(item: $achievingGoal) { goal in
            GoalAchievedSheet(goal: goal)
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

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var type: ResistType
    @State private var targetValue = ""
    @State private var timeUnit: GoalTimeInputUnit = .hour
    @State private var goalImage: UIImage?
    @State private var imageSource: CustomImageSource?
    @State private var saveFailed = false
    private let onCreate: (Goal) -> Void

    init(initialType: ResistType = .money, onCreate: @escaping (Goal) -> Void = { _ in }) {
        _type = State(initialValue: initialType)
        self.onCreate = onCreate
    }

    private var parsedTarget: Double {
        let rawValue = Double(targetValue.replacingOccurrences(of: ",", with: "")) ?? 0
        return type == .time ? rawValue * timeUnit.minuteMultiplier : rawValue
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedTarget > 0
    }

    var body: some View {
        goalForm
            .navigationTitle("新目标")
            .navigationBarTitleDisplayMode(.inline)
            .appKeyboardDismissal()
            .onSubmit { UIApplication.shared.dismissKeyboard() }
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
            .fullScreenCover(item: $imageSource) { source in
                CameraImagePicker(image: $goalImage, sourceType: source.sourceType)
                    .ignoresSafeArea()
            }
            .alert("目标保存失败", isPresented: $saveFailed) {
                Button("知道了", role: .cancel) {}
            }
    }

    private var goalForm: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
            onCreate(goal)
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
    @State private var isConfirmingDelete = false

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

    /// Removes the goal and unlinks its records, which are kept.
    private func deleteGoal() {
        let goalId = goal.id
        let imagePath = goal.customImagePath
        let linked = (try? modelContext.fetch(FetchDescriptor<ResistRecord>()))?.filter { $0.goalId == goalId } ?? []
        for record in linked {
            record.goalId = nil
        }
        modelContext.delete(goal)
        do {
            try modelContext.save()
            LocalImageStore.delete(imagePath)
            dismiss()
        } catch {
            modelContext.rollback()
            saveFailed = true
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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

                    Button(role: .destructive) {
                        UIApplication.shared.dismissKeyboard()
                        isConfirmingDelete = true
                    } label: {
                        Label("删除目标", systemImage: "trash")
                            .font(.rounded(16, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.punchBlack.opacity(0.07))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                    .accessibilityIdentifier("deleteGoalButton")
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
        .confirmationDialog("删除「\(goal.title)」？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("删除目标", role: .destructive, action: deleteGoal)
            Button("取消", role: .cancel) {}
        } message: {
            Text("记录都会保留，只是不再算进这个目标。")
        }
        .navigationTitle("编辑目标")
        .navigationBarTitleDisplayMode(.inline)
        .appKeyboardDismissal()
        .onSubmit { UIApplication.shared.dismissKeyboard() }
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
        .fullScreenCover(item: $imageSource) { source in
            CameraImagePicker(image: $goalImage, sourceType: source.sourceType) {
                imageWasChanged = true
            }
            .ignoresSafeArea()
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
