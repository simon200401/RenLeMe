import Foundation
import SwiftData

/// The built-in food table: energy per 100 g for things people commonly crave, each with the entry it
/// was taken from so it can be checked.
///
/// - `usda` rows are from the SR Legacy release of USDA FoodData Central; the reference is the FDC ID.
/// - `chinaTable` rows are from 《中国食物成分表标准版（第6版）》; the reference is the food code in the
///   book. They were read from a third party's transcription of the book, not from the printed tables.
/// - Serving sizes are everyday estimates, not from either source.
///
/// Mixed dishes that vary too much to have one number (hotpot, takeaway, milk tea) are left out on
/// purpose: the user types those in.
enum FoodSeedData {
    static let usda = "USDA FoodData Central"
    static let chinaTable = "中国食物成分表标准版（第6版）"

    /// Raise this whenever `entries` changes, so installs pick the changes up on next launch.
    static let version = 2
    static let versionKey = "foodSeedVersion"

    /// The order sections appear in on the picker.
    static let categories = ["主食", "快餐", "零食", "坚果", "甜品", "饮料", "肉蛋", "乳制品", "水果"]

    struct Entry {
        /// Fixed once given: it becomes the row's id, and records point at it.
        let number: Int
        let name: String
        let aliases: [String]
        let category: String
        let state: String?
        let energyKcalPer100g: Double
        let servingName: String
        let servingGrams: Double
        let source: String
        let sourceFoodId: String

        init(
            _ number: Int, _ name: String, _ aliases: [String], _ category: String, _ state: String?,
            _ energyKcalPer100g: Double, _ servingName: String, _ servingGrams: Double,
            _ source: String, _ sourceFoodId: String
        ) {
            self.number = number
            self.name = name
            self.aliases = aliases
            self.category = category
            self.state = state
            self.energyKcalPer100g = energyKcalPer100g
            self.servingName = servingName
            self.servingGrams = servingGrams
            self.source = source
            self.sourceFoodId = sourceFoodId
        }

        var id: UUID {
            UUID(uuidString: String(format: "A0000000-0000-0000-0000-%012d", number))!
        }
    }

