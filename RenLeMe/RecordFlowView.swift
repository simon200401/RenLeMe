import SwiftData
import SwiftUI
import UIKit

enum CustomImageSource: String, Identifiable {
    case camera
    case photoLibrary

    var id: String { rawValue }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: .camera
        case .photoLibrary: .photoLibrary
        }
    }
}

struct RecordFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]

    var isModal = false

    @State private var selectedType: ResistType = .money
    @State private var title = ""
    @State private var valueText = ""
    @State private var selectedReason = "好看"
    @State private var note = ""
    @State private var selectedGoalId: UUID?
    @State private var selectedTemplate: PropTemplate?
    @State private var isCustomPropSelected = false
    @State private var isPropPickerExpanded = false
    @State private var isDetailsExpanded = false
    @State private var customImage: UIImage?
    @State private var customImageSource: CustomImageSource?
    @State private var selectedFood: FoodNutritionItem?
    @State private var servingGramsText = ""
    @State private var completionMoment: MascotMoment?
    @State private var introExpression: DynamicMascotExpression = .thinking
    @State private var isShowingFoodPicker = false

    private var filteredGoals: [Goal] {
        goals.filter { $0.type == selectedType }
    }

    private var parsedValue: Double {
        Double(valueText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var parsedServingGrams: Double {
        Double(servingGramsText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var calculatedFoodCalories: Double {
        guard let selectedFood, parsedServingGrams > 0 else { return 0 }
        return selectedFood.calories(for: parsedServingGrams)
    }

    private var effectiveValue: Double {
        if selectedType == .food, selectedFood != nil {
            return calculatedFoodCalories
        }
        if parsedValue > 0 {
            return parsedValue
        }
        return selectedTemplate?.defaultValue ?? 0
    }

    private var hasTitle: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasEstimatedValue: Bool {
        effectiveValue > 0
    }

    private func canSave(_ status: ResistStatus) -> Bool {
        hasTitle && (status == .pending || hasEstimatedValue)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    typePicker
                    propPicker
                    detailsCard
                    decisionCard
                }
                .padding(18)
            }
            .appScrollDefaults()

            if let completionMoment {
                MascotFeedbackPopup(moment: completionMoment) {
                    hideCompletionPopup()
                }
            }
        }
        .navigationTitle("忍一下")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedType) { _, newType in
            selectedReason = newType.reasons.first ?? ""
            selectedGoalId = nil
            selectedTemplate = nil
            isCustomPropSelected = false
            isPropPickerExpanded = false
            customImage = nil
            customImageSource = nil
            selectedFood = nil
            servingGramsText = ""
            title = ""
            valueText = ""
            isDetailsExpanded = false
            completionMoment = nil
            pulseIntro(.thinking)
        }
        .sheet(isPresented: $isShowingFoodPicker) {
            NavigationStack {
                FoodPickerView { food in
                    selectedTemplate = nil
                    selectedFood = food
                    title = food.name
                    if let grams = food.defaultServingGrams {
                        servingGramsText = grams.cleanString
                        valueText = food.calories(for: grams).cleanString
                    }
                }
            }
        }
        .sheet(item: $customImageSource) { source in
            CameraImagePicker(image: $customImage, sourceType: source.sourceType) {
                isCustomPropSelected = true
                selectedTemplate = nil
            }
        }
    }

    private var intro: some View {
        PunchyCard(fill: Color.blockColor(for: selectedType), cornerRadius: 34, padding: 20) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pause")
                        .font(.rounded(42, weight: .black))
                        .foregroundStyle(selectedType == .time ? Color.punchBlack : .white)

                }

                Spacer()

                AnimatedXiaoRenView(
                    color: selectedType.v2MascotColor,
                    expression: introExpression,
                    size: 86,
                    reduceMotion: reduceMotion
                )
            }
        }
    }

    private var typePicker: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("1. 选择欲望类型")
                    .font(.rounded(20, weight: .black))
                    .foregroundStyle(Color.ink)

                HStack(spacing: 10) {
                    ForEach(ResistType.allCases) { type in
                        Button {
                            selectedType = type
                            pulseIntro(.sparkle)
                        } label: {
                            VStack(spacing: 8) {
                                TypeMascotBadge(type: type, size: 56)
                                Text(type.title)
                                    .font(.rounded(15, weight: .black))
                                    .foregroundStyle(Color.punchBlack)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.softBlockColor(for: type).opacity(selectedType == type ? 1 : 0.58))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.punchBlack, lineWidth: selectedType == type ? 3 : 0)
                            }
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
            }
        }
    }

    private var propPicker: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("2. 选择一个具体道具")
                    .font(.rounded(20, weight: .black))
                    .foregroundStyle(Color.ink)

                Button {
                    toggleCustomProp()
                    pulseIntro(.curious)
                } label: {
                    CustomPropCard(type: selectedType, selectedImage: customImage, isSelected: isCustomPropSelected)
                }
                .buttonStyle(PressableScaleStyle())
                .accessibilityLabel("自选道具")

                if isCustomPropSelected {
                    customPropControls
                }

                Button {
                    togglePropPicker()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2.fill")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isPropPickerExpanded ? "收起内置道具" : "展开内置道具")
                                .font(.rounded(16, weight: .black))
                            if let selectedTemplate {
                                Text("已选：\(selectedTemplate.title)")
                                    .font(.rounded(13, weight: .bold))
                            }
                        }
                        Spacer(minLength: 4)
                        Image(systemName: isPropPickerExpanded ? "chevron.up" : "chevron.down")
                    }
                    .foregroundStyle(Color.punchBlack)
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Color.softBlockColor(for: selectedType))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableScaleStyle())
                .accessibilityValue(isPropPickerExpanded ? "已展开" : "已收起")
                .accessibilityIdentifier("builtInPropToggle")

                if isPropPickerExpanded {
                    LazyVGrid(columns: propColumns, spacing: 10) {
                        ForEach(PropTemplate.templates(for: selectedType)) { template in
                            Button {
                                selectTemplate(template)
                                pulseIntro(selectedTemplate?.id == template.id ? .curious : .sparkle)
                            } label: {
                                PropCard(template: template, isSelected: selectedTemplate?.id == template.id)
                            }
                            .buttonStyle(PressableScaleStyle())
                            .accessibilityLabel("选择\(template.title)")
                        }
                    }
                }

                Button {
                    save(status: .pending)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "pause.fill")
                            .font(.rounded(18, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .frame(width: 38, height: 38)
                            .background(Color.punchYellow)
                            .clipShape(Circle())

                        Text("先缓一下")
                            .font(.rounded(18, weight: .black))

                        Spacer()

                        Text(cooldownDurationText)
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.white.opacity(0.78))
                    }
                    .foregroundStyle(Color.white)
                    .padding(12)
                    .background(Color.punchBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(PressableScaleStyle())
                .disabled(!canSave(.pending))
                .opacity(canSave(.pending) ? 1 : 0.45)
            }
        }
    }

    private let propColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var customPropControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text("自选名称")
                    .font(.rounded(14, weight: .black))
                    .foregroundStyle(Color.fieldLabelInk)

                AppTextField(placeholder: customTitlePlaceholder, text: $title)
            }

            HStack(spacing: 10) {
                Button {
                    openCustomImageSource(.photoLibrary)
                } label: {
                    Label("相册", systemImage: "photo.fill")
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.softBlockColor(for: selectedType))
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())

                Button {
                    openCustomImageSource(.camera)
                } label: {
                    Label(UIImagePickerController.isSourceTypeAvailable(.camera) ? "拍照" : "真机拍照", systemImage: "camera.fill")
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cream)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                .opacity(UIImagePickerController.isSourceTypeAvailable(.camera) ? 1 : 0.45)
            }
        }
    }

    private var customTitlePlaceholder: String {
        switch selectedType {
        case .money: "比如：香水、衣服、手表"
        case .food: "比如：奶茶、炸鸡、甜品"
        case .time: "比如：刷视频、闲聊、拖延"
        }
    }

    private var detailsCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    if reduceMotion {
                        isDetailsExpanded.toggle()
                    } else {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                            isDetailsExpanded.toggle()
                        }
                    }
                } label: {
                    HStack {
                        Text("3. 补充信息")
                            .font(.rounded(20, weight: .black))
                            .foregroundStyle(Color.ink)

                        Spacer()

                        Text(hasEstimatedValue ? effectiveValue.displayValue(for: selectedType) : "可选")
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.secondaryInk)

                        Image(systemName: isDetailsExpanded ? "chevron.up" : "chevron.down")
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableScaleStyle())

                if isDetailsExpanded {
                    if selectedType == .food {
                        foodDatabaseFields
                    } else {
                        standardValueFields
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("此刻的原因")
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(Color.fieldLabelInk)

                        Picker("原因", selection: $selectedReason) {
                            ForEach(selectedType.reasons, id: \.self) { reason in
                                Text(reason).tag(reason)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if !filteredGoals.isEmpty {
                        Picker("投向目标", selection: $selectedGoalId) {
                            Text("暂不关联").tag(UUID?.none)
                            ForEach(filteredGoals) { goal in
                                Text(goal.title).tag(Optional(goal.id))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("给自己的备注")
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(Color.fieldLabelInk)

                        AppTextField(
                            placeholder: "写点什么",
                            text: $note,
                            axis: .vertical,
                            lineLimit: 3,
                            reservesSpace: true
                        )
                    }
                }
            }
        }
    }

    private var standardValueFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(selectedType.valueTitle) · \(unitText)")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.fieldLabelInk)

                AppTextField(placeholder: valuePlaceholder, text: $valueText, keyboardType: .decimalPad)

                if let selectedTemplate {
                    ValueDefaultChip(text: selectedTemplate.defaultValueText, fill: selectedTemplate.displayColor.opacity(0.34))
                }
            }
        }
    }

    private var foodDatabaseFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("热量 · kcal")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.fieldLabelInk)

                AppTextField(placeholder: valuePlaceholder, text: $valueText, keyboardType: .decimalPad)

                if let selectedTemplate {
                    ValueDefaultChip(text: selectedTemplate.defaultValueText, fill: selectedTemplate.displayColor.opacity(0.34))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                    Text("本地食物库")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.fieldLabelInk)

                Button {
                    isShowingFoodPicker = true
                } label: {
                    HStack(spacing: 12) {
                        TypeIcon(type: .food, size: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedFood?.name ?? "从本地食物库精确计算")
                                .font(.rounded(17, weight: .black))
                                .foregroundStyle(Color.ink)

                            Text(selectedFoodDetailText)
                                .font(.caption)
                                .foregroundStyle(Color.secondaryInk)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.secondaryInk)
                    }
                    .padding(12)
                    .background(Color.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(PressableScaleStyle())
            }

            if selectedFood != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("这次的份量 · g")
                        .font(.rounded(15, weight: .black))
                        .foregroundStyle(Color.fieldLabelInk)

                    AppTextField(placeholder: "例如 150", text: $servingGramsText, keyboardType: .decimalPad)
                        .onChange(of: servingGramsText) { _, _ in
                            valueText = calculatedFoodCalories > 0 ? calculatedFoodCalories.cleanString : ""
                        }

                    if let selectedFood, let servingName = selectedFood.defaultServingName, let servingGrams = selectedFood.defaultServingGrams {
                        Button {
                            servingGramsText = servingGrams.cleanString
                            valueText = selectedFood.calories(for: servingGrams).cleanString
                        } label: {
                            Label("使用常用份量：\(servingName) · \(servingGrams.cleanString)g", systemImage: "scalemass")
                                .font(.rounded(13, weight: .black))
                                .foregroundStyle(Color.punchBlack)
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("本次热量")
                        .font(.rounded(12, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                    Text(effectiveValue > 0 ? effectiveValue.calorieString : "选择道具或填写热量")
                        .font(.rounded(18, weight: .black))
                        .foregroundStyle(Color.ink)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.softBlockColor(for: .food))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var decisionCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("4. 现在就决定")
                    .font(.rounded(20, weight: .black))
                    .foregroundStyle(Color.ink)

                Button {
                    save(status: .resisted)
                } label: {
                    DecisionButtonLabel(title: "我忍住了", subtitle: "", systemImage: "checkmark.circle.fill", tint: .punchGreen, fill: .punchBlack, isDark: true)
                }
                .buttonStyle(PressableScaleStyle())
                .disabled(!canSave(.resisted))
                .opacity(canSave(.resisted) ? 1 : 0.45)

                Button {
                    save(status: .gaveIn)
                } label: {
                    DecisionButtonLabel(title: "我还是做了", subtitle: "", systemImage: "eye.fill", tint: .secondaryInk, fill: .cream)
                }
                .buttonStyle(PressableScaleStyle())
                .disabled(!canSave(.gaveIn))
                .opacity(canSave(.gaveIn) ? 1 : 0.45)
            }
        }
    }

    private var valuePlaceholder: String {
        switch selectedType {
        case .money: "例如 100"
        case .food: selectedTemplate?.defaultValue.map { "默认 \($0.cleanString)，可修改" } ?? "例如 420"
        case .time: "例如 60"
        }
    }

    private var unitText: String {
        switch selectedType {
        case .money: "¥"
        case .food: "kcal"
        case .time: "分钟"
        }
    }

    private var cooldownDurationText: String {
        switch selectedType {
        case .money: "24 小时"
        case .food: "10 分钟"
        case .time: "15 分钟"
        }
    }

    private var selectedFoodDetailText: String {
        guard let selectedFood else {
            return selectedTemplate?.defaultValueText ?? "kcal / 100g"
        }

        var parts = [
            "\(Int(selectedFood.energyKcalPer100g.rounded())) kcal / 100g",
            selectedFood.sourceName
        ]

        if let state = selectedFood.state {
            parts.insert(state, at: 0)
        }

        return parts.joined(separator: " · ")
    }

    private func save(status: ResistStatus) {
        guard canSave(status) else { return }
        UIApplication.shared.dismissKeyboard()
        if status == .resisted {
            AppHaptics.success()
        } else {
            AppHaptics.lightTap()
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedAt = status == .pending ? nil : Date()
        let cooldownUntil = status == .pending ? Date().addingTimeInterval(selectedType.cooldownSeconds) : nil
        let savedValue = effectiveValue
        let fallbackTemplate = isCustomPropSelected ? PropTemplate.customFallbackTemplate(for: selectedType) : nil
        let storedCustomImagePath = isCustomPropSelected ? LocalImageStore.save(customImage) : nil
        let storedPropIcon = selectedTemplate?.iconKey ?? fallbackTemplate?.iconKey
        let record = ResistRecord(
            type: selectedType,
            title: trimmedTitle,
            value: savedValue,
            hasEstimatedValue: hasEstimatedValue,
            status: status,
            reason: selectedReason,
            resolvedAt: resolvedAt,
            cooldownUntil: cooldownUntil,
            enteredCooldown: status == .pending,
            note: note,
            goalId: selectedGoalId,
            foodNutritionItemId: selectedFood?.id,
            foodSourceName: selectedFood?.sourceName,
            foodSourceVersion: selectedFood?.sourceVersion,
            foodServingGrams: selectedType == .food && selectedFood != nil ? parsedServingGrams : nil,
            foodEnergyKcalPer100g: selectedFood?.energyKcalPer100g,
            propTemplateId: selectedTemplate?.id,
            propIconKey: storedPropIcon,
            customImagePath: storedCustomImagePath
        )

        modelContext.insert(record)

        if status == .pending, cooldownUntil != nil {
            CooldownCoordinator.schedule(for: record)
        }

        let moment = completionMoment(for: status)
        if reduceMotion {
            completionMoment = moment
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                completionMoment = moment
            }
        }
        resetForm()

        if isModal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                dismiss()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            hideCompletionPopup()
        }
    }

    private func hideCompletionPopup() {
        if reduceMotion {
            completionMoment = nil
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                completionMoment = nil
            }
        }
    }

    private func resetForm() {
        title = ""
        valueText = ""
        note = ""
        selectedGoalId = nil
        selectedTemplate = nil
        isCustomPropSelected = false
        isPropPickerExpanded = false
        isDetailsExpanded = false
        customImage = nil
        customImageSource = nil
        selectedFood = nil
        servingGramsText = ""
    }

    private func selectTemplate(_ template: PropTemplate) {
        if selectedTemplate?.id == template.id {
            selectedTemplate = nil
            if title == template.title {
                title = ""
            }
            valueText = ""
            isPropPickerExpanded = false
            return
        }

        selectedTemplate = template
        isCustomPropSelected = false
        customImage = nil
        customImageSource = nil
        selectedFood = nil
        servingGramsText = ""
        title = template.title
        valueText = template.defaultValue?.cleanString ?? ""
        isPropPickerExpanded = false
    }

    private func togglePropPicker() {
        if reduceMotion {
            isPropPickerExpanded.toggle()
        } else {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
                isPropPickerExpanded.toggle()
            }
        }
    }

    private func toggleCustomProp() {
        if isCustomPropSelected {
            isCustomPropSelected = false
            customImage = nil
            customImageSource = nil
            if selectedTemplate == nil {
                title = ""
                valueText = ""
            }
            return
        }

        isCustomPropSelected = true
        selectedTemplate = nil
        selectedFood = nil
        servingGramsText = ""
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || PropTemplate.templates(for: selectedType).contains(where: { $0.title == title }) {
            title = ""
        }
        pulseIntro(.curious)
    }

    private func openCustomImageSource(_ source: CustomImageSource) {
        guard UIImagePickerController.isSourceTypeAvailable(source.sourceType) else { return }
        isCustomPropSelected = true
        selectedTemplate = nil
        customImageSource = source
    }

    private func completionMoment(for status: ResistStatus) -> MascotMoment {
        switch status {
        case .resisted: .resistedSuccess
        case .pending: .coolingSaved
        case .gaveIn: .gaveInSaved
        }
    }

    private func pulseIntro(_ expression: DynamicMascotExpression) {
        if reduceMotion {
            introExpression = expression
            return
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
            introExpression = expression
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.22)) {
                introExpression = .thinking
            }
        }
    }

}

private struct DecisionButtonLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var fill: Color = .cream
    var isDark = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.rounded(22, weight: .black))
                .foregroundStyle(isDark ? .white : .punchBlack)
                .frame(width: 38, height: 38)
                .background(tint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.rounded(18, weight: .black))
                    .foregroundStyle(isDark ? .white : .ink)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.rounded(12, weight: .bold))
                        .foregroundStyle(isDark ? .white.opacity(0.78) : .secondaryInk)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.punchBlack.opacity(isDark ? 0 : 1), lineWidth: isDark ? 0 : 2)
        }
    }
}

struct CameraImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    var onPick: () -> Void = {}

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.onPick()
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
