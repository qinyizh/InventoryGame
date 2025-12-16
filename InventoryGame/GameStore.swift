import SwiftUI
import Combine

// 网格配置
struct GridConfig {
    static let rows = 8
    static let columns = 8
    static let tileSize: CGFloat = 46
    static let spacing: CGFloat = 2
}

// 1. 定义类别枚举
enum ItemCategory: String, Codable, CaseIterable {
    case food = "食品"
    case weapon = "武器"
    case medical = "医疗"
    case utility = "物资"
    
    // 给不同类别分配颜色（用于以后做UI区分）
    var color: Color {
        switch self {
        case .food: return .green
        case .weapon: return .red
        case .medical: return .blue
        case .utility: return .orange
        }
    }
}

// 2. 更新物品定义
struct ItemType: Equatable {
    let id: String
    let w: Int
    let h: Int
    let img: String
    let name: String
    let basePrice: Int
    let category: ItemCategory // 新增类别
    let desc: String
}

// 3. 全新的掉落表
let AllItems: [ItemType] = [
    // --- 食品 ---
    ItemType(id: "noodles", w: 1, h: 1, img: "instant_noodles_1x1", name: "红烧牛肉面", basePrice: 20, category: .food, desc: "生存低保。单卖亏本，建议合成。"),
    ItemType(id: "cola", w: 1, h: 1, img: "cola_can_1x1", name: "冰阔落", basePrice: 35, category: .food, desc: "肥宅快乐水，末世里的硬通货。"),
    ItemType(id: "chips", w: 1, h: 1, img: "potato_chips_1x1", name: "乐事薯片", basePrice: 40, category: .food, desc: "虽然全是空气，但热量很高。"),
    ItemType(id: "spam", w: 1, h: 1, img: "food_spam_1x1", name: "午餐肉", basePrice: 65, category: .food, desc: "肉！真正的肉！进货就能回本。"),
    ItemType(id: "beans", w: 1, h: 1, img: "canned_beans_1x1", name: "茄汁黄豆", basePrice: 45, category: .food, desc: "英式黑暗料理，但富含蛋白质。"),
    ItemType(id: "energy", w: 1, h: 1, img: "energy_bar_1x1", name: "士力架", basePrice: 55, category: .food, desc: "横扫饥饿，做回自己。"),
    ItemType(id: "water", w: 1, h: 2, img: "water_bottle_1x1", name: "大桶矿泉水", basePrice: 120, category: .food, desc: "生命之源。非常占地(1x2)，但值钱。"),
    
    // --- 武器 ---
    ItemType(id: "knife", w: 1, h: 1, img: "weapon_knife_1x1", name: "战术匕首", basePrice: 70, category: .weapon, desc: "短小精悍，防身必备。"),
    ItemType(id: "bat", w: 1, h: 2, img: "weapon_bat_1x2", name: "棒球棍", basePrice: 90, category: .weapon, desc: "物理学圣剑。注意它是长条形的。"),
    ItemType(id: "pistol", w: 2, h: 1, img: "weapon_pistol_2x1", name: "左轮手枪", basePrice: 200, category: .weapon, desc: "午时已到。横向占两格(2x1)。"),
    
    // --- 医疗 ---
    ItemType(id: "bandage", w: 1, h: 1, img: "med_bandage_1x1", name: "绷带", basePrice: 50, category: .medical, desc: "受了小伤？缠一下就好。"),
    ItemType(id: "pills", w: 1, h: 1, img: "med_pills_1x1", name: "抗生素", basePrice: 150, category: .medical, desc: "末世里的黄金。比金子还贵重。"),
    ItemType(id: "medkit", w: 2, h: 2, img: "med_kit_2x2", name: "急救箱", basePrice: 400, category: .medical, desc: "巨大的(2x2)医疗包，能救命也能发财。"),
    
    // --- 杂物 ---
    ItemType(id: "battery", w: 1, h: 1, img: "util_battery_1x1", name: "工业电池", basePrice: 80, category: .utility, desc: "没有电，你的GameBoy就没法玩了。"),
    ItemType(id: "gas", w: 2, h: 2, img: "util_gas_2x2", name: "汽油桶", basePrice: 350, category: .utility, desc: "液体黄金。2x2的大块头，易燃易爆。")
]

