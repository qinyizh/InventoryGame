//
//  PokedexView.swift
//  InventoryGame
//
//  Created by Qinyi zhang on 12/15/25.
//

import SwiftUI

struct PokedexView: View {
    @ObservedObject var store: GameStore
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AllItems, id: \.id) { item in
                        let isUnlocked = store.unlockedItemIds.contains(item.id)
                        
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(isUnlocked ? Color.white : Color.gray.opacity(0.2))
                                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                
                                if isUnlocked {
                                    Image(item.img)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(10)
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(height: 80)
                            
                            Text(isUnlocked ? item.name : "???")
                                .font(.system(.caption, design: .rounded))
                                .bold()
                                .foregroundColor(isUnlocked ? .primary : .gray)
                            
                            if isUnlocked {
                                Text("$\(item.basePrice)")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                        .onTapGesture {
                            // 可以加一个详情弹窗，这里简单点，只展示
                        }
                    }
                }
                .padding()
                
                if store.unlockedItemIds.count == AllItems.count {
                    Text("🏆 全图鉴收集达成！")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.top, 20)
                }
            }
            .background(Color.creamBackground)
            .navigationTitle("物资图鉴")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
