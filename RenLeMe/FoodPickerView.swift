import SwiftData
import SwiftUI

struct FoodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodNutritionItem.name, order: .forward) private var foods: [FoodNutritionItem]
    @State private var query = ""

    let onSelect: (FoodNutritionItem) -> Void

    private var filteredFoods: [FoodNutritionItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return foods }

        return foods.filter { item in
            item.searchableText.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PunchyCard(fill: .punchPink, cornerRadius: 34, padding: 20) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Food")
                                    .font(.rounded(42, weight: .black))
                                    .foregroundStyle(Color.white)
                                Text("选一个可信来源，再填份量。")
                                    .font(.rounded(16, weight: .black))
                                    .foregroundStyle(Color.white.opacity(0.78))
                            }

                            Spacer()

                            MascotMomentView(moment: .idle, size: 78)
                        }
                    }

                    if filteredFoods.isEmpty {
                        PunchyCard(fill: .cardBackground) {
                            VStack(alignment: .leading, spacing: 12) {
                                EmptyStateView(title: "本地库里还没有这个食物", message: "可以先用食物模板的默认热量，或者之后把它补充到本地数据库。", systemImage: "tray")
                                StatusChip(title: "本地库 · 轻量记录", fill: .punchBlack)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredFoods) { food in
                                Button {
                                    onSelect(food)
                                    dismiss()
                                } label: {
                                    FoodSearchRow(food: food)
                                }
                                .buttonStyle(PressableScaleStyle())
                            }
                        }
                    }

                    Text("热量来自本地食物库或已确认来源。找不到的食物不会自动计入热量资产。")
                        .font(.rounded(13, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }
            .appScrollDefaults()
        }
        .navigationTitle("食物数据库")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "搜索食物、别名或分类")
    }
}

private struct FoodSearchRow: View {
    let food: FoodNutritionItem

    var body: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 26, padding: 12) {
            HStack(spacing: 12) {
                TypeIcon(type: .food, size: 46)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(food.name)
                            .font(.rounded(18, weight: .black))
                            .foregroundStyle(Color.ink)

                        if food.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.rounded(14, weight: .black))
                                .foregroundStyle(Color.punchGreen)
                        }
                    }

                    Text(foodDetailText)
                        .font(.rounded(12, weight: .bold))
                        .foregroundStyle(Color.secondaryInk)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(food.energyKcalPer100g.rounded()))")
                        .font(.rounded(24, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                    Text("kcal")
                        .font(.rounded(12, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                }
            }
        }
    }

    private var foodDetailText: String {
        var parts = [food.category]
        if let state = food.state {
            parts.append(state)
        }
        parts.append("每 100g")
        parts.append(food.sourceName)
        return parts.joined(separator: " · ")
    }
}
