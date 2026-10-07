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
    @Query(sort: \ResistRecord.createdAt, order: .reverse) private var records: [ResistRecord]

    var isModal = false

    @State private var selectedType: ResistType = .money
    @State private var title = ""
    @State private var valueText = ""
    @State private var selectedReason = ""
    @State private var note = ""
    @State private var selectedGoalId: UUID?
    @State private var hasChosenGoal = false
    @State private var selectedTemplate: PropTemplate?
    @State private var isCustomPropSelected = false
    @State private var isShowingAllTemplates = false
    @State private var isDetailsExpanded = false
    @State private var customImage: UIImage?
    @State private var customImageSource: CustomImageSource?
    @State private var selectedFood: FoodNutritionItem?
    @State private var servingGramsText = ""
    @State private var completionMoment: MascotMoment?
    @State private var introReaction: MascotReaction?
    @State private var introReactionToken = 0
    @State private var isShowingFoodPicker = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isValueFocused: Bool
    @FocusState private var isNoteFocused: Bool
    @FocusState private var isServingFocused: Bool

    private var filteredGoals: [Goal] {
        goals.active.filter { $0.type == selectedType }
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

    private var isInputFocused: Bool {
        isTitleFocused || isValueFocused || isNoteFocused || isServingFocused
    }

    private var hasEstimatedValue: Bool {
        effectiveValue > 0
    }

    /// Only a name is needed; the amount can be filled in later from the record.
    private func canSave(_ status: ResistStatus) -> Bool {
        hasTitle
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
                .onTapGesture(perform: dismissInput)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    typePicker
                    itemCard
                    detailsCard
                    decisionCard
                }
                .padding(18)
            }
            .appScrollDefaults()
            .scrollDismissesKeyboard(.immediately)

            if let completionMoment {
                MascotFeedbackPopup(moment: completionMoment) {
                    hideCompletionPopup()
                }
            }
        }
        .navigationTitle("直接记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismissInput()
                        dismiss()
                    }
                }
            }
        }
        .appKeyboardDismissal(onDismiss: dismissInput)
        .onAppear(perform: synchronizeGoalSelection)
        .onChange(of: filteredGoals.map(\.id)) { _, _ in
            synchronizeGoalSelection()
        }
        .onChange(of: isInputFocused) { _, focused in
            if focused { introReaction = nil }
        }
        .task(id: introReactionToken) {
            guard let introReaction else { return }
            do {
                try await Task.sleep(for: .seconds(introReaction.duration))
            } catch {
                return
            }
            self.introReaction = nil
        }
        .onDisappear(perform: dismissInput)
        .onChange(of: isDetailsExpanded) { _, isExpanded in
            if !isExpanded { dismissInput() }
        }
        .onChange(of: selectedType) { _, newType in
            dismissInput()
            selectedReason = ""
            selectedGoalId = nil
            hasChosenGoal = false
            synchronizeGoalSelection()
            selectedTemplate = nil
            isCustomPropSelected = false
            isShowingAllTemplates = false
            customImage = nil
            customImageSource = nil
            selectedFood = nil
            servingGramsText = ""
            title = ""
            valueText = ""
            isDetailsExpanded = false
            completionMoment = nil
            pulseIntro(newType.selectionReaction)
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
        .fullScreenCover(item: $customImageSource) { source in
            CameraImagePicker(image: $customImage, sourceType: source.sourceType) {
                isCustomPropSelected = true
                selectedTemplate = nil
            }
            .ignoresSafeArea()
        }
    }

    private var typePicker: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("哪一类")
                    .font(.rounded(20, weight: .black))
                    .foregroundStyle(Color.ink)

                HStack(spacing: 10) {
                    ForEach(ResistType.allCases) { type in
                        Button {
                            if selectedType == type {
                                guard introReaction?.isPropInteraction != true else { return }
                                dismissInput()
                                pulseIntro(type.selectionReaction)
                            } else {
                                selectedType = type
                            }
                        } label: {
                            VStack(spacing: 8) {
                                TypeMascotBadge(
                                    type: type, size: 56,
                                    reaction: selectedType == type && introReaction?.isPropInteraction == true ? introReaction : nil,
                                    reactionToken: introReactionToken,
                                    isPaused: isInputFocused || completionMoment != nil || isShowingFoodPicker || customImageSource != nil
                                )
                                Text(type.urgeTitle)
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

    private static let collapsedTemplateCount = 7

    private let itemColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var orderedTemplates: [PropTemplate] {
        PropTemplate.templates(for: selectedType, orderedByUsageIn: records)
    }

    /// Two rows with "自填"; the chosen one is kept in view even if it sits further down the list.
    private var visibleTemplates: [PropTemplate] {
        guard !isShowingAllTemplates else { return orderedTemplates }
        var shown = Array(orderedTemplates.prefix(Self.collapsedTemplateCount))
        if let selectedTemplate, !shown.contains(selectedTemplate) {
            shown[shown.count - 1] = selectedTemplate
        }
        return shown
    }

    /// What it is and how much, in one card.
    private var itemCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(selectedType.urgeTitle)什么")
                        .font(.rounded(20, weight: .black))
                        .foregroundStyle(Color.ink)

                    Spacer()

                    if orderedTemplates.count > Self.collapsedTemplateCount {
                        Button {
                            toggleAllTemplates()
                        } label: {
                            HStack(spacing: 4) {
                                Text(isShowingAllTemplates ? "收起" : "更多")
                                Image(systemName: "chevron.down")
                                    .rotationEffect(.degrees(isShowingAllTemplates ? 180 : 0))
                            }
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.cream)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(PressableScaleStyle())
                        .accessibilityIdentifier("builtInPropToggle")
                    }
                }

                LazyVGrid(columns: itemColumns, spacing: 8) {
                    customTile
                    ForEach(visibleTemplates) { template in
                        itemTile(template)
                    }
                }

                if isCustomPropSelected {
                    customPropControls
                }

                valueField
            }
        }
    }

    /// Always first and inverted, as in the pause flow.
    private var customTile: some View {
        Button {
            toggleCustomProp()
        } label: {
            tileLabel(title: "自填", isSelected: isCustomPropSelected) {
                if let customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 52 * 0.28, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 52 * 0.28, style: .continuous)
                        .fill(Color.punchBlack)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: "pencil")
                                .font(.rounded(20, weight: .black))
                                .foregroundStyle(Color.white)
                        }
                }
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("自填")
        .accessibilityAddTraits(isCustomPropSelected ? .isSelected : [])
        .accessibilityIdentifier("customItemChip")
    }

    private func itemTile(_ template: PropTemplate) -> some View {
        let isSelected = selectedTemplate?.id == template.id
        return Button {
            selectTemplate(template)
            pulseIntro()
        } label: {
            tileLabel(title: template.title, isSelected: isSelected) {
                PropIconView(template: template, size: 52)
            }
        }
        .buttonStyle(PressableScaleStyle())
        .accessibilityLabel("选择\(template.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func tileLabel<Icon: View>(title: String, isSelected: Bool, @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: 6) {
            icon()

            Text(title)
                .font(.rounded(12, weight: .black))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(isSelected ? Color.softBlockColor(for: selectedType) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.punchBlack, lineWidth: isSelected ? 2 : 0)
        }
        .contentShape(Rectangle())
    }

    private var customPropControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppTextField(placeholder: customTitlePlaceholder, text: $title, focus: $isTitleFocused)

            HStack(spacing: 10) {
                photoButton(title: "相册", systemImage: "photo.fill", source: .photoLibrary)
                photoButton(
                    title: UIImagePickerController.isSourceTypeAvailable(.camera) ? "拍照" : "真机拍照",
                    systemImage: "camera.fill",
                    source: .camera
                )
            }
        }
    }

    private func photoButton(title: String, systemImage: String, source: CustomImageSource) -> some View {
        let isAvailable = UIImagePickerController.isSourceTypeAvailable(source.sourceType)
        return Button {
            openCustomImageSource(source)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.rounded(14, weight: .black))
                .foregroundStyle(Color.punchBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cream)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableScaleStyle())
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.45)
    }

    private var customTitlePlaceholder: String {
        switch selectedType {
        case .money: "比如：香水、衣服、手表"
        case .food: "比如：奶茶、炸鸡、甜品"
        case .time: "比如：刷视频、闲聊、拖延"
        }
    }

    /// In plain sight, but never required: a record without a number shows "待补充" and can be
    /// filled in later.
    private var valueField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(selectedType.valueTitle) · \(unitText)")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.fieldLabelInk)

                // A built-in default is for a stated serving; say which.
                if let selectedTemplate, selectedTemplate.defaultValue != nil {
                    Text(selectedTemplate.caption)
                        .font(.rounded(12, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                Text("选填")
                    .font(.rounded(12, weight: .bold))
                    .foregroundStyle(Color.secondaryInk)
            }

            AppTextField(placeholder: valuePlaceholder, text: $valueText, keyboardType: .decimalPad, focus: $isValueFocused)

            HStack(spacing: 8) {
                ForEach(selectedType.quickValues, id: \.self) { value in
                    Button {
                        AppHaptics.lightTap()
                        dismissInput()
                        selectedFood = nil
                        servingGramsText = ""
                        valueText = value.cleanString
                    } label: {
                        Text(value.displayValue(for: selectedType))
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.punchBlack)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.softBlockColor(for: selectedType))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
        }
    }

    private var detailsCard: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    dismissInput()
                    if reduceMotion {
                        isDetailsExpanded.toggle()
                    } else {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                            isDetailsExpanded.toggle()
                        }
                    }
                } label: {
                    HStack {
                        Text("补充信息")
                            .font(.rounded(20, weight: .black))
                            .foregroundStyle(Color.ink)

                        Spacer()

                        Text("可选")
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
                    }

                    goalPicker

                    VStack(alignment: .leading, spacing: 8) {
                        Text("此刻的原因")
                            .font(.rounded(15, weight: .black))
                            .foregroundStyle(Color.fieldLabelInk)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                            ForEach(selectedType.reasons, id: \.self) { reason in
                                let isSelected = selectedReason == reason
                                Button {
                                    dismissInput()
                                    // Tapping the chosen one again clears it.
                                    selectedReason = isSelected ? "" : reason
                                } label: {
                                    Text(reason)
                                        .font(.rounded(14, weight: .black))
                                        .foregroundStyle(isSelected ? .white : .punchBlack)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background(isSelected ? Color.punchBlack : Color.cream)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PressableScaleStyle())
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                            reservesSpace: true,
                            focus: $isNoteFocused
                        )
                    }
                }
            }
        }
    }

    /// Working the calories out from the local food table instead of typing them.
    private var foodDatabaseFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("本地食物库")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.fieldLabelInk)

                Button {
                    dismissInput()
                    isShowingFoodPicker = true
                } label: {
                    HStack(spacing: 12) {
                        TypeIcon(type: .food, size: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedFood?.name ?? "按克数精确计算")
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

                    AppTextField(placeholder: "例如 150", text: $servingGramsText, keyboardType: .decimalPad, focus: $isServingFocused)
                        .onChange(of: servingGramsText) { _, _ in
                            guard selectedFood != nil else { return }
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
        }
    }

    private var decisionCard: some View {
        VStack(spacing: 10) {
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
                DecisionButtonLabel(title: "我还是做了", subtitle: "", systemImage: "eye.fill", tint: .cream, fill: .cardBackground)
            }
            .buttonStyle(PressableScaleStyle())
            .disabled(!canSave(.gaveIn))
            .opacity(canSave(.gaveIn) ? 1 : 0.45)

            Button {
                save(status: .pending)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "archivebox.fill")
                    Text("放进冷静箱 · \(cooldownDurationText)")
                }
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.punchBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.softBlockColor(for: selectedType))
                .clipShape(Capsule())
            }
            .buttonStyle(PressableScaleStyle())
            .disabled(!canSave(.pending))
            .opacity(canSave(.pending) ? 1 : 0.45)
            .accessibilityIdentifier("recordPendingButton")
        }
    }

    private func toggleAllTemplates() {
        dismissInput()
        AppHaptics.lightTap()
        if reduceMotion {
            isShowingAllTemplates.toggle()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                isShowingAllTemplates.toggle()
            }
        }
    }

    @ViewBuilder
    private var goalPicker: some View {
        if !filteredGoals.isEmpty {
            GoalMenuRow(goals: filteredGoals, selection: $selectedGoalId) {
                hasChosenGoal = true
                dismissInput()
            }
        }
    }

    private var valuePlaceholder: String {
        switch selectedType {
        case .money: "例如 100，可以先不填"
        case .food: selectedTemplate?.defaultValue.map { "默认 \($0.cleanString)，可修改" } ?? "例如 420，可以先不填"
        case .time: "例如 60，可以先不填"
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
        selectedType.cooldownDurationText
    }

    private var selectedFoodDetailText: String {
        guard let selectedFood else {
            return "从食物库里选，再填克数"
        }

        var parts = [
            "\(Int(selectedFood.energyKcalPer100g.rounded())) kcal / 100g",
            FoodSeedData.displaySource(selectedFood.sourceName)
        ]

        if let state = selectedFood.state {
            parts.insert(state, at: 0)
        }

        return parts.joined(separator: " · ")
    }

    private func save(status: ResistStatus) {
        dismissInput()
        guard canSave(status) else { return }
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
            goalId: filteredGoals.contains(where: { $0.id == selectedGoalId }) ? selectedGoalId : nil,
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
        dismissInput()
        title = ""
        valueText = ""
        note = ""
        selectedReason = ""
        selectedGoalId = nil
        hasChosenGoal = false
        synchronizeGoalSelection()
        selectedTemplate = nil
        isCustomPropSelected = false
        isShowingAllTemplates = false
        isDetailsExpanded = false
        customImage = nil
        customImageSource = nil
        selectedFood = nil
        servingGramsText = ""
    }

    private func dismissInput() {
        isTitleFocused = false
        isValueFocused = false
        isNoteFocused = false
        isServingFocused = false
        UIApplication.shared.dismissKeyboard()
    }

    private func synchronizeGoalSelection() {
        if hasChosenGoal {
            // Preserve an explicit opt-out and never reroute a deleted or incompatible goal.
            if let selectedGoalId, !filteredGoals.contains(where: { $0.id == selectedGoalId }) {
                self.selectedGoalId = nil
            }
            return
        }
        selectedGoalId = StatsCalculator.suggestedGoalId(for: selectedType, goals: goals, records: records)
    }

    private func selectTemplate(_ template: PropTemplate) {
        dismissInput()
        if selectedTemplate?.id == template.id {
            selectedTemplate = nil
            if title == template.title {
                title = ""
            }
            valueText = ""
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
    }

    private func toggleCustomProp() {
        dismissInput()
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
        pulseIntro()
    }

    private func openCustomImageSource(_ source: CustomImageSource) {
        guard UIImagePickerController.isSourceTypeAvailable(source.sourceType) else { return }
        dismissInput()
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

    /// Sets off a reaction on the three type badges.
    private func pulseIntro(_ reaction: MascotReaction = .acknowledge) {
        introReaction = reaction
        introReactionToken += 1
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
