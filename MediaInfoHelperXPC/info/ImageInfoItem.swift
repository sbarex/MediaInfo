//
//  ImageInfoItem.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import AVFoundation
import JavaScriptCore

// MARK: - ImageInfo
class ImageInfo: FileInfo, DimensionalInfo, PaperInfo {
    enum CodingKeys: String, CodingKey {
        case dpi
        case colorMode
        case depth
        case isAnimated
        case hasAlpha
        case profileName
        case isFloating
        case isIndexed
        case metadata
        case metadataRaw
    }
    
    enum ColorTable: Int {
        case unknown
        case regular
        case indexed
        case float
    }
    
    override class func updateSettings(_ settings: Settings, forItems items: [Settings.MenuItem]) {
        super.updateSettings(settings, forItems: items)
        for item in items {
            if item.template.contains("[[metadata]]") {
                settings.extractImageMetadata = true
                return
            } else if item.template.contains("[[script") {
                let r = BaseInfo.splitTokens(in: item.template)
                for result in r {
                    let placeholder = String(item.template[Range(result.range, in: item.template)!])
                    guard placeholder.hasPrefix("[[script-") else {
                        continue
                    }
                    guard let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64() else {
                        continue
                    }
                    if code.hasPrefix("/* require-metadata */") {
                        settings.extractImageMetadata = true
                        return
                    }
                }
            }
        }
        settings.extractImageMetadata = false
    }
    
    static func getMetaClasses() -> [AnyClass] {
        return [
            MetadataBaseInfo.self,
            MetadataExifInfo.self,
            MetadataGifInfo.self,
            MetadataPngInfo.self,
            MetadataIPTCInfo.self,
            MetadataJfifInfo.self,
            MetadataTiffInfo.self,
            MetadataHeicsInfo.self,
            MetadataGPSInfo.self,
            MetadataDNGInfo.self
        ]
    }
    
    let dpi: Int
    let colorMode: String
    let depth: Int
    let isAnimated: Bool
    
    var width: Int
    var height: Int
    var unit: String = "px"
    
    let withAlpha: Bool
    let profileName: String
    let colorTable: ColorTable
    let metadata: [String: [MetadataInfo]]
    let metadataRaw: [String: String]
    
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
    
    override var infoType: Settings.SupportedFile { return .image }
    
