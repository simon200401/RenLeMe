import SwiftUI

enum PropCategory: String, CaseIterable, Identifiable {
    case ui
    case food
    case time
    case money

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ui: "软件 UI"
        case .food: "食物"
        case .time: "时间"
        case .money: "金钱"
        }
    }

    var baseColor: Color {
        switch self {
        case .ui: .punchBlue
        case .food: .punchPink
        case .time: .punchYellow
        case .money: .punchGreen
        }
    }
}

enum PropIconKey: String, CaseIterable, Hashable {
    case coolBox
    case badge
    case calendar
    case chart
    case milkTea
    case snack
    case takeout
    case dessert
    case friedChicken
    case clock
    case gaming
    case drama
    case shortVideo
    case sleep
    case chat
    case stayUp
    case delay
    case wallet
    case camera
    case clothes
    case gamingGear
    case misc
    case phone
    case laptop
    case jewelry
    case subscription
    case cosmetics
    case shoes
    case bag
    case blindBox
    case travel
    case course

    var symbolName: String {
        switch self {
        case .coolBox: "archivebox.fill"
        case .badge: "star.fill"
        case .calendar: "calendar"
        case .chart: "chart.bar.fill"
        case .milkTea: "cup.and.saucer.fill"
        case .snack: "takeoutbag.and.cup.and.straw.fill"
        case .takeout: "takeoutbag.and.cup.and.straw.fill"
        case .dessert: "birthday.cake.fill"
        case .friedChicken: "fork.knife"
        case .clock: "clock.fill"
        case .gaming: "gamecontroller.fill"
        case .drama: "play.tv.fill"
        case .shortVideo: "play.rectangle.fill"
        case .sleep: "bed.double.fill"
        case .chat: "bubble.left.and.bubble.right.fill"
        case .stayUp: "moon.zzz.fill"
        case .delay: "hourglass"
        case .wallet: "wallet.pass.fill"
        case .camera: "camera.fill"
        case .clothes: "tshirt.fill"
        case .gamingGear: "desktopcomputer"
        case .misc: "shippingbox.fill"
        case .phone: "iphone"
        case .laptop: "laptopcomputer"
        case .jewelry: "diamond.fill"
        case .subscription: "creditcard.fill"
        case .cosmetics: "paintbrush.pointed.fill"
        case .shoes: "shoeprints.fill"
        case .bag: "handbag.fill"
        case .blindBox: "questionmark.app.fill"
        case .travel: "paperplane.fill"
        case .course: "graduationcap.fill"
        }
    }
}

