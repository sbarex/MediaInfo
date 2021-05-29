//
//  Int+ext.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 11/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

extension Int {
    static func gcd(_ a: Int, _ b: Int) -> Int {
        let remainder = abs(a) % abs(b)
        if remainder != 0 {
            return gcd(abs(b), remainder)
        } else {
            return abs(b)
        }
    }
}

