import Foundation

enum FoodSeedData {
    static let sourceName = "USDA FoodData Central / 内置启动种子库"
    static let sourceVersion = "FDC public domain seed, v0.1"

    static let items: [FoodNutritionItem] = [
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
            name: "白米饭",
            aliases: ["米饭", "熟米饭", "rice"],
            category: "主食",
            energyKcalPer100g: 130,
            defaultServingName: "1 碗",
            defaultServingGrams: 150,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "熟",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
            name: "鸡蛋",
            aliases: ["水煮蛋", "蛋", "egg"],
            category: "蛋类",
            energyKcalPer100g: 155,
            defaultServingName: "1 个",
            defaultServingGrams: 50,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "全蛋",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
            name: "苹果",
            aliases: ["apple"],
            category: "水果",
            energyKcalPer100g: 52,
            defaultServingName: "1 个",
            defaultServingGrams: 180,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "带皮生食",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004")!,
            name: "香蕉",
            aliases: ["banana"],
            category: "水果",
            energyKcalPer100g: 89,
            defaultServingName: "1 根",
            defaultServingGrams: 118,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "生食",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005")!,
            name: "牛奶",
            aliases: ["全脂牛奶", "milk"],
            category: "乳制品",
            energyKcalPer100g: 61,
            defaultServingName: "250 ml",
            defaultServingGrams: 250,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "全脂",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000006")!,
            name: "鸡胸肉",
            aliases: ["鸡肉", "chicken breast"],
            category: "肉类",
            energyKcalPer100g: 165,
            defaultServingName: "1 份",
            defaultServingGrams: 120,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "熟，去皮",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000007")!,
            name: "面包",
            aliases: ["白面包", "bread"],
            category: "主食",
            energyKcalPer100g: 265,
            defaultServingName: "1 片",
            defaultServingGrams: 30,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "白面包",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000008")!,
            name: "薯片",
            aliases: ["potato chips", "零食"],
            category: "零食",
            energyKcalPer100g: 536,
            defaultServingName: "1 小包",
            defaultServingGrams: 50,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "普通原味",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000009")!,
            name: "可乐",
            aliases: ["cola", "含糖可乐"],
            category: "饮品",
            energyKcalPer100g: 42,
            defaultServingName: "330 ml",
            defaultServingGrams: 330,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "含糖",
            isVerified: true
        ),
        FoodNutritionItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000010")!,
            name: "炸鸡",
            aliases: ["fried chicken", "鸡块"],
            category: "快餐",
            energyKcalPer100g: 260,
            defaultServingName: "1 份",
            defaultServingGrams: 160,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            state: "裹粉油炸",
            isVerified: true
        )
    ]
}