// 游戏内物品实例
struct GameItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var name: String
    let imageName: String
    let price: Int // 记录这个物品的具体价值
    let typeId: String // 用于查图鉴
}

// 电台订单
struct RadioOrder: Codable, Equatable {
    let targetImageName: String
    let targetName: String
    let priceMultiplier: Int
}

class GameStore: ObservableObject {
    @Published var inventory: [GameItem] = []
    @Published var money: Int = 500 // 初始资金给多点，容错率高
    
    // 图鉴系统
    @Published var unlockedItemIds: Set<String> = []
    @Published var showNewItemAlert: ItemType? = nil // 用于触发弹窗
    
    // 电台状态
    @Published var isRadioUnlocked: Bool = false
    @Published var radioRequest: RadioOrder? = nil
    
    // 常量
    let buyCost = 50
    private let kInventoryKey = "saved_inventory_v3"
    private let kMoneyKey = "saved_money_v3"
    private let kRadioUnlockKey = "saved_radio_unlock_v3"
    private let kUnlockedItemsKey = "saved_pokedex_v3"
    
    init() {
        loadGame()
        if isRadioUnlocked && radioRequest == nil { generateNewOrder() }
    }
    
    // MARK: - 💾 存档/读档
    func saveGame() {
        do {
            let encoder = JSONEncoder()
            UserDefaults.standard.set(try encoder.encode(inventory), forKey: kInventoryKey)
            UserDefaults.standard.set(money, forKey: kMoneyKey)
            UserDefaults.standard.set(isRadioUnlocked, forKey: kRadioUnlockKey)
            // 保存图鉴 (Set 转 Array 存)
            UserDefaults.standard.set(Array(unlockedItemIds), forKey: kUnlockedItemsKey)
        } catch { print("存档失败: \(error)") }
    }
    
    func loadGame() {
        if UserDefaults.standard.object(forKey: kMoneyKey) != nil {
            self.money = UserDefaults.standard.integer(forKey: kMoneyKey)
        }
        if let data = UserDefaults.standard.data(forKey: kInventoryKey) {
            if let decoded = try? JSONDecoder().decode([GameItem].self, from: data) {
                self.inventory = decoded
            }
        }
        self.isRadioUnlocked = UserDefaults.standard.bool(forKey: kRadioUnlockKey)
        
        if let savedIds = UserDefaults.standard.array(forKey: kUnlockedItemsKey) as? [String] {
            self.unlockedItemIds = Set(savedIds)
        }
    }
    
    // MARK: - 📚 图鉴逻辑
    func unlockItem(type: ItemType) {
        if !unlockedItemIds.contains(type.id) {
            unlockedItemIds.insert(type.id)
            showNewItemAlert = type // 触发 UI 弹窗
            saveGame()
        }
    }

    // MARK: - 🎮 游戏逻辑
    
    func buyItem() {
        if money < buyCost { return }
        
        // 随机逻辑：80% 概率出 1x1，20% 概率出 1x2 (水)
        let pool = AllItems
        guard let itemType = pool.randomElement() else { return }
        
        if let pos = findEmptySlot(w: itemType.w, h: itemType.h) {
            money -= buyCost
            let newItem = GameItem(
                x: pos.x, y: pos.y, width: itemType.w, height: itemType.h,
                name: itemType.name, imageName: itemType.img,
                price: itemType.basePrice, typeId: itemType.id
            )
            inventory.append(newItem)
            
            // 尝试解锁图鉴
            unlockItem(type: itemType)
            
            saveGame()
        }
    }
    
    func sellItem(id: UUID) {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return }
        let item = inventory[index]
        
        var finalPrice = item.price
        // 土豪金 = 3倍价格
        if item.name.contains("✨") {
            finalPrice *= 3
        }
        
