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
        guard b != 0 else {
            return 1
        }
        let remainder = abs(a) % abs(b)
        if remainder != 0 {
            return gcd(abs(b), remainder)
        } else {
            return abs(b)
        }
    }
}

extension Double {
    typealias Rational = (num : Int, den : Int)

    func rationalApproximation(withPrecision eps: Double = 1.0E-6) -> Rational {
        var x = self
        var a = floor(x)
        var (h1, k1, h, k) = (1, 0, Int(a), 1)

        while x - a > eps * Double(k) * Double(k) {
            x = 1.0/(x - a)
            a = floor(x)
            (h1, k1, h, k) = (h, k, h1 + Int(a) * h, k1 + Int(a) * k)
        }
        return (num: h, den: k)
    }
}