    init(file: URL, width: Int, height: Int, dpi: Int, colorMode: String, depth: Int, profileName:String, animated: Bool, withAlpha: Bool, colorTable: ColorTable, metadata: [String: [MetadataInfo]], metadataRaw: [String: String]) {
        self.dpi = dpi
        let color = colorMode.uppercased()
        if color.contains("GRAY") && depth == 1 {
            self.colorMode = NSLocalizedString("B/W", tableName: "LocalizableExt", comment: "")
        } else {
            self.colorMode = colorMode
        }
        self.depth = depth
        self.isAnimated = animated
        self.withAlpha = withAlpha
        self.profileName = profileName
        self.colorTable = colorTable
        self.metadata = metadata
        self.metadataRaw = metadataRaw
        self.width = width
        self.height = height
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let dim = try Self.decodeDimension(from: decoder)
        self.width = dim.width
        self.height = dim.height
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dpi = try container.decode(Int.self, forKey: .dpi)
        self.colorMode = try container.decode(String.self, forKey: .colorMode)
        self.depth = try container.decode(Int.self, forKey: .depth)
        self.isAnimated = try container.decode(Bool.self, forKey: .isAnimated)
        self.withAlpha = try container.decode(Bool.self, forKey: .hasAlpha)
        self.profileName = try container.decode(String.self, forKey: .profileName)
        if try container.decode(Bool.self, forKey: .isFloating) {
            self.colorTable = .float
        } else if try container.decode(Bool.self, forKey: .isIndexed) {
            self.colorTable = .indexed
        } else {
            self.colorTable = .regular
        }
        
        self.metadata = try container.decode([String: [MetadataBaseInfo]].self, forKey: .metadata)
        self.metadataRaw = try container.decode([String:String].self, forKey: .metadataRaw)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeDimension(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.dpi, forKey: .dpi)
        try container.encode(self.colorMode, forKey: .colorMode)
        try container.encode(self.depth, forKey: .depth)
        try container.encode(self.isAnimated, forKey: .isAnimated)
        try container.encode(self.withAlpha, forKey: .hasAlpha)
        try container.encode(self.profileName, forKey: .profileName)
        try container.encode(self.colorTable == .float, forKey: .isFloating)
        try container.encode(self.colorTable == .indexed, forKey: .isIndexed)
        try container.encode(self.metadata as? [String: [MetadataBaseInfo]], forKey: .metadata)
        try container.encode(self.metadataRaw, forKey: .metadataRaw)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        switch placeholder {
        case "[[size]]", "[[width]]", "[[height]]", "[[ratio]]", "[[resolution]]":
            return self.processDimensionPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
        case "[[animated]]":
            isFilled = true
            return NSLocalizedString(isAnimated ? "animated" : "static", tableName: "LocalizableExt", comment: "")
        case "[[is-animated]]":
            if isAnimated {
                isFilled = true
                return NSLocalizedString("animated", tableName: "LocalizableExt", comment: "")
            } else {
                isFilled = false
                return ""
            }
        case "[[alpha]]":
            isFilled = true
            return NSLocalizedString(withAlpha ? "with alpha channel" : "opaque", tableName: "LocalizableExt", comment: "")
        case "[[is-alpha]]":
            if withAlpha {
                isFilled = true
                return NSLocalizedString("with alpha channel", tableName: "LocalizableExt", comment: "")
            } else {
                isFilled = false
                return ""
            }
        case "[[color]]":
            isFilled = !colorMode.isEmpty
            return colorMode
        case "[[color-depth]]":
            isFilled = true
            return "\(colorMode) "+String(format: NSLocalizedString("%d bit", comment: ""), self.depth)
        case "[[depth]]":
            if depth > 0 {
                isFilled = true
                return String(format: NSLocalizedString("%d bit", comment: ""), self.depth)
            } else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
        case "[[color-table]]":
            isFilled = colorTable != .unknown
            switch colorTable {
            case .unknown:
                return ""
            case .regular:
                return NSLocalizedString("normal", tableName: "LocalizableExt", comment: "")
            case .indexed:
                return NSLocalizedString("indexed colors", tableName: "LocalizableExt", comment: "")
            case .float:
                return NSLocalizedString("float colors", tableName: "LocalizableExt", comment: "")
            }
        case "[[profile-name]]":
            guard !profileName.isEmpty else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            isFilled = true
            return profileName
        case "[[dpi]]":
            isFilled = dpi > 0
            if dpi > 0 {
                return String(format: NSLocalizedString("%d dpi", comment: ""), dpi)
            } else {
                return self.formatND(useEmptyData: useEmptyData)
            }
        
        case "[[print:cm]]", "[[print:mm]]", "[[print:in]]":
            if dpi > 0 {
                return processPlaceholder(placeholder[placeholder.startIndex..<placeholder.index(placeholder.endIndex, offsetBy: -2)]+":\(dpi)]]", settings: settings, isFilled: &isFilled, forItem: item)
            } else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
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
                
                if let w_print = Self.numberFormatter.string(from: NSNumber(value: Double(width) / Double(dpi) * unit.scale)), let h_print = Self.numberFormatter.string(from: NSNumber(value: Double(height) / Double(dpi) * unit.scale)) {
                        
                    isFilled = true
                    let s = String(format:NSLocalizedString("%d dpi", tableName: "LocalizableExt", comment: ""), dpi)
                    return "\(w_print) × \(h_print) \(unit.label) (\(s))"
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            } else {
                return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
            }
        }
    }
    