    static let entries: [Entry] = [
        Entry(1, "白米饭", ["米饭", "rice"], "主食", "蒸", 116, "1 碗", 150, chinaTable, "012401x"),
        Entry(11, "馒头", ["mantou"], "主食", nil, 223, "1 个", 100, chinaTable, "011404x"),
        Entry(12, "油条", [], "主食", nil, 388, "1 根", 70, chinaTable, "011409"),
        Entry(13, "烧饼", [], "主食", "加糖", 298, "1 个", 80, chinaTable, "011407"),
        Entry(14, "面条", ["汤面", "noodles"], "主食", "煮熟", 107, "1 碗", 250, chinaTable, "011317"),
        Entry(15, "白粥", ["大米粥", "稀饭"], "主食", nil, 46, "1 碗", 250, chinaTable, "012404"),
        Entry(16, "玉米", ["甜玉米", "corn"], "主食", "鲜", 112, "1 根", 150, chinaTable, "013101"),
        Entry(7, "面包", ["白面包", "吐司", "bread"], "主食", "白面包", 266, "1 片", 30, usda, "FDC 174924"),
        Entry(17, "牛角包", ["可颂", "croissant"], "主食", "黄油", 406, "1 个", 60, usda, "FDC 174987"),
        Entry(18, "意面", ["意大利面", "pasta"], "主食", "煮熟，不含酱", 158, "1 盘", 200, usda, "FDC 169737"),
        Entry(19, "炒饭", ["蛋炒饭"], "主食", "中餐馆，无肉", 174, "1 盘", 300, usda, "FDC 167668"),
        Entry(20, "方便面", ["泡面", "ramen"], "主食", "面饼和调料，未泡", 440, "1 包", 85, usda, "FDC 171177"),
        Entry(10, "炸鸡", ["fried chicken"], "快餐", "裹粉油炸，带皮", 289, "2 块", 150, usda, "FDC 171448"),
        Entry(21, "炸鸡翅", ["鸡翅"], "快餐", "带皮带裹粉", 310, "2 个", 80, usda, "FDC 170360"),
        Entry(22, "薯条", ["fries"], "快餐", nil, 312, "中份", 110, usda, "FDC 170698"),
        Entry(23, "汉堡", ["burger", "牛肉汉堡"], "快餐", "单层牛肉，含酱料", 263, "1 个", 110, usda, "FDC 170694"),
        Entry(24, "披萨", ["pizza"], "快餐", "芝士，普通饼底", 266, "1 片", 110, usda, "FDC 173292"),
        Entry(25, "洋葱圈", [], "快餐", "裹粉油炸", 411, "1 份", 90, usda, "FDC 170697"),
        Entry(8, "薯片", ["chips"], "零食", "原味", 532, "1 小包", 50, usda, "FDC 169677"),
        Entry(26, "爆米花", ["popcorn"], "零食", "油爆，加盐", 500, "1 小桶", 50, usda, "FDC 170247"),
        Entry(27, "苏打饼干", ["饼干", "crackers"], "零食", nil, 418, "5 片", 15, usda, "FDC 172746"),
        Entry(28, "曲奇", ["巧克力曲奇", "cookie", "饼干"], "零食", "巧克力豆", 492, "2 块", 30, usda, "FDC 172716"),
        Entry(29, "牛奶巧克力", ["巧克力", "chocolate"], "零食", nil, 535, "1 排", 43, usda, "FDC 167587"),
        Entry(30, "硬糖", ["糖果", "水果糖"], "零食", nil, 394, "3 颗", 15, usda, "FDC 167990"),
        Entry(31, "棉花糖", [], "零食", nil, 318, "5 颗", 35, usda, "FDC 167995"),
        Entry(32, "牛肉干", [], "零食", nil, 550, "1 小包", 30, chinaTable, "082303"),
        Entry(33, "猪肉脯", ["肉脯"], "零食", nil, 378, "1 小包", 30, chinaTable, "081325"),
        Entry(34, "火腿肠", [], "零食", nil, 212, "1 根", 60, chinaTable, "081409"),
        Entry(35, "豆腐干", ["豆干"], "零食", nil, 197, "1 小包", 50, chinaTable, "031510x"),
        Entry(36, "葡萄干", [], "零食", nil, 344, "1 小把", 30, chinaTable, "063107"),
        Entry(37, "红枣", ["干枣", "大枣"], "零食", "干", 276, "5 颗", 30, chinaTable, "062302"),
        Entry(38, "瓜子", ["葵花子"], "坚果", "炒，咸，去壳后", 625, "1 小把", 25, chinaTable, "072007"),
        Entry(39, "花生", ["花生米", "花生仁"], "坚果", "炒", 589, "1 把", 30, chinaTable, "072005"),
        Entry(40, "核桃", [], "坚果", "干", 646, "2 个", 20, chinaTable, "071004"),
        Entry(41, "腰果", [], "坚果", "熟", 615, "1 把", 30, chinaTable, "071036"),
        Entry(42, "开心果", [], "坚果", "熟，去壳后", 631, "1 把", 30, chinaTable, "071039"),
        Entry(43, "杏仁", ["巴旦木"], "坚果", "烤，加盐", 617, "1 把", 30, chinaTable, "071021"),
        Entry(44, "板栗", ["栗子", "糖炒栗子"], "坚果", "熟", 214, "5 颗", 50, chinaTable, "071010"),
        Entry(45, "花生酱", [], "坚果", "柔滑型", 598, "1 勺", 16, usda, "FDC 174266"),
        Entry(46, "甜甜圈", ["donut"], "甜品", "糖霜", 421, "1 个", 60, usda, "FDC 172758"),
        Entry(47, "巧克力蛋糕", ["蛋糕", "cake"], "甜品", "带巧克力糖霜", 389, "1 块", 100, usda, "FDC 174934"),
        Entry(48, "芝士蛋糕", ["蛋糕", "cheesecake"], "甜品", nil, 321, "1 块", 100, usda, "FDC 172711"),
        Entry(49, "冰淇淋", ["雪糕", "ice cream"], "甜品", "香草", 207, "1 球", 70, usda, "FDC 167575"),
        Entry(50, "巧克力冰淇淋", ["雪糕"], "甜品", nil, 216, "1 球", 70, usda, "FDC 168809"),
        Entry(51, "甜筒", ["圆筒冰淇淋"], "甜品", "香草软冰淇淋带脆筒", 163, "1 个", 100, usda, "FDC 173274"),
        Entry(52, "泡芙", ["闪电泡芙"], "甜品", "奶油夹心，带淋面", 334, "1 个", 60, usda, "FDC 167534"),
        Entry(53, "布朗尼", ["brownie"], "甜品", nil, 405, "1 块", 60, usda, "FDC 172713"),
        Entry(54, "华夫饼", ["waffle"], "甜品", "原味", 291, "1 块", 75, usda, "FDC 175039"),
        Entry(55, "玛芬", ["麦芬", "muffin"], "甜品", "蓝莓", 375, "1 个", 110, usda, "FDC 172765"),
        Entry(56, "苹果派", [], "甜品", nil, 237, "1 块", 120, usda, "FDC 175011"),
        Entry(57, "巧克力布丁", ["布丁"], "甜品", "即食", 142, "1 杯", 110, usda, "FDC 168778"),
        Entry(58, "蜂蜜", [], "甜品", nil, 304, "1 勺", 20, usda, "FDC 169640"),
        Entry(9, "可乐", ["cola", "汽水"], "饮料", "含糖", 42, "1 罐", 330, usda, "FDC 174852"),
        Entry(59, "橙汁", ["果汁"], "饮料", "鲜榨", 45, "1 杯", 250, usda, "FDC 169098"),
        Entry(60, "冰红茶", ["柠檬茶"], "饮料", "含糖，瓶装", 45, "1 瓶", 500, usda, "FDC 171888"),
        Entry(61, "能量饮料", ["功能饮料"], "饮料", "含糖", 45, "1 罐", 250, usda, "FDC 174108"),
        Entry(62, "豆浆", [], "饮料", "无糖", 31, "1 杯", 300, chinaTable, "031405"),
        Entry(63, "啤酒", ["beer"], "饮料", nil, 43, "1 瓶", 500, usda, "FDC 168746"),
        Entry(64, "红酒", ["葡萄酒", "wine"], "饮料", nil, 85, "1 杯", 150, usda, "FDC 173190"),
        Entry(65, "烈酒", ["白酒", "威士忌", "伏特加"], "饮料", "40 度", 231, "1 小杯", 50, usda, "FDC 174815"),
        Entry(2, "鸡蛋", ["水煮蛋", "egg"], "肉蛋", "煮", 143, "1 个", 50, chinaTable, "111204"),
        Entry(66, "煎蛋", ["荷包蛋"], "肉蛋", "油煎", 195, "1 个", 50, chinaTable, "111206"),
        Entry(67, "皮蛋", ["松花蛋"], "肉蛋", nil, 171, "1 个", 60, chinaTable, "112201"),
        Entry(6, "鸡胸肉", ["chicken breast"], "肉蛋", "烤，去皮", 165, "1 块", 120, usda, "FDC 171477"),
        Entry(68, "香肠", [], "肉蛋", nil, 508, "1 根", 50, chinaTable, "081413"),
        Entry(69, "烤鸭", ["北京烤鸭"], "肉蛋", nil, 436, "1 份", 100, chinaTable, "092301"),
        Entry(70, "酱牛肉", ["卤牛肉"], "肉蛋", nil, 246, "1 份", 100, chinaTable, "082301"),
        Entry(71, "羊肉串", ["烤串"], "肉蛋", "烤", 206, "3 串", 90, chinaTable, "083304"),
        Entry(72, "鱼丸", [], "肉蛋", nil, 107, "5 个", 75, chinaTable, "121305"),
        Entry(5, "牛奶", ["纯牛奶", "milk"], "乳制品", "全脂", 65, "1 杯", 250, chinaTable, "101101x"),
        Entry(73, "酸奶", ["yogurt"], "乳制品", "全脂", 86, "1 杯", 200, chinaTable, "103001x"),
        Entry(74, "奶酪", ["芝士", "cheese"], "乳制品", nil, 328, "1 片", 20, chinaTable, "104001"),
        Entry(3, "苹果", ["apple"], "水果", nil, 53, "1 个", 200, chinaTable, "061101x"),
        Entry(4, "香蕉", ["banana"], "水果", nil, 93, "1 根", 100, chinaTable, "065033"),
        Entry(75, "葡萄", [], "水果", nil, 45, "1 小串", 200, chinaTable, "063101x"),
        Entry(76, "西瓜", [], "水果", nil, 31, "1 块", 300, chinaTable, "066201x"),
        Entry(77, "芒果", [], "水果", nil, 35, "1 个", 200, chinaTable, "065011"),
        Entry(78, "橙子", ["橙"], "水果", nil, 48, "1 个", 150, chinaTable, "064101"),
        Entry(79, "橘子", ["蜜橘", "桔子"], "水果", nil, 45, "1 个", 100, chinaTable, "064206"),
        Entry(80, "草莓", [], "水果", nil, 32, "10 颗", 150, chinaTable, "063910"),
        Entry(81, "荔枝", [], "水果", nil, 71, "10 颗", 150, chinaTable, "065010"),
        Entry(82, "榴莲", [], "水果", nil, 150, "1 瓣", 100, chinaTable, "065025"),
        Entry(83, "桃子", ["桃"], "水果", nil, 42, "1 个", 200, chinaTable, "062101x"),
        Entry(84, "梨", [], "水果", nil, 51, "1 个", 200, chinaTable, "061201x"),
        Entry(85, "菠萝", ["凤梨"], "水果", nil, 44, "1 块", 150, chinaTable, "065002"),
        Entry(86, "猕猴桃", ["奇异果"], "水果", nil, 61, "1 个", 80, chinaTable, "063909"),
        Entry(87, "樱桃", ["车厘子"], "水果", nil, 46, "1 把", 100, chinaTable, "062902"),
        Entry(88, "火龙果", [], "水果", nil, 55, "半个", 200, chinaTable, "065023"),
    ]

