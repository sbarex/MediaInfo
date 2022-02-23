//
//  Settings+ext.swift
//  MediaInfoEx
//
//  Created by Sbarex on 12/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

extension Settings {
    func refreshImageMetadataExtractionRequired() {
        for item in imageMenuItems {
            if item.template.contains("[[metadata]]") {
                self.extractImageMetadata = true
                return
            } else if item.template.contains("[[script") {
                let r = BaseInfo.splitTokens(in: item.template)
                for result in r {
                    let placeholder = String(item.template[Range(result.range, in: item.template)!])
                    guard placeholder.hasPrefix("[[script-") && !placeholder.hasPrefix("[[script-action:") else {
                        continue
                    }
                    guard let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64() else {
                        continue
                    }
                    if !code.hasPrefix("/* no-metadata */") {
                        self.extractImageMetadata = true
                        return
                    }
                }
            }
        }
        self.extractImageMetadata = false
    }
    
    func refreshOfficeDeepScanRequired() {
        for item in imageMenuItems {
            if item.template.contains("[[size:") || item.template.contains("[[pages]]") || item.template.contains("[[sheets]]") {
                self.isOfficeDeepScan = true
                return
            } else if item.template.contains("[[script") {
                let r = BaseInfo.splitTokens(in: item.template)
                for result in r {
                    let placeholder = String(item.template[Range(result.range, in: item.template)!])
                    guard placeholder.hasPrefix("[[script-") && !placeholder.hasPrefix("[[script-action:") else {
                        continue
                    }
                    guard let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64() else {
                        continue
                    }
                    if !code.hasPrefix("/* no-deep-scan */") {
                        self.isOfficeDeepScan = true
                        return
                    }
                }
            }
        }
        self.isOfficeDeepScan = false
    }
}