    override func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.menuItem.template.hasPrefix("[[print:") {
            let s = item.menuItem.template.trimmingCharacters(in: CharacterSet(charactersIn: "[]")) .split(separator: ":")
            guard s.count > 2 else {
                return false
            }
            
            guard let um = PrintUnit(placeholder: String(s[1])),  let dpi = Int(String(s[2])), dpi == self.dpi else {
                return false
            }
            
            for item2 in settings.imageMenuItems {
                guard item2.template != item.menuItem.template else {
                    continue
                }
                if item2.template == "[[print:\(um.placeholder)]]" {
                    // Prevents duplicate menu items.
                    return true
                }
            }
            
            return false
        } else if item.menuItem.template == "[[metadata]]" {
            guard !self.metadata.isEmpty else {
                return false
            }
            let metadata_submenu = NSMenu(title: NSLocalizedString("Metadata", tableName: "LocalizableExt", comment: ""))
            let keys = self.metadata.keys.sorted()
            let iconHidden = settings.isIconHidden
            settings.isIconHidden = true
            for key in keys {
                var subItemInfo = item
                subItemInfo.userInfo["metadata_key"] = String(key)
                
                let items = self.metadata[key]!
                let mnu_item = NSMenuItem(title: key, action: nil, keyEquivalent: "")
                mnu_item.submenu = NSMenu(title: key)
                mnu_item.representedObject = subItemInfo
                for (i, item) in items.enumerated() {
                    guard !item.isHidden, !item.value.isEmpty else {
                        continue
                    }
                    if item.label == "-" {
                        mnu_item.submenu!.addItem(NSMenuItem.separator())
                    } else {
                        var subItemInfo2 = subItemInfo
                        subItemInfo2.userInfo["metadata_key_index"] = i
                        
                        let mnu_tag = self.createMenuItem(title: "\(item.label): \(item.value)", image: nil, settings: settings, representedObject: subItemInfo2)
                        mnu_item.submenu!.addItem(mnu_tag)
                    }
                }
                if !mnu_item.submenu!.items.isEmpty {
                    metadata_submenu.addItem(mnu_item)
                }
            }
            settings.isIconHidden = iconHidden
            let metadata_mnu = self.createMenuItem(title: NSLocalizedString("Metadata", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, settings: settings, representedObject: item)
            metadata_mnu.submenu = metadata_submenu
            destination_sub_menu.addItem(metadata_mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
    
    override var standardMainItem: MenuItemInfo {
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
        
        return MenuItemInfo(fileType: self.infoType, index: -1, item: Settings.MenuItem(image: "image", template: template))
    }
    
    override internal func getImage(for name: String) -> NSImage? {
        if let image = self.getDimensionImage(for: name) {
            return super.getImage(for: image)
        }
        var image: String
        switch name {
        case "color":
            image = self.color_image_name
        default:
            image = name
        }
        return super.getImage(for: image)
    }
    
    static func parseExif(dict: [CFString: AnyHashable])->[MetadataExifInfo] {
        var metadata: [MetadataExifInfo] = []
        for item in dict {
            if let m = MetadataExifInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseExifAux(dict: [CFString: AnyHashable])->[MetadataExifAuxInfo] {
        var metadata: [MetadataExifAuxInfo] = []
        for item in dict {
            if let m = MetadataExifAuxInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseTiffDictionary(dict: [CFString: AnyHashable])->[MetadataTiffInfo] {
        var metadata: [MetadataTiffInfo] = []
        for item in dict {
            if let m = MetadataTiffInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseJfifDictionary(dict: [CFString: AnyHashable])->[MetadataJfifInfo] {
        var metadata: [MetadataJfifInfo] = []
        for item in dict {
            if let m = MetadataJfifInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseGifDictionary(dict: [CFString: AnyHashable])->[MetadataGifInfo] {
        var metadata: [MetadataGifInfo] = []
        for item in dict {
            if let m = MetadataGifInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseHeicsDictionary(dict: [CFString: AnyHashable])->[MetadataHeicsInfo] {
        var metadata: [MetadataHeicsInfo] = []
        for item in dict {
            if let m = MetadataHeicsInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parsePngDictionary(dict: [CFString: AnyHashable])->[MetadataPngInfo] {
        var metadata: [MetadataPngInfo] = []
        for item in dict {
            if let m = MetadataPngInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseIptcDictionary(dict: [CFString: AnyHashable])->[MetadataIPTCInfo] {
        var metadata: [MetadataIPTCInfo] = []
        for item in dict {
            if let m = MetadataIPTCInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseGPSDictionary(dict: [CFString: AnyHashable])->[MetadataGPSInfo] {
        var metadata: [MetadataGPSInfo] = []
        for item in dict {
            if let m = MetadataGPSInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseDNGDictionary(dict: [CFString: AnyHashable])->[MetadataDNGInfo] {
        var metadata: [MetadataDNGInfo] = []
        for item in dict {
            if let m = MetadataDNGInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
    
    static func parseMetadataDictionary(dict: [CFString: AnyHashable])->[MetadataBaseInfo] {
        var metadata: [MetadataBaseInfo] = []
        for item in dict {
            if let m = MetadataBaseInfo(code: item.key, value: item.value) {
                metadata.append(m)
            }
        }
        metadata.sort(by: { $0.index < $1.index })
        
        return metadata
    }
}

