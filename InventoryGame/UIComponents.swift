//
//  UIComponents.swift
//  InventoryGame
//
//  Created by Qinyi zhang on 12/15/25.
//
import SwiftUI
import Combine


struct CuteButtonStyle: ButtonStyle {
    var color: Color = .blue // 默认颜色，可传参修改
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded).weight(.bold)) // 圆体字
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                ZStack {
                    // 1. 底部阴影 (模拟厚度)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color.opacity(0.3))
                        .offset(y: 5) // 向下偏移，制造立体感
                    
                    // 2. 按钮本体
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color)
                }
            )
            // 3. 按下时的缩放动画 (Q弹感)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// 使用方法：
// Button("疯狂进货") { ... }
//    .buttonStyle(CuteButtonStyle(color: .mint))
