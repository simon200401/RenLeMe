import SwiftData
import SwiftUI

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]

    let record: ResistRecord

    @State private var title: String
    @State private var valueText: String
    @State private var selectedStatus: ResistStatus
    @State private var selectedReason: String
    @State private var note: String
    @State private var selectedGoalId: UUID?
    @State private var selectedFood: FoodNutritionItem?
    @State private var servingGramsText: String
    @State private var isShowingFoodPicker = false

    init(record: ResistRecord) {
        self.record = record
        _title = State(initialValue: record.title)
        _valueText = State(initialValue: record.value.cleanString)
        _selectedStatus = State(initialValue: record.status)
        _selectedReason = State(initialValue: record.reason)
        _note = State(initialValue: record.note)
        _selectedGoalId = State(initialValue: record.goalId)
        _selectedFood = State(initialValue: nil)
        _servingGramsText = State(initialValue: record.foodServingGrams?.cleanString ?? "")
    }

    private var filteredGoals: [Goal] {
        goals.filter { $0.type == record.type }
    }

    private var parsedValue: Double {
        Double(valueText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var parsedServingGrams: Double {
        Double(servingGramsText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var selectedFoodEnergyKcalPer100g: Double {
        selectedFood?.energyKcalPer100g ?? record.foodEnergyKcalPer100g ?? 0
    }

    private var calculatedFoodCalories: Double {
        guard record.type == .food, parsedServingGrams > 0, selectedFoodEnergyKcalPer100g > 0 else { return 0 }
        return selectedFoodEnergyKcalPer100g * parsedServingGrams / 100
    }

    private var canSave: Bool {
        if record.type == .food {
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && calculatedFoodCalories > 0
        }

        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedValue > 0
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PunchyCard(fill: Color.blockColor(for: record.type), cornerRadius: 34, padding: 20) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Edit")
                                    .font(.rounded(42, weight: .black))
                                    .foregroundStyle(record.type == .time ? Color.punchBlack : .white)
                            }
                            Spacer()
                            MascotMomentView(moment: record.status.mascotMoment, size: 78)
                        }
                    }

                    PunchyCard(fill: .cardBackground, cornerRadius: 30, padding: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            if record.type == .food {
                                foodFields
                            } else {
                                standardFields
                            }

                            chipGroup(title: "状态", selection: $selectedStatus, options: ResistStatus.allCases)
                            reasonGroup

                            if !filteredGoals.isEmpty {
                                Picker("投向目标", selection: $selectedGoalId) {
                                    Text("暂不关联").tag(UUID?.none)
                                    ForEach(filteredGoals) { goal in
                                        Text(goal.title).tag(Optional(goal.id))
                                    }
                                }
                            }

                            labeledField("备注") {
                                TextField("给自己留一句话", text: $note, axis: .vertical)
                                    .appInputTextStyle()
                                    .lineLimit(3, reservesSpace: true)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("编辑记录")
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
                    save()
                    dismiss()
                }
                .disabled(!canSave)
                .font(.rounded(15, weight: .black))
            }
        }
        .sheet(isPresented: $isShowingFoodPicker) {
            NavigationStack {
                FoodPickerView { food in
                    selectedFood = food
                    title = food.name
                    if let grams = food.defaultServingGrams {
                        servingGramsText = grams.cleanString
                        valueText = food.calories(for: grams).cleanString
                    } else {
                        servingGramsText = ""
                        valueText = ""
                    }
                }
            }
        }
    }

    private var standardFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            labeledField(record.type.fieldTitle) {
                TextField("名称", text: $title)
                    .appInputTextStyle()
                    .textInputAutocapitalization(.never)
            }

            labeledField("\(record.type.valueTitle) · \(record.type == .money ? "¥" : "分钟")") {
                TextField("数值", text: $valueText)
                    .appInputTextStyle()
                    .keyboardType(.decimalPad)
            }
        }
    }

    private var foodFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("食物")
                    .font(.rounded(15, weight: .black))
                    .foregroundStyle(Color.secondaryInk)

                Button {
                    isShowingFoodPicker = true
                } label: {
                    HStack(spacing: 12) {
                        TypeIcon(type: .food, size: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.rounded(17, weight: .black))
                                .foregroundStyle(Color.ink)

                            Text(foodSourceText)
                                .font(.rounded(12, weight: .bold))
                                .foregroundStyle(Color.secondaryInk)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.rounded(13, weight: .black))
                            .foregroundStyle(Color.secondaryInk)
                    }
                    .padding(12)
                    .background(Color.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(PressableScaleStyle())
            }

            labeledField("这次的份量 · g") {
                TextField("例如 150", text: $servingGramsText)
                    .appInputTextStyle()
                    .keyboardType(.decimalPad)
                    .onChange(of: servingGramsText) { _, _ in
                        valueText = calculatedFoodCalories > 0 ? calculatedFoodCalories.cleanString : valueText
                    }
            }

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("本次热量")
                        .font(.rounded(12, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                    Text(calculatedFoodCalories > 0 ? calculatedFoodCalories.calorieString : valueText.calorieFallbackText)
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

    private var reasonGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("原因")
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.secondaryInk)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(record.type.reasons, id: \.self) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        Text(reason)
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(selectedReason == reason ? .white : .punchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(selectedReason == reason ? Color.punchBlack : Color.cream)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                }
            }
        }
    }

    private func chipGroup<Option: CaseIterable & Identifiable & Hashable & StatusTitle>(
        title: String,
        selection: Binding<Option>,
        options: Option.AllCases
    ) -> some View where Option.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rounded(15, weight: .black))
                .foregroundStyle(Color.secondaryInk)

            HStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option.title)
                            .font(.rounded(14, weight: .black))
                            .foregroundStyle(selection.wrappedValue == option ? .white : .punchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(selection.wrappedValue == option ? Color.punchBlack : Color.cream)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableScaleStyle())
                }
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

    private var foodSourceText: String {
        if let selectedFood {
            return "\(Int(selectedFood.energyKcalPer100g.rounded())) kcal / 100g · \(selectedFood.sourceName)"
        }

        if let energy = record.foodEnergyKcalPer100g, let source = record.foodSourceName {
            return "\(energy.cleanString) kcal / 100g · \(source)"
        }

        return "可以重新从本地食物库选择。"
    }

    private func save() {
        record.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        record.status = selectedStatus
        record.reason = selectedReason
        record.note = note
        record.goalId = selectedGoalId
        if let template = PropTemplate.matching(type: record.type, title: record.title) {
            record.propTemplateId = template.id
            record.propIconKey = template.iconKey
        }

        if selectedStatus == .pending {
            record.resolvedAt = nil
            record.cooldownUntil = Date().addingTimeInterval(record.type.cooldownSeconds)
            record.enteredCooldown = true
        } else if record.resolvedAt == nil {
            record.resolvedAt = .now
            record.cooldownUntil = nil
        } else {
            record.cooldownUntil = nil
        }

        if record.type == .food {
            record.value = calculatedFoodCalories > 0 ? calculatedFoodCalories : parsedValue
            record.foodServingGrams = parsedServingGrams > 0 ? parsedServingGrams : record.foodServingGrams
            if let selectedFood {
                record.foodNutritionItemId = selectedFood.id
                record.foodSourceName = selectedFood.sourceName
                record.foodSourceVersion = selectedFood.sourceVersion
                record.foodEnergyKcalPer100g = selectedFood.energyKcalPer100g
            }
        } else {
            record.value = parsedValue
        }
    }
}

private protocol StatusTitle {
    var title: String { get }
}

extension ResistStatus: StatusTitle {}

private extension String {
    var calorieFallbackText: String {
        guard let value = Double(replacingOccurrences(of: ",", with: "")), value > 0 else {
            return "填写份量后自动计算"
        }

        return value.calorieString
    }
}
