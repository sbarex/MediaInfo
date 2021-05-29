//
//  TimeInterval+ext.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 10/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

extension TimeInterval {
    func formatTime() -> String {
        var m = Int(self / 60)
        let h = Int(TimeInterval(m) / 60)
        m -= h * 60
        let s = Int(self) - (m * 60) - (h * 3600)
        // let ms = time - TimeInterval(s + m * 60 + h * 3600)
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

