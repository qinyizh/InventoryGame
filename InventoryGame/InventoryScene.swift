import SwiftUI
import SpriteKit
import Combine
import UIKit

class InventoryScene: SKScene {
    var store: GameStore?
    private var cancellables = Set<AnyCancellable>()
    
    // 节点定义
    var sellNode: SKSpriteNode!
    var priceLabel: SKLabelNode!
    
    // 📻 电台相关节点
    var radioGroupNode: SKNode!
    var radioBaseNode: SKShapeNode!   // 底座 (作为点击范围)
    var radioIconNode: SKSpriteNode!  // ✨ 新图标节点
    var radioBubbleNode: SKShapeNode!
    var radioItemNode: SKSpriteNode!
    var radioLabel: SKLabelNode!
    var guideArrow: SKLabelNode!
    
    // 拖拽状态
    var selectedNode: SKSpriteNode?
    var originalPosition: CGPoint?
    var selectedItemId: UUID?
    var touchStartPosition: CGPoint?
    
    override func didMove(to view: SKView) {
        self.scaleMode = .resizeFill
        self.backgroundColor = .clear
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let gridW = CGFloat(GridConfig.columns) * GridConfig.tileSize
        let gridH = CGFloat(GridConfig.rows) * GridConfig.tileSize
        
        // 阴影 & 白底
        let shadowNode = SKShapeNode(rectOf: CGSize(width: gridW + 20, height: gridH + 20), cornerRadius: 16)
        shadowNode.fillColor = .black.withAlphaComponent(0.05)
        shadowNode.strokeColor = .clear
        shadowNode.zPosition = -10
        shadowNode.position = CGPoint(x: 0, y: -5)
        addChild(shadowNode)
        
        let bgNode = SKShapeNode(rectOf: CGSize(width: gridW + 20, height: gridH + 20), cornerRadius: 16)
        bgNode.fillColor = .white
        bgNode.strokeColor = .clear
        bgNode.zPosition = -5
        addChild(bgNode)

        // 1. 卖出按钮 (使用新素材 sell_icon)
        setupSellButton()
        
        // 2. 电台 (使用新素材 broadcast_tower)
        setupRadioNode()
        
        // 3. 价格标签
        priceLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        priceLabel.fontSize = 24
        priceLabel.fontColor = .systemGreen
        priceLabel.zPosition = 300
        priceLabel.isHidden = true
        addChild(priceLabel)
        
        // 4. 网格线
        setupGridLines(gridW: gridW, gridH: gridH)
        
        // 5. 灰色底板
        let gridBg = SKShapeNode(rectOf: CGSize(width: gridW, height: gridH))
        gridBg.fillColor = .darkGray
        gridBg.strokeColor = .clear
        gridBg.zPosition = -2
        addChild(gridBg)
        
        setupSubscribers()
        
        if let store = store {
            redrawInventory(items: store.inventory)
            updateRadioState()
        }
    }
    
    // MARK: - 💰 卖出按钮 (使用 sell_icon)
    func setupSellButton() {
        // 优先尝试加载你刚生成的图片
        if let _ = UIImage(named: "sell_icon") {
            sellNode = SKSpriteNode(imageNamed: "sell_icon")
            // 如果图标自带投影或很大，可以在这里调整大小
            sellNode.size = CGSize(width: 80, height: 80)
        } else {
            // 兜底：如果没有图，还是用原来的系统图标
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold)
            if let uiImage = UIImage(systemName: "dollarsign.circle.fill", withConfiguration: config)?
                .withTintColor(.systemOrange, renderingMode: .alwaysOriginal) {
                sellNode = SKSpriteNode(texture: SKTexture(image: uiImage))
                sellNode.size = CGSize(width: 70, height: 70)
            }
        }
        