        money += finalPrice
        inventory.remove(at: index)
        checkRadioUnlock()
        saveGame()
    }
    
    // ... (移动、旋转、合成逻辑保持不变，但记得 saveGame) ...
    // 这里为了节省篇幅，省略了 move/rotate/findEmptySlot 代码
    // 请保留你原来文件中这部分的逻辑！只要确保 update inventory 后调用 saveGame() 即可。
    // 👇 特别注意 combineItems 需要稍微改一下，合成后价格要变吗？
    // 其实不用变数据结构，只要名字带 ✨，卖出时逻辑会自动 x3
    
    func moveItem(id: UUID, toGridX x: Int, toGridY y: Int) -> Bool {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return false }
        var item = inventory[index]
        if x < 0 || y < 0 || x + item.width > GridConfig.columns || y + item.height > GridConfig.rows { return false }
        let otherItems = inventory.filter { $0.id != id }
        for other in otherItems {
            if isOverlapping(item1: (x, y, item.width, item.height), item2: (other.x, other.y, other.width, other.height)) { return false }
        }
        inventory[index].x = x; inventory[index].y = y
        saveGame()
        return true
    }
    
    func rotateItem(id: UUID) -> Bool {
        guard let index = inventory.firstIndex(where: { $0.id == id }) else { return false }
        let item = inventory[index]
        let newW = item.height; let newH = item.width
        if item.x + newW > GridConfig.columns || item.y + newH > GridConfig.rows { return false }
        let otherItems = inventory.filter { $0.id != id }
        for other in otherItems {
            if isOverlapping(item1: (item.x, item.y, newW, newH), item2: (other.x, other.y, other.width, other.height)) { return false }
        }
        inventory[index].width = newW; inventory[index].height = newH
        saveGame()
        return true
    }
    
    func combineItems(draggedId: UUID, targetId: UUID) -> Bool {
        guard let dragIndex = inventory.firstIndex(where: { $0.id == draggedId }),
              let targetIndex = inventory.firstIndex(where: { $0.id == targetId }) else { return false }
        let draggedItem = inventory[dragIndex]; let targetItem = inventory[targetIndex]
        
        if draggedItem.imageName != targetItem.imageName || targetItem.name.contains("✨") { return false }
        
        inventory.remove(at: dragIndex)
        if let newTargetIndex = inventory.firstIndex(where: { $0.id == targetId }) {
            inventory[newTargetIndex].name = "✨ " + inventory[newTargetIndex].name
            // 这里不需要改 basePrice，卖出时会自动 x3
        }
        saveGame()
        return true
    }

    // ... (Radio 逻辑保持不变) ...
    func checkRadioUnlock() {
        if !isRadioUnlocked && money >= 1000 {
            isRadioUnlocked = true
            generateNewOrder()
            saveGame()
        }
    }
    
    func generateNewOrder() {
        if let target = AllItems.randomElement() {
            self.radioRequest = RadioOrder(targetImageName: target.img, targetName: target.name, priceMultiplier: 5)
        }
    }
    
    func completeRadioOrder(itemId: UUID) -> Bool {
        guard let order = radioRequest, isRadioUnlocked else { return false }
        guard let index = inventory.firstIndex(where: { $0.id == itemId }) else { return false }
        let item = inventory[index]
        
        if item.imageName == order.targetImageName {
            var price = item.price
            if item.name.contains("✨") { price *= 3 }
            money += price * order.priceMultiplier
            inventory.remove(at: index)
            generateNewOrder()
            saveGame()
            return true
        }
        return false
    }
    
    func findEmptySlot(w: Int, h: Int) -> (x: Int, y: Int)? {
        for y in 0...(GridConfig.rows - h) {
            for x in 0...(GridConfig.columns - w) {
                var collision = false
                for item in inventory {
                    if isOverlapping(item1: (x, y, w, h), item2: (item.x, item.y, item.width, item.height)) { collision = true; break }
                }
                if !collision { return (x, y) }
            }
        }
        return nil
    }
    
    func isOverlapping(item1: (x: Int, y: Int, w: Int, h: Int), item2: (x: Int, y: Int, w: Int, h: Int)) -> Bool {
        return item1.x < item2.x + item2.w && item1.x + item1.w > item2.x && item1.y < item2.y + item2.h && item1.y + item1.h > item2.y
    }
    
    func reset() {
        inventory = []; money = 500; isRadioUnlocked = false; radioRequest = nil; unlockedItemIds = []
        saveGame()
    }
}
