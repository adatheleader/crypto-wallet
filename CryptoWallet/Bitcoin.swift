//
//  Bitcoin.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 14.08.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import Foundation
import SwiftyRSA

class Bitcoin {
    
    class func randomHexDigit() -> Character {
        let hex: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
        let randomInt = Int(arc4random_uniform(16))
        return hex[randomInt]
    }
    
    class func newPrivateKey() -> String {
        var key = ""
        for _ in 1...64 {
            key.append(randomHexDigit())
        }
        return key
    }
}