        sellNode.position = CGPoint(x: 0, y: -240)
        sellNode.name = "sell"
        sellNode.zPosition = 200
        addChild(sellNode)
    }
    
    // MARK: - 📻 电台节点 (使用 broadcast_tower)
    func setupRadioNode() {
        radioGroupNode = SKNode()
        radioGroupNode.position = CGPoint(x: 0, y: 230)
        radioGroupNode.zPosition = 200
        radioGroupNode.isHidden = true
        addChild(radioGroupNode)
        
        // 1. 底座 (透明化，只作为点击热区，或者保留一点光晕)
        radioBaseNode = SKShapeNode(circleOfRadius: 45) // 稍微大一点
        // 把底座改成半透明白色，或者完全透明，让你的3D图标唱主角
        radioBaseNode.fillColor = .white.withAlphaComponent(0.01)
        radioBaseNode.strokeColor = .clear
        radioBaseNode.name = "radioBase"
        radioGroupNode.addChild(radioBaseNode)
        
        // 2. ✨ 加载你的新图标
        if let _ = UIImage(named: "broadcast_tower") {
            radioIconNode = SKSpriteNode(imageNamed: "broadcast_tower")
            radioIconNode.size = CGSize(width: 90, height: 90) // 调大一点，这可是核心建筑
        } else {
            // 兜底
            radioIconNode = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        }
        // 稍微向上一点，因为透视关系
        radioIconNode.position = CGPoint(x: 0, y: 10)
        radioGroupNode.addChild(radioIconNode)
        
        // 3. 需求气泡 (位置微调)
        radioBubbleNode = SKShapeNode(circleOfRadius: 22)
        radioBubbleNode.fillColor = .white
        radioBubbleNode.strokeColor = .systemRed // 改成红色边框呼应电台
        radioBubbleNode.lineWidth = 3
        radioBubbleNode.position = CGPoint(x: 45, y: 35) // 放在塔尖右侧
        radioBubbleNode.zPosition = 205
        radioGroupNode.addChild(radioBubbleNode)
        
        radioItemNode = SKSpriteNode(color: .clear, size: CGSize(width: 28, height: 28))
        radioBubbleNode.addChild(radioItemNode)
        
        // 4. 文字 (放在图标下方)
        radioLabel = SKLabelNode(text: "5倍高价求购！")
        radioLabel.fontName = "PingFangSC-Semibold"
        radioLabel.fontSize = 14
        radioLabel.fontColor = .systemRed
        radioLabel.position = CGPoint(x: 0, y: -45)
        
        let labelBg = SKShapeNode(rectOf: CGSize(width: 120, height: 24), cornerRadius: 5)
        labelBg.fillColor = .white.withAlphaComponent(0.9)
        labelBg.strokeColor = .clear
        labelBg.zPosition = -1
        labelBg.position = CGPoint(x: 0, y: 5)
        radioLabel.addChild(labelBg)
        
        radioGroupNode.addChild(radioLabel)
        
        // 5. 箭头
        guideArrow = SKLabelNode(text: "⬇️")
        guideArrow.fontSize = 30
        guideArrow.position = CGPoint(x: 45, y: 50)
        radioGroupNode.addChild(guideArrow)
        
        let moveDown = SKAction.moveBy(x: 0, y: -10, duration: 0.5)
        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.5)
        guideArrow.run(SKAction.repeatForever(SKAction.sequence([moveDown, moveUp])))
        
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.8)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
        radioBubbleNode.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
    }
    
    func setupGridLines(gridW: CGFloat, gridH: CGFloat) {
        let startX = -gridW / 2 + GridConfig.tileSize / 2
        let startY = gridH / 2 - GridConfig.tileSize / 2
        for x in 0..<GridConfig.columns {
            for y in 0..<GridConfig.rows {
                let cell = SKShapeNode(rectOf: CGSize(width: GridConfig.tileSize - 2, height: GridConfig.tileSize - 2))
                cell.strokeColor = UIColor.white.withAlphaComponent(0.15)
                cell.fillColor = .clear
                cell.lineWidth = 1
                let px = startX + CGFloat(x) * GridConfig.tileSize
                let py = startY - CGFloat(y) * GridConfig.tileSize
                cell.position = CGPoint(x: px, y: py)
                addChild(cell)
            }
        }
    }
    
    func setupSubscribers() {
        guard let store = store else { return }
        
        store.$inventory
            .receive(on: RunLoop.main)
            .sink { [weak self] items in self?.redrawInventory(items: items) }
            .store(in: &cancellables)
        
        store.$isRadioUnlocked
            .combineLatest(store.$radioRequest)
            .receive(on: RunLoop.main)
            .sink { [weak self] unlocked, request in
                self?.updateRadioState(unlocked: unlocked, request: request)
            }
            .store(in: &cancellables)
    }
    
    func updateRadioState(unlocked: Bool? = nil, request: RadioOrder? = nil) {
        guard let store = store else { return }
        let isUnlocked = unlocked ?? store.isRadioUnlocked
        let currentOrder = request ?? store.radioRequest
        
        if isUnlocked {
            if radioGroupNode.isHidden {
                radioGroupNode.isHidden = false
                radioGroupNode.setScale(0)
                radioGroupNode.run(SKAction.scale(to: 1.0, duration: 0.5))
                createExplosion(at: radioGroupNode.position, color: .red)
                SoundManager.shared.play(.combine)
            }
            
            if let order = currentOrder {
                radioBubbleNode.isHidden = false
                radioItemNode.texture = SKTexture(imageNamed: order.targetImageName)
                radioLabel.text = "\(order.targetName) (5倍!)"
                guideArrow.isHidden = false
            } else {
                radioBubbleNode.isHidden = true
                radioLabel.text = "搜索信号中..."
                guideArrow.isHidden = true
            }
        } else {
            radioGroupNode.isHidden = true
        }
    }
    
    // MARK: - 🎨 核心绘制逻辑 (含分类光环)
        func redrawInventory(items: [GameItem]) {
            // 1. 清理旧节点
            children.forEach { node in
                if node.name == "itemNode" {
                    node.removeFromParent()
                }
            }
            
            let gridW = CGFloat(GridConfig.columns) * GridConfig.tileSize
            let gridH = CGFloat(GridConfig.rows) * GridConfig.tileSize
            let startX = -gridW / 2 + GridConfig.tileSize / 2
            let startY = gridH / 2 - GridConfig.tileSize / 2
            
            for item in items {
                // 计算物品的像素尺寸
                let itemW = CGFloat(item.width) * GridConfig.tileSize - GridConfig.spacing
                let itemH = CGFloat(item.height) * GridConfig.tileSize - GridConfig.spacing
                
                // 计算物品中心点坐标
                let xOffset = CGFloat(item.width - 1) * GridConfig.tileSize / 2
                let yOffset = CGFloat(item.height - 1) * GridConfig.tileSize / 2
                let pixelX = startX + CGFloat(item.x) * GridConfig.tileSize + xOffset
                let pixelY = startY - CGFloat(item.y) * GridConfig.tileSize - yOffset
                
                // --- 🌈 A. 绘制分类光环 (新功能) ---
                // 根据 typeId 查找物品的类别颜色
                let categoryColor = getCategoryColor(typeId: item.typeId)
                
                let bgNode = SKShapeNode(rectOf: CGSize(width: itemW + 4, height: itemH + 4), cornerRadius: 8)
                bgNode.fillColor = categoryColor.withAlphaComponent(0.25) // 25% 透明度
                bgNode.strokeColor = categoryColor.withAlphaComponent(0.6) // 边框深一点
                bgNode.lineWidth = 2
                bgNode.position = CGPoint(x: pixelX, y: pixelY)
                bgNode.name = "itemNode" // 统一命名，方便清理
                bgNode.zPosition = 9 // 放在物品图片下面
                addChild(bgNode)
                
                // --- B. 绘制物品图片 ---
                let node = SKSpriteNode(imageNamed: item.imageName)
                node.size = CGSize(width: itemW, height: itemH)
                node.position = CGPoint(x: pixelX, y: pixelY)
                node.name = "itemNode"
                node.zPosition = 10
                
                // --- C. 土豪金特效 ---
                let isGold = item.name.contains("✨")
                if isGold {
                    // 金色混合
                    node.color = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
                    node.colorBlendFactor = 0.4
                    
                    // 闪烁星星
                    let sparkleNode = SKLabelNode(text: "✨")
                    sparkleNode.fontSize = 24
                    // 放在右上角
                    sparkleNode.position = CGPoint(x: itemW/2 - 12, y: itemH/2 - 12)
                    sparkleNode.zPosition = 11
                    
                    let seq = SKAction.sequence([SKAction.fadeAlpha(to: 0.4, duration: 0.8), SKAction.fadeAlpha(to: 1.0, duration: 0.8)])
                    sparkleNode.run(SKAction.repeatForever(seq))
                    node.addChild(sparkleNode)
                    
                    // 如果是金色，光环也变成金色
                    bgNode.strokeColor = .systemYellow
                    bgNode.fillColor = UIColor.systemYellow.withAlphaComponent(0.3)
                }
                
                // 存入数据，用于拖拽逻辑
                node.userData = [
                    "id": item.id.uuidString,
                    "w": item.width,
                    "h": item.height,
                    "isGold": isGold
                ]
                
                addChild(node)
            }
        }
        
        // 🔍 辅助：根据 ID 查颜色
        func getCategoryColor(typeId: String) -> UIColor {
            // 在 AllItems 数组里查找对应的定义
            if let typeDef = AllItems.first(where: { $0.id == typeId }) {
                switch typeDef.category {
                case .food: return .systemGreen
                case .weapon: return .systemRed
                case .medical: return .systemBlue
                case .utility: return .systemOrange
                }
            }
            return .gray // 没找到就用灰色
        }
    func createCoinRain(at position: CGPoint) {
        for _ in 0..<20 {
            let coin = SKShapeNode(circleOfRadius: 6)
            coin.fillColor = .systemYellow
            coin.strokeColor = .orange
            coin.lineWidth = 1
            coin.position = position
            coin.zPosition = 1000
            addChild(coin)
            let randomX = CGFloat.random(in: -100...100)
            let randomY = CGFloat.random(in: 100...300)
            let moveUp = SKAction.move(by: CGVector(dx: randomX, dy: randomY), duration: 0.4)
            moveUp.timingMode = .easeOut
            let moveDown = SKAction.move(by: CGVector(dx: randomX * 0.5, dy: -400), duration: 0.6)
            moveDown.timingMode = .easeIn
            coin.run(SKAction.sequence([moveUp, SKAction.group([moveDown, SKAction.fadeOut(withDuration: 0.2)]), SKAction.removeFromParent()]))
        }
    }
    
    func createExplosion(at position: CGPoint, color: UIColor) {
        for _ in 0..<15 {
            let spark = SKShapeNode(circleOfRadius: 4)
            spark.fillColor = color
            spark.strokeColor = .white
            spark.lineWidth = 1
            spark.position = position
            spark.zPosition = 1000
            addChild(spark)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 50...120)
            let move = SKAction.move(by: CGVector(dx: distance * cos(angle), dy: distance * sin(angle)), duration: 0.5)
            move.timingMode = .easeOut
            spark.run(SKAction.sequence([SKAction.group([move, SKAction.fadeOut(withDuration: 0.5)]), SKAction.removeFromParent()]))
        }
    }
    
    // --- 交互逻辑 ---
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartPosition = location
        
        let nodes = nodes(at: location)
        if let node = nodes.first(where: { $0.name == "itemNode" }) as? SKSpriteNode {
            selectedNode = node
            originalPosition = node.position
            selectedItemId = UUID(uuidString: node.userData?["id"] as? String ?? "")
            SoundManager.shared.play(.pickup)
            node.run(SKAction.scale(to: 1.1, duration: 0.1))
            node.zPosition = 100
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = selectedNode, let touch = touches.first else { return }
        let location = touch.location(in: self)
        node.position = location

        if sellNode.contains(location) {
            if sellNode.xScale == 1.0 {
                sellNode.run(SKAction.scale(to: 1.2, duration: 0.1))
                node.alpha = 0.6
                if let w = node.userData?["w"] as? Int, let h = node.userData?["h"] as? Int {
                    var price = (w * h) * 20
                    let isGold = node.userData?["isGold"] as? Bool ?? false
                    if isGold { price *= 3 }
                    priceLabel.fontColor = isGold ? UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0) : .systemGreen
                    priceLabel.text = isGold ? "✨ +\(price) ✨" : "+\(price)"
                    priceLabel.isHidden = false
                    priceLabel.position = CGPoint(x: sellNode.position.x, y: sellNode.position.y + 70)
                }
            }
        } else {
            if sellNode.xScale != 1.0 { sellNode.run(SKAction.scale(to: 1.0, duration: 0.1)); node.alpha = 1.0; priceLabel.isHidden = true }
        }
        
        let radioPos = radioGroupNode.position
        let distToRadio = sqrt(pow(location.x - radioPos.x, 2) + pow(location.y - radioPos.y, 2))
        
        // 判定范围稍微大一点，因为图标变大了
        if let store = store, store.isRadioUnlocked, !radioGroupNode.isHidden, distToRadio < 70 {
            if radioIconNode.xScale == 1.0 {
                // 视觉反馈：图标跳动，底座显示（如果想强调）
                radioIconNode.run(SKAction.scale(to: 1.2, duration: 0.1))
                radioLabel.text = "松手交易!"
                radioLabel.fontColor = .green
            }
        } else {
            if radioIconNode.xScale != 1.0 {
                radioIconNode.run(SKAction.scale(to: 1.0, duration: 0.1))
                if let request = store?.radioRequest {
                    radioLabel.text = "\(request.targetName) (5倍!)"
                    radioLabel.fontColor = .systemRed
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = selectedNode, let startPos = touchStartPosition, let touch = touches.first, let itemId = selectedItemId else { return }
        let endPos = touch.location(in: self)
        priceLabel.isHidden = true
        
        if sellNode.contains(endPos) {
            store?.sellItem(id: itemId)
            SoundManager.shared.play(.sell)
            createCoinRain(at: sellNode.position)
            node.removeFromParent()
            sellNode.run(SKAction.scale(to: 1.0, duration: 0.1))
            selectedNode = nil
            return
        }
        
        let radioPos = radioGroupNode.position
        let distToRadio = sqrt(pow(endPos.x - radioPos.x, 2) + pow(endPos.y - radioPos.y, 2))
        
        // 判定范围 70
        if let store = store, store.isRadioUnlocked, !radioGroupNode.isHidden, distToRadio < 70 {
            if store.completeRadioOrder(itemId: itemId) {
                SoundManager.shared.play(.combine)
                createExplosion(at: radioGroupNode.position, color: .green)
                createCoinRain(at: radioGroupNode.position)
                node.removeFromParent()
            } else {
                SoundManager.shared.play(.error)
                if let originalPos = originalPosition { node.run(SKAction.move(to: originalPos, duration: 0.2)) }
            }
            radioIconNode.run(SKAction.scale(to: 1.0, duration: 0.1))
            selectedNode = nil
            return
        }
        
        let dx = endPos.x - startPos.x; let dy = endPos.y - startPos.y; let distance = sqrt(dx*dx + dy*dy)
        if distance < 10 {
            if let store = store, store.rotateItem(id: itemId) {
                SoundManager.shared.play(.pickup)
                let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
            } else {
                SoundManager.shared.play(.error)
                node.run(SKAction.sequence([SKAction.rotate(byAngle: 0.1, duration: 0.05), SKAction.rotate(byAngle: -0.2, duration: 0.05), SKAction.rotate(byAngle: 0.1, duration: 0.05)]))
            }
        } else {
            let otherNodes = nodes(at: endPos).filter { $0.name == "itemNode" && $0 != node }
            var combineSuccess = false
            if let targetNode = otherNodes.first, let targetIdStr = targetNode.userData?["id"] as? String, let targetId = UUID(uuidString: targetIdStr) {
                if let store = store, store.combineItems(draggedId: itemId, targetId: targetId) {
                    combineSuccess = true
                    SoundManager.shared.play(.combine)
                    createExplosion(at: targetNode.position, color: .yellow)
                    targetNode.run(SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
                    node.removeFromParent()
                    let generator = UIImpactFeedbackGenerator(style: .heavy); generator.impactOccurred()
                }
            }
            if !combineSuccess {
                let (gridX, gridY) = convertPointToGrid(node.position, width: 0, height: 0)
                if let store = store, store.moveItem(id: itemId, toGridX: gridX, toGridY: gridY) {
                    SoundManager.shared.play(.drop)
                    let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
                } else {
                    SoundManager.shared.play(.error)
                    if let originalPos = originalPosition { node.run(SKAction.move(to: originalPos, duration: 0.2)) }
                    let generator = UINotificationFeedbackGenerator(); generator.notificationOccurred(.error)
                }
            }
        }
        
        if node.parent != nil { node.run(SKAction.scale(to: 1.0, duration: 0.1)); node.alpha = 1.0; node.zPosition = 10 }
        selectedNode = nil; originalPosition = nil; selectedItemId = nil; touchStartPosition = nil
    }
    
    func convertPointToGrid(_ point: CGPoint, width: Int, height: Int) -> (Int, Int) {
        let totalGridWidth = CGFloat(GridConfig.columns) * GridConfig.tileSize
        let totalGridHeight = CGFloat(GridConfig.rows) * GridConfig.tileSize
        let rawX = (point.x - (-totalGridWidth/2)) / GridConfig.tileSize
        let rawY = (totalGridHeight/2 - point.y) / GridConfig.tileSize
        return (Int(floor(rawX)), Int(floor(rawY)))
    }
}