    /// Installs seeded before this was tidied up carry a developer's note after the source; it is
    /// stored in their food table and on their records, so it is trimmed wherever a source is shown.
    static func displaySource(_ stored: String) -> String {
        stored.replacingOccurrences(of: " / 内置启动种子库", with: "")
    }

    /// Adds the rows an install does not have yet and brings the ones it has up to date. Records keep
    /// their own copy of the figure they were saved with, so past entries do not change.
    @MainActor
    static func sync(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<FoodNutritionItem>())) ?? []
        let byId = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for entry in entries {
            if let item = byId[entry.id] {
                item.name = entry.name
                item.aliasesText = entry.aliases.joined(separator: "|")
                item.category = entry.category
                item.energyKcalPer100g = entry.energyKcalPer100g
                item.defaultServingName = entry.servingName
                item.defaultServingGrams = entry.servingGrams
                item.sourceName = entry.source
                item.sourceVersion = "seed v\(version)"
                item.sourceFoodId = entry.sourceFoodId
                item.state = entry.state
                item.isVerified = true
                item.updatedAt = .now
            } else {
                context.insert(FoodNutritionItem(
                    id: entry.id,
                    name: entry.name,
                    aliases: entry.aliases,
                    category: entry.category,
                    energyKcalPer100g: entry.energyKcalPer100g,
                    defaultServingName: entry.servingName,
                    defaultServingGrams: entry.servingGrams,
                    sourceName: entry.source,
                    sourceVersion: "seed v\(version)",
                    sourceFoodId: entry.sourceFoodId,
                    state: entry.state,
                    isVerified: true
                ))
            }
        }
    }
}
