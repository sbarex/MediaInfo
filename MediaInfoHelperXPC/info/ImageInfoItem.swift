//
//  ImageInfoItem.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

// MARK: - ImageInfo
class ImageInfo: DimensionalInfo, FileInfo, PaperInfo {
    let dpi: Int
    let colorMode: String
    let depth: Int
    let isAnimated: Bool
    let file: URL
    let fileSize: Int64
    
    var color_image_name: String {
        let color = colorMode.uppercased()
        if color.contains("RGB") {
            return "color_rgb"
        } else if color.contains("CMYK") {
            return "color_cmyk"
        } else if color.contains("CMYK") {
            return "color_rgb"
        } else if color.contains("LAB") {
            return "color_lab"
        } else if color.contains("GRAY") || color.contains("B/W") {
            return depth == 1 ? "color_bw" : "color_gray"
        } else {
            return "color"
        }
    }
    
    init(file: URL, width: Int, height: Int, dpi: Int, colorMode: String, depth: Int, animated: Bool) {
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        self.dpi = dpi
        let color = colorMode.uppercased()
        if color.contains("GRAY") && depth == 1 {
            self.colorMode = NSLocalizedString("B/W", tableName: "LocalizableExt", comment: "")
        } else {
            self.colorMode = colorMode
        }
        self.depth = depth
        self.isAnimated = animated
        
        super.init(width: width, height: height)
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        
        self.dpi = coder.decodeInteger(forKey: "dpi")
        self.colorMode = coder.decodeObject(forKey: "colorMode") as? String ?? ""
        self.depth = coder.decodeInteger(forKey: "depth")
        self.isAnimated = coder.decodeBool(forKey: "isAnimated")
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        coder.encode(self.dpi, forKey: "dpi")
        coder.encode(self.colorMode, forKey: "colorMode")
        coder.encode(self.depth, forKey: "depth")
        coder.encode(self.isAnimated, forKey: "isAnimated")
        
        super.encode(with: coder)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String: Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[animated]]":
            return self.format(value: values?["is-animated"] ?? isAnimated, isFilled: &isFilled) { v, isFilled in
                if let animated = v as? Bool {
                    isFilled = true
                    return NSLocalizedString(animated ? "animated" : "static", tableName: "LocalizableExt", comment: "")
                } else {
                    isFilled = false
                    return useEmptyData ? "N/D" : ""
                }
            }
        case "[[is-animated]]":
            return self.format(value: values?["is-animated"] ?? isAnimated, isFilled: &isFilled) { v, isFilled in
                if let animated = v as? Bool, animated {
                    isFilled = true
                    return NSLocalizedString("animated", tableName: "LocalizableExt", comment: "")
                } else {
                    isFilled = false
                    return ""
                }
            }
        case "[[color]]":
            return self.format(value: values?["color"] ?? self.colorMode, isFilled: &isFilled) { v, isFilled in
                guard let color = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return color
            }
        case "[[color-depth]]":
            return self.format(value: [values?["color"] ?? self.colorMode, values?["depth"] ?? self.depth], isFilled: &isFilled) { v, isFilled in
                guard let i = v as? [Any], let color = i[0] as? String, let depth = i[1] as? Int else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return "\(color) \(depth) "+NSLocalizedString("bit", comment: "")
            }
        case "[[depth]]":
            return self.format(value: values?["depth"] ?? depth, isFilled: &isFilled) { v, isFilled in
                if let depth = v as? Int, depth > 0 {
                    isFilled = true
                    return "\(depth) "+NSLocalizedString("bit", comment: "")
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        case "[[dpi]]":
            return self.format(value: values?["dpi"] ?? dpi, isFilled: &isFilled) { v, isFilled in
                if let dpi = v as? Int, dpi > 0 {
                    isFilled = true
                    return "\(dpi) "+NSLocalizedString("dpi", comment: "")
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        
        case "[[print:cm]]", "[[print:mm]]", "[[print:in]]":
            if dpi > 0 {
                return processPlaceholder(placeholder[placeholder.startIndex..<placeholder.index(placeholder.endIndex, offsetBy: -2)]+":\(dpi)]]", settings: settings, values: values, isFilled: &isFilled)
            } else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]":
            return self.processFilePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[paper]]":
            if self.dpi <= 0 {
                isFilled = false
                return ""
            }
            let w = (Double(self.width) / Double(self.dpi)) * 25.4
            let h = (Double(self.height) / Double(self.dpi)) * 25.4
            let paper = Self.getPaperSize(width: w, height: h)
            isFilled = paper != nil && !paper!.isEmpty
            return paper ?? ""
        default:
            if placeholder.hasPrefix("[[print:") {
                let tokens = placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).split(separator: ":")
                guard tokens.count == 3, let dpi = Int(tokens[2]) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                guard dpi > 0 else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
                
                guard let unit = PrintUnit(placeholder: String(tokens[1])) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                
                return format(value: [values?["width"] ?? width, values?["height"] ?? height], isFilled: &isFilled) { v, isFilled in
                    guard let dim = v as? [Int] else {
                        isFilled = false
                        return self.formatERR(useEmptyData: useEmptyData)
                    }
                    let width = dim[0]
                    let height = dim[1]
                    
                    if let w_print = Self.numberFormatter.string(from: NSNumber(value: Double(width) / Double(dpi) * unit.scale)), let h_print = Self.numberFormatter.string(from: NSNumber(value: Double(height) / Double(dpi) * unit.scale)) {
                            
                        isFilled = true
                        return "\(w_print) × \(h_print) \(unit.label) (\(dpi) "+NSLocalizedString("dpi", tableName: "LocalizableExt", comment: "")+")"
                    } else {
                        isFilled = false
                        return self.formatND(useEmptyData: useEmptyData)
                    }
                }
            } else {
                return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
            }
        }
    }
    
    override func processSpecialMenuItem(_ item: Settings.MenuItem, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template.hasPrefix("[[print:") {
            let s = item.template.trimmingCharacters(in: CharacterSet(charactersIn: "[]")) .split(separator: ":")
            guard s.count > 2 else {
                return false
            }
            
            guard let um = PrintUnit(placeholder: String(s[1])),  let dpi = Int(String(s[2])), dpi == self.dpi else {
                return false
            }
            
            for item2 in settings.imageMenuItems {
                guard item2.template != item.template else {
                    continue
                }
                if item2.template == "[[print:\(um.placeholder)]]" {
                    // Prevents duplicate menu items.
                    return true
                }
            }
            
            return false
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        var template = "[[size]]"
        if self.isAnimated {
            template += " ([[is-animated]])"
        }
        
        if !self.colorMode.isEmpty {
            template += ", [[color-depth]]"
        }
        if self.dpi > 0 {
            template += " ([[dpi]])"
        }
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled)
        return isFilled ? title : ""
    }
    
    override internal func getImage(for name: String) -> NSImage? {
        var image: String
        switch name {
        case "color":
            image = self.color_image_name
        default:
            image = name
        }
        return super.getImage(for: image)
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.imageMenuItems, image: self.getImage(for: "image"), withSettings: settings)
    }
}
