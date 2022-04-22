//
//  LanguageInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 26/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Cocoa

// MARK: -

protocol LanguageInfo: BaseInfo {
    /// Country ISO code.
    var lang: String? { get }
    
    /// Get the emoji of the counyty flag.
    func getCountryFlag() -> String?
    /// Get an image 32 x 32 px of the country flag.
    func getImageOfFlag() -> NSImage?
    
    func processLanguagePlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String
    static func getCountryFlag(lang: String?) -> String?
}

extension LanguageInfo {
    static func getCountryFlag(lang: String?) -> String? {
        guard let countryCode = lang, countryCode.count == 2 else {
            return nil
        }
        if countryCode.uppercased() == "EN" {
            return "🇺🇸"
        }
        return countryCode
            .uppercased()
            .unicodeScalars
            .map({ 127397 + $0.value })
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
    
    func getCountryFlag() -> String? {
        return Self.getCountryFlag(lang: self.lang)
    }
    
    func processLanguagePlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[language-count]]":
            if let lang = self.lang {
                isFilled = !lang.isEmpty
                if isFilled {
                    return NSLocalizedString("1 Language", tableName: "LocalizableExt", comment: "")
                } else {
                    return useEmptyData ? NSLocalizedString("no Language", tableName: "LocalizableExt", comment: "") : ""
                }
            } else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
        case "[[language]]", "[[languages]]":
            if let lang = self.lang, !lang.isEmpty {
                isFilled = true
                return lang
            } else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
        case "[[language-flag]]", "[[languages-flag]]":
            guard let lang = self.lang else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
            guard !lang.isEmpty else {
                isFilled = false
                return useEmptyData ? "🏳" : ""
            }
            isFilled = true
            if let flag = Self.getCountryFlag(lang: lang) {
                return flag
            } else {
                return lang
            }
        default:
            return placeholder
        }
    }
    
    func getImageOfFlag() -> NSImage? {
        guard let flag = getCountryFlag() else {
            return nil
        }
        let scale: CGFloat = 2
        let side: Int = Int(16 * scale)
        let size = CGSize(width: side, height: side)
        
        guard let drawingContext = CGContext(data: nil, width: side,  height: side, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            return nil
        }
        drawingContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
        
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let stringAttributes: [NSAttributedString.Key: Any] = [.font: font]
        
        let imageSize = (flag as NSString).size(withAttributes: stringAttributes)
        let pos = CGPoint(x: (size.width / scale - imageSize.width) / 2, y: (size.height / scale - imageSize.height) / 2)
        
        NSGraphicsContext.saveGraphicsState()
        defer {
            NSGraphicsContext.restoreGraphicsState()
        }
        NSGraphicsContext.current = NSGraphicsContext(cgContext: drawingContext, flipped: false)
        
        NSString(string: String(flag.first!)).draw(at: pos, withAttributes: stringAttributes)
        
        guard let coreImage = drawingContext.makeImage() else {
            return nil
        }
        return NSImage(cgImage: coreImage, size: imageSize).resized(to: NSSize(width: 16, height: 16))
    }
}

protocol LanguagesInfo: LanguageInfo {
    var languages: [String] { get }
    
    func processLanguagesPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String?
}

extension LanguagesInfo {
    func processLanguagesPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String? {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[language-count]]":
            return formatCount(languages.count, noneLabel: "no Language", singleLabel: "1 Language", manyLabel: "%d Languages", isFilled: &isFilled, useEmptyData: useEmptyData, formatAsString: false)
        case "[[languages]]":
            isFilled = !languages.isEmpty
            return isFilled ? languages.joined(separator: " ") : self.formatND(useEmptyData: useEmptyData)
        case "[[languages-flag]]":
            isFilled = !languages.isEmpty
            return isFilled ? languages.map({ Self.getCountryFlag(lang: $0) ?? "🏳" }).joined(separator: " ") : ""
        case "[[language-flag]]", "[[language]]":
            return self.processLanguagePlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        default:
            return nil
        }
    }
}
