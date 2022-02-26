//
//  PaperInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 24/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

// MARK: -
protocol PaperInfo {
    static func getPaperSize(width: Double, height: Double) -> String?
}

extension PaperInfo {
    /// Get the format of the size
    /// - parameters:
    ///   - width: Width, in _mm_.
    ///   - height: Height, in _mm_.
    static func getPaperSize(width: Double, height: Double) -> String? {
        guard width > 0 && height > 0 else {
            return nil
        }
        let formats: [String: [Double]] = [
            "A0": [841, 1189],
            "A1": [594, 841],
            "A2": [420, 594],
            "A3": [297, 420],
            "A4": [210, 297],
            "A5": [148, 210],
            "A6": [105, 148],
            "A7": [74, 105],
            "A8": [52, 74],
            "A9": [37, 52],
            "A10": [26, 37],
            
            "B0": [1000, 1414],
            "B1": [707, 1000],
            "B2": [500, 707],
            "B3": [353, 500],
            "B4": [250, 353],
            "B5": [176, 250],
            "B6": [125, 176],
            "B7": [88, 125],
            "B8": [62, 88],
            "B9": [44, 62],
            "B10": [31, 44],
            
            "C0": [917, 1297],
            "C1": [648, 917],
            "C2": [458, 648],
            "C3": [324, 458],
            "C4": [229, 324],
            "C5": [162, 229],
            "C6": [114, 162],
            "C7": [81, 114],
            "C8": [57, 81],
            "C9": [40, 57],
            "C10": [28, 40],
            
            "letter": [216, 279],
            "legal": [216, 356],
            "legal junior": [203, 127],
            "ledger": [432, 279], // tabloid
            
            "Arch A": [229, 305],
            "Arch B": [305, 457],
            "Arch C": [457, 610],
            "Arch D": [610, 914],
            "Arch E": [914, 1219],
            "Arch E1": [762, 1067],
            "Arch E2": [660, 965],
            "Arch E£": [686, 991],
        ]
        
        let w = min(width, height)
        let h = max(width, height)
        var d = formats.map { k, v -> (String, [Double]) in
            let dw = abs(v[0] - w)
            let dh = abs(v[1] - h)
            
            return (k, [dw, dh])
        }
        if let k = d.first(where: { $0.1[0] <= 0.1 && $0.1[1] <= 0.1 }) {
            if k.0 == "ledger" && width < height {
                return "tabloid"
            }
            return k.0
        }
        d.sort { a, b in
            let m1 = a.1.reduce(0, +) / Double(a.1.count)
            let m2 = b.1.reduce(0, +) / Double(b.1.count)
            return m1 < m2
        }
        guard let result = d.first else {
            return nil
        }
        
        let v = formats[result.0]!
        let max_delta: Double
        if v[1] <= 150 {
            max_delta = 1.5
        } else if v[1] <= 600 {
            max_delta = 2.0
        } else {
            max_delta = 3.0
        }
        if result.1.reduce(0, +) / 2.0 <= max_delta {
            if result.0 == "ledger" && width < height {
                return "tabloid" // "~ tabloid"
            }
            
            return "\(result.0)" // "~ \(result.0)"
        }
        return nil
    }
}
