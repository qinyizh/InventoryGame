import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject var store = GameStore()
    @State private var showPokedex = false // 控制图鉴显示
    @State private var showClearConfirmation = false
    
    // 弹窗状态
    @State private var newItemAlert: ItemType? = nil

    @State private var gameScene: InventoryScene = {
        let scene = InventoryScene()
        scene.size = CGSize(width: 390, height: 800)
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }()

    var body: some View {
        ZStack {
            Color.creamBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // --- 顶部栏 (增加了图鉴按钮) ---
                HStack {
                    // 左上角：图鉴按钮
                    Button(action: { showPokedex = true }) {
                        VStack(spacing: 2) {
                            Image(systemName: "book.closed.fill")
                                .font(.title2)
                            Text("图鉴")
                                .font(.caption2)
                        }
                        .foregroundColor(.brown)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                    Text("📦 末世囤货记")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // 右上角：占位或设置，目前留空保持平衡
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 100)
                
                // --- 数据面板 ---
                HStack(spacing: 15) {
                    VStack {
                        Text("物资")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                        Text("\(store.inventory.count)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.darkInk)
                            .contentTransition(.numericText())
                    }
                    
                    Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 1, height: 40)
                    
                    VStack {
                        Text("余额")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                        Text("$\(store.money)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(store.money < 100 ? .jellyRed : .popOrange)
                            .contentTransition(.numericText())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                
                // --- 游戏区域 ---
                SpriteView(scene: gameScene, options: [.allowsTransparency])
                    .frame(height: 580)
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    .onAppear {
                        gameScene.store = store
                        gameScene.redrawInventory(items: store.inventory)
                    }
                
                Spacer()
                
                // --- 底部按钮 ---
                VStack(spacing: 15) {
                    Button(action: {
                        store.buyItem()
                        SoundManager.shared.play(.buy)
                    }) {
                        HStack {
                            Image(systemName: store.money < store.buyCost ? "xmark.circle" : "cart.fill")
                            // 💡 明确显示价格： (-$50)
                            Text(store.money < store.buyCost ? "没钱啦！" : "疯狂进货 (-$\(store.buyCost))")
                        }
                    }
                    .buttonStyle(CuteButtonStyle(
                        color: store.money < store.buyCost ? .gray : .popOrange
                    ))
                    .disabled(store.money < store.buyCost)
                    
                    Button("重置游戏") {
                        showClearConfirmation = true
                    }
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
                }
                .padding(.bottom, 100)
            }
            
            // --- 弹窗：新物品解锁 ---
            if let newItem = store.showNewItemAlert {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    VStack(spacing: 15) {
                        Text("✨ 新物资解锁！")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Image(newItem.img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                        
                        Text(newItem.name)
                            .font(.title2)
                            .bold()
                        
                        Text(newItem.desc)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("基础价值: $\(newItem.basePrice)")
                            .font(.caption)
                            .padding(5)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(5)
                        
                        Button("收下") {
                            withAnimation {
                                store.showNewItemAlert = nil
                            }
                        }
                        .padding(.top, 10)
                        .buttonStyle(CuteButtonStyle(color: .blue))
                    }
                    .padding(30)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding(40)
                }
                .transition(.scale)
                .zIndex(100)
            }
        }
        // 图鉴 Sheet
        .sheet(isPresented: $showPokedex) {
            PokedexView(store: store)
        }
        // 清空确认
        .alert("💥 确定重置？", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) { }
            Button("确定", role: .destructive) {
                store.reset()
                SoundManager.shared.play(.error)
            }
        }
    }
}

extension Color {
    // 奶油白背景 (不要用纯白，太刺眼)
    static let creamBackground = Color(red: 0.98, green: 0.96, blue: 0.93)
    
    // 活力橙 (用于重点按钮)
    static let popOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    // 清新薄荷 (用于成功提示)
    static let mintGreen = Color(red: 0.4, green: 0.8, blue: 0.6)
    
    // 软糖红 (用于警告或重要物品)
    static let jellyRed = Color(red: 1.0, green: 0.45, blue: 0.45)
    
    // 深色文字 (不要用纯黑，用深灰蓝)
    static let darkInk = Color(red: 0.2, green: 0.2, blue: 0.3)
}


#Preview {
    ContentView()
}