struct PropTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let type: ResistType?
    let category: PropCategory
    let iconKey: PropIconKey
    let defaultValue: Double?
    let unit: ValueUnit?
    let caption: String
    let shadeIndex: Int

    var displayColor: Color {
        category.color(shadeIndex)
    }

    var defaultValueText: String {
        guard let unit else { return caption }
        if let defaultValue {
            switch unit {
            case .cny: return "默认 \(defaultValue.moneyString) / 可自填"
            case .kcal: return "默认 \(Int(defaultValue.rounded())) kcal / 可自填"
            case .minute: return "默认 \(defaultValue.displayValue(for: .time)) / 可自填"
            }
        }

        switch unit {
        case .cny: return "自填金额"
        case .kcal: return "自填 kcal"
        case .minute: return "自填分钟"
        }
    }

    static let templates: [PropTemplate] = [
        PropTemplate(id: "ui.coolBox", title: "冷静箱", type: nil, category: .ui, iconKey: .coolBox, defaultValue: nil, unit: nil, caption: "延迟决定", shadeIndex: 0),
        PropTemplate(id: "ui.badge", title: "成就", type: nil, category: .ui, iconKey: .badge, defaultValue: nil, unit: nil, caption: "连续记录", shadeIndex: 1),
        PropTemplate(id: "ui.calendar", title: "日历", type: nil, category: .ui, iconKey: .calendar, defaultValue: nil, unit: nil, caption: "历史入口", shadeIndex: 2),
        PropTemplate(id: "ui.chart", title: "统计", type: nil, category: .ui, iconKey: .chart, defaultValue: nil, unit: nil, caption: "复盘趋势", shadeIndex: 3),

        PropTemplate(id: "food.milkTea", title: "奶茶", type: .food, category: .food, iconKey: .milkTea, defaultValue: 420, unit: .kcal, caption: "饮品冲动", shadeIndex: 0),
        PropTemplate(id: "food.snack", title: "零食", type: .food, category: .food, iconKey: .snack, defaultValue: 180, unit: .kcal, caption: "小零嘴", shadeIndex: 1),
        PropTemplate(id: "food.takeout", title: "外卖", type: .food, category: .food, iconKey: .takeout, defaultValue: 800, unit: .kcal, caption: "一餐外卖", shadeIndex: 2),
        PropTemplate(id: "food.dessert", title: "甜品", type: .food, category: .food, iconKey: .dessert, defaultValue: 320, unit: .kcal, caption: "甜食冲动", shadeIndex: 3),
        PropTemplate(id: "food.friedChicken", title: "炸鸡", type: .food, category: .food, iconKey: .friedChicken, defaultValue: 620, unit: .kcal, caption: "快餐冲动", shadeIndex: 4),

        PropTemplate(id: "time.clock", title: "时钟", type: .time, category: .time, iconKey: .clock, defaultValue: nil, unit: .minute, caption: "时间冲动", shadeIndex: 0),
        PropTemplate(id: "time.gaming", title: "打游戏", type: .time, category: .time, iconKey: .gaming, defaultValue: nil, unit: .minute, caption: "娱乐暂停", shadeIndex: 1),
        PropTemplate(id: "time.drama", title: "追剧", type: .time, category: .time, iconKey: .drama, defaultValue: nil, unit: .minute, caption: "连播提醒", shadeIndex: 2),
        PropTemplate(id: "time.shortVideo", title: "短视频", type: .time, category: .time, iconKey: .shortVideo, defaultValue: nil, unit: .minute, caption: "刷屏暂停", shadeIndex: 3),
        PropTemplate(id: "time.sleep", title: "睡觉", type: .time, category: .time, iconKey: .sleep, defaultValue: nil, unit: .minute, caption: "休息记录", shadeIndex: 4),
        PropTemplate(id: "time.chat", title: "闲聊", type: .time, category: .time, iconKey: .chat, defaultValue: nil, unit: .minute, caption: "聊天记录", shadeIndex: 5),
        PropTemplate(id: "time.stayUp", title: "熬夜", type: .time, category: .time, iconKey: .stayUp, defaultValue: nil, unit: .minute, caption: "晚睡记录", shadeIndex: 6),
        PropTemplate(id: "time.delay", title: "拖延", type: .time, category: .time, iconKey: .delay, defaultValue: nil, unit: .minute, caption: "先停一下", shadeIndex: 7),

        PropTemplate(id: "money.wallet", title: "钱包", type: .money, category: .money, iconKey: .wallet, defaultValue: nil, unit: .cny, caption: "金钱冲动", shadeIndex: 0),
        PropTemplate(id: "money.camera", title: "相机", type: .money, category: .money, iconKey: .camera, defaultValue: nil, unit: .cny, caption: "愿望存钱", shadeIndex: 1),
        PropTemplate(id: "money.clothes", title: "衣服", type: .money, category: .money, iconKey: .clothes, defaultValue: nil, unit: .cny, caption: "穿搭消费", shadeIndex: 2),
        PropTemplate(id: "money.gamingGear", title: "游戏设备", type: .money, category: .money, iconKey: .gamingGear, defaultValue: nil, unit: .cny, caption: "设备升级", shadeIndex: 3),
        PropTemplate(id: "money.misc", title: "杂物", type: .money, category: .money, iconKey: .misc, defaultValue: nil, unit: .cny, caption: "小物件", shadeIndex: 4),
        PropTemplate(id: "money.phone", title: "手机", type: .money, category: .money, iconKey: .phone, defaultValue: nil, unit: .cny, caption: "数码消费", shadeIndex: 5),
        PropTemplate(id: "money.laptop", title: "电脑", type: .money, category: .money, iconKey: .laptop, defaultValue: nil, unit: .cny, caption: "先评估", shadeIndex: 6),
        PropTemplate(id: "money.jewelry", title: "首饰", type: .money, category: .money, iconKey: .jewelry, defaultValue: nil, unit: .cny, caption: "珠宝首饰", shadeIndex: 7),
        PropTemplate(id: "money.subscription", title: "会员", type: .money, category: .money, iconKey: .subscription, defaultValue: nil, unit: .cny, caption: "订阅续费", shadeIndex: 8),
        PropTemplate(id: "money.cosmetics", title: "化妆品", type: .money, category: .money, iconKey: .cosmetics, defaultValue: nil, unit: .cny, caption: "美妆消费", shadeIndex: 9),
        PropTemplate(id: "money.shoes", title: "鞋子", type: .money, category: .money, iconKey: .shoes, defaultValue: nil, unit: .cny, caption: "穿搭消费", shadeIndex: 10),
        PropTemplate(id: "money.bag", title: "包", type: .money, category: .money, iconKey: .bag, defaultValue: nil, unit: .cny, caption: "包袋消费", shadeIndex: 11),
        PropTemplate(id: "money.blindBox", title: "盲盒", type: .money, category: .money, iconKey: .blindBox, defaultValue: nil, unit: .cny, caption: "惊喜消费", shadeIndex: 12),
        PropTemplate(id: "money.travel", title: "旅行", type: .money, category: .money, iconKey: .travel, defaultValue: nil, unit: .cny, caption: "机酒门票", shadeIndex: 13),
        PropTemplate(id: "money.course", title: "报课", type: .money, category: .money, iconKey: .course, defaultValue: nil, unit: .cny, caption: "课程消费", shadeIndex: 14)
    ]

    static func templates(for type: ResistType) -> [PropTemplate] {
        templates.filter { $0.type == type }
    }

    static func uiTemplates() -> [PropTemplate] {
        templates.filter { $0.category == .ui }
    }

    static func defaultTemplate(for type: ResistType) -> PropTemplate {
        let preferredTitle: String
        switch type {
        case .money:
            preferredTitle = "钱包"
        case .food:
            preferredTitle = "奶茶"
        case .time:
            preferredTitle = "时钟"
        }

        return matching(type: type, title: preferredTitle) ?? templates(for: type)[0]
    }

    static func customFallbackTemplate(for type: ResistType) -> PropTemplate {
        let preferredTitle: String
        switch type {
        case .money:
            preferredTitle = "杂物"
        case .food:
            preferredTitle = "零食"
        case .time:
            preferredTitle = "拖延"
        }

        return matching(type: type, title: preferredTitle) ?? defaultTemplate(for: type)
    }

    static func matching(record: ResistRecord) -> PropTemplate? {
        if let propTemplateId = record.propTemplateId,
           let template = templates.first(where: { $0.id == propTemplateId }) {
            return template
        }

        if let iconKey = record.propIconKey,
           let template = matching(type: record.type, iconKey: iconKey) {
            return template
        }

        return matching(type: record.type, title: record.title)
    }

    static func matching(goal: Goal) -> PropTemplate? {
        matching(type: goal.type, title: goal.title)
    }

    static func matching(type: ResistType, title: String) -> PropTemplate? {
        let normalizedTitle = title.normalizedPropTitle
        let candidates = templates(for: type)
        return candidates.first { template in
            normalizedTitle.contains(template.title.normalizedPropTitle)
                || template.title.normalizedPropTitle.contains(normalizedTitle)
        }
    }

    static func matching(type: ResistType, iconKey: PropIconKey) -> PropTemplate? {
        templates(for: type).first { $0.iconKey == iconKey }
    }
}

