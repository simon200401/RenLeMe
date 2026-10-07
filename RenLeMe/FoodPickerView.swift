import SwiftData
import SwiftUI

struct FoodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodNutritionItem.name, order: .forward) private var foods: [FoodNutritionItem]
    @State private var query = ""
    /// Folded, a kind shows its first few; this keeps the page short while still showing what is in it.
    private static let previewCount = 3

    @State private var expanded: Set<String> = []

    let onSelect: (FoodNutritionItem) -> Void

    private var filteredFoods: [FoodNutritionItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return foods }

        return foods.filter { item in
            item.searchableText.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    /// By kind, in the table's own order; anything with an unknown kind goes last.
    private var sections: [(title: String, foods: [FoodNutritionItem])] {
        let grouped = Dictionary(grouping: filteredFoods, by: \.category)
        let known = FoodSeedData.categories.filter { grouped[$0] != nil }
        let others = grouped.keys.filter { !FoodSeedData.categories.contains($0) }.sorted()
        // Within a kind, the table's own order puts the everyday ones first, so those are the ones
        // that show while it is folded.
        let rank = Dictionary(uniqueKeysWithValues: FoodSeedData.entries.enumerated().map { ($1.id, $0) })
        return (known + others).map { title in
            let foods = (grouped[title] ?? []).sorted {
                (rank[$0.id] ?? .max, $0.name) < (rank[$1.id] ?? .max, $1.name)
            }
            return (title: title, foods: foods)
        }
    }

    /// While searching everything is open, so a match is never hidden in a folded section.
    private func isExpanded(_ title: String) -> Bool {
        isSearching || expanded.contains(title)
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        // Nothing to unfold when the whole kind already fits in the preview.
        let canFold = !isSearching && count > Self.previewCount

        return Button {
            AppHaptics.lightTap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                if expanded.contains(title) {
                    expanded.remove(title)
                } else {
                    expanded.insert(title)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.rounded(18, weight: .black))
                    .foregroundStyle(Color.ink)

                Text("\(count)")
                    .font(.rounded(13, weight: .black))
                    .foregroundStyle(Color.secondaryInk)

                Spacer()

                if canFold {
                    Image(systemName: "chevron.down")
                        .font(.rounded(14, weight: .black))
                        .foregroundStyle(Color.punchBlack)
                        .rotationEffect(.degrees(isExpanded(title) ? 180 : 0))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableScaleStyle())
        .disabled(!canFold)
        .accessibilityLabel("\(title)，\(count) 种")
        .accessibilityValue(canFold ? (isExpanded(title) ? "已展开" : "只显示前 \(Self.previewCount) 种") : "")
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if filteredFoods.isEmpty {
                        PunchyCard(fill: .cardBackground, cornerRadius: 24) {
                            EmptyStateView(title: "没找到", message: "可以返回直接填热量", systemImage: "tray")
                        }
                    } else {
                        ForEach(sections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(section.title, count: section.foods.count)

                                ForEach(isExpanded(section.title) ? section.foods : Array(section.foods.prefix(Self.previewCount))) { food in
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

                        // Said once for the whole list instead of on every row.
                        Text("每 100 克的热量，数据来自《中国食物成分表标准版（第6版）》和 USDA FoodData Central；份量是常见的大概值。选好后填克数，自动算出这一次的热量。")
                            .font(.rounded(12, weight: .bold))
                            .foregroundStyle(Color.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 6)
                    }

                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
            .appScrollDefaults()
        }
        .navigationTitle("食物库")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "搜索食物")
    }
}

private struct FoodSearchRow: View {
    let food: FoodNutritionItem

    var body: some View {
        PunchyCard(fill: .cardBackground, cornerRadius: 24, padding: 12) {
            HStack(spacing: 12) {
                // The same drawing the item has everywhere else, where there is one.
                if let template = PropTemplate.matching(type: .food, exactTitle: food.name) {
                    PropIconView(template: template, size: 46)
                } else {
                    TypeIcon(type: .food, size: 46)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(food.name)
                        .font(.rounded(18, weight: .black))
                        .foregroundStyle(Color.ink)

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
                    Text("kcal / 100g")
                        .font(.rounded(12, weight: .black))
                        .foregroundStyle(Color.secondaryInk)
                }
            }
        }
    }

    private var foodDetailText: String {
        var parts: [String] = []
        if let state = food.state {
            parts.append(state)
        }
        if let servingName = food.defaultServingName, let grams = food.defaultServingGrams {
            parts.append("\(servingName)约 \(grams.cleanString)g")
        }
        return parts.joined(separator: " · ")
    }
}
