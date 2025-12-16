//
//  SoundManager.swift
//  InventoryGame
//
//  Created by Qinyi zhang on 12/15/25.
//

import Foundation
import AudioToolbox // 引入系统音频库

class SoundManager {
    static let shared = SoundManager()
    
    enum SoundType {
        case pickup    // 拿起物品
        case drop      // 放下物品
        case combine   // 合成成功 (魔法声)
        case sell      // 卖出 (收银机声)
        case buy       // 进货 (啵啵声)
        case error     // 错误 (撞墙声)
    }
    
    func play(_ type: SoundType) {
        // 这里我们使用 iOS 系统自带的 SystemSoundID
        // 虽然这些 ID 是系统私有的，但在 App 开发中常用于模拟原生体验
        // 这种方式的好处是：你不需要去找 MP3 文件，直接能用！
        
        var soundID: SystemSoundID = 0
        
        switch type {
        case .pickup:
            soundID = 1104 // Tock (类似键盘按键声，清脆)
        case .drop:
            soundID = 1103 // Tink (稍微沉一点的声音)
        case .combine:
            soundID = 1001 // Mail Sent (一种像魔法一样的上升音效)
            // 备选: 1322 (Bloom)
        case .sell:
            soundID = 1407 // Payment Success (非常爽的收钱声音！)
            // 备选: 1111 (Fanfare)
        case .buy:
            soundID = 1057 // Pock (气泡破裂声)
        case .error:
            soundID = 1053 // Bonk (沉闷的拒绝声)
        }
        
        // 播放系统音效
        AudioServicesPlaySystemSound(soundID)
    }
}