private extension PropCategory {
    func color(_ index: Int) -> Color {
        let colors: [Color]
        switch self {
        case .ui:
            colors = [
                Color(red: 0.282, green: 0.655, blue: 1.0),
                Color(red: 0.361, green: 0.706, blue: 1.0),
                Color(red: 0.471, green: 0.769, blue: 1.0),
                Color(red: 0.247, green: 0.620, blue: 1.0)
            ]
        case .food:
            colors = [
                Color(red: 0.957, green: 0.518, blue: 0.769),
                Color(red: 0.965, green: 0.604, blue: 0.816),
                Color(red: 0.949, green: 0.463, blue: 0.718),
                Color(red: 0.973, green: 0.659, blue: 0.847),
                Color(red: 0.937, green: 0.400, blue: 0.682)
            ]
        case .time:
            colors = [
                Color(red: 1.0, green: 0.812, blue: 0.0),
                Color(red: 1.0, green: 0.847, blue: 0.239),
                Color(red: 0.976, green: 0.769, blue: 0.0),
                Color(red: 1.0, green: 0.878, blue: 0.392),
                Color(red: 0.957, green: 0.725, blue: 0.0),
                Color(red: 1.0, green: 0.831, blue: 0.290),
                Color(red: 0.969, green: 0.788, blue: 0.157),
                Color(red: 1.0, green: 0.890, blue: 0.424)
            ]
        case .money:
            colors = [
                Color(red: 0.024, green: 0.749, blue: 0.435),
                Color(red: 0.094, green: 0.784, blue: 0.490),
                Color(red: 0.0, green: 0.718, blue: 0.416),
                Color(red: 0.184, green: 0.800, blue: 0.541),
                Color(red: 0.039, green: 0.678, blue: 0.396),
                Color(red: 0.208, green: 0.816, blue: 0.557),
                Color(red: 0.0, green: 0.663, blue: 0.373),
                Color(red: 0.133, green: 0.780, blue: 0.510)
            ]
        }

        return colors[index % colors.count]
    }
}

private extension String {
    var normalizedPropTitle: String {
        replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "基金", with: "")
            .replacingOccurrences(of: "本周", with: "")
            .lowercased()
    }
}
