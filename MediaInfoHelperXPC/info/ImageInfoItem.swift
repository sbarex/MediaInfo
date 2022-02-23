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
class ImageInfo: DimensionalInfo, FileInfo, PaperInfo {
    enum ColorTable: Int {
        case unknown
        case regular
        case indexed
        case float
    }
    
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
    let file: URL
    let fileSize: Int64
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
    
    init(file: URL, width: Int, height: Int, dpi: Int, colorMode: String, depth: Int, profileName:String, animated: Bool, withAlpha: Bool, colorTable: ColorTable, metadata: [String: [MetadataInfo]], metadataRaw: [String: String]) {
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
        self.withAlpha = withAlpha
        self.profileName = profileName
        self.colorTable = colorTable
        self.metadata = metadata
        self.metadataRaw = metadataRaw
        super.init(width: width, height: height)
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        
        self.dpi = coder.decodeInteger(forKey: "dpi")
        self.colorMode = coder.decodeObject(of: NSString.self, forKey: "colorMode") as String? ?? ""
        self.depth = coder.decodeInteger(forKey: "depth")
        self.profileName = coder.decodeObject(of: NSString.self, forKey: "profileName") as String? ?? ""
        self.isAnimated = coder.decodeBool(forKey: "isAnimated")
        self.withAlpha = coder.decodeBool(forKey: "withAlpha")
        self.colorTable = ColorTable(rawValue: coder.decodeInteger(forKey: "colorTable")) ?? .unknown
        var metadata: [String: [MetadataInfo]] = [:]
        var n = coder.decodeInteger(forKey: "metadata_n")
        
        let metadata_classes = Self.getMetaClasses()
        for metadata_class in metadata_classes {
            NSKeyedUnarchiver.setClass(metadata_class, forClassName: String(describing: metadata_class))
            NSKeyedUnarchiver.setClass(metadata_class, forClassName: "MediaInfo_Helper_XPC." + String(describing: metadata_class))
            NSKeyedUnarchiver.setClass(metadata_class, forClassName: NSStringFromClass(metadata_class))
        }
        
        for i in 0 ..< n {
            guard let key = coder.decodeObject(of: NSString.self, forKey: "metadata_key_\(i)") as String? else {
                break
            }
            let sub_items_count = coder.decodeInteger(forKey: "metadata_key_\(key)_n")
            var sub_metadata: [MetadataInfo] = []
            for j in 0 ..< sub_items_count {
                guard let data = coder.decodeObject(of: NSData.self, forKey: "metadata_key_\(key)_\(j)") as Data? else {
                    continue
                }
                do {
                    guard let meta = try NSKeyedUnarchiver.unarchivedObject(ofClasses: metadata_classes, from: data) as? MetadataBaseInfo else {
                        continue
                    }
                    sub_metadata.append(meta)
                } catch {
                    // let s = error.localizedDescription
                    continue
                }
            }
            if !sub_metadata.isEmpty {
                metadata[key] = sub_metadata
            }
        }
        self.metadata = metadata
        
        var metadata_raw: [String: String] = [:]
        n = coder.decodeInteger(forKey: "metadata_raw_n")
        for i in 0 ..< n {
            guard let key = coder.decodeObject(of: NSString.self, forKey: "metadata_raw_key_\(i)") as String? else {
                break
            }
            guard let data = coder.decodeObject(of: NSString.self, forKey: "metadata_raw_value_\(i)") as String? else {
                break
            }
            metadata_raw[key] = data
        }
        self.metadataRaw = metadata_raw
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        coder.encode(self.dpi, forKey: "dpi")
        coder.encode(self.colorMode as NSString, forKey: "colorMode")
        coder.encode(self.depth, forKey: "depth")
        coder.encode(self.profileName as NSString, forKey: "profileName")
        coder.encode(self.isAnimated, forKey: "isAnimated")
        coder.encode(self.withAlpha, forKey: "withAlpha")
        coder.encode(self.colorTable.rawValue, forKey: "colorTable")
        coder.encode(self.metadata.count, forKey: "metadata_n")
        
        for metadata_class in Self.getMetaClasses() {
            NSKeyedArchiver.setClassName(String(describing: metadata_class), for: metadata_class)
        }
        
        for (i, key) in self.metadata.keys.enumerated() {
            let items = self.metadata[key]!
            coder.encode(key as NSString, forKey: "metadata_key_\(i)")
            coder.encode(items.count, forKey: "metadata_key_\(key)_n")
            for (j, item) in items.enumerated() {
                let data = try! NSKeyedArchiver.archivedData(withRootObject: item.self, requiringSecureCoding: true)
                coder.encode(data as NSData, forKey: "metadata_key_\(key)_\(j)")
            }
        }
        
        coder.encode(self.metadataRaw.count, forKey: "metadata_raw_n")
        for (i, key) in self.metadataRaw.keys.enumerated() {
            let data = self.metadataRaw[key]!
            coder.encode(key as NSString, forKey: "metadata_raw_key_\(i)")
            coder.encode(data as NSString, forKey: "metadata_raw_value_\(i)")
        }
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeFileInfo(to: encoder)
        
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
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        switch placeholder {
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
            return NSLocalizedString(withAlpha ? "transparent" : "opaque", tableName: "LocalizableExt", comment: "")
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
            return "\(colorMode) \(depth) "+NSLocalizedString("bit", comment: "")
        case "[[depth]]":
            if depth > 0 {
                isFilled = true
                return "\(depth) "+NSLocalizedString("bit", comment: "")
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
                return NSLocalizedString("indexed", tableName: "LocalizableExt", comment: "")
            case .float:
                return NSLocalizedString("float", tableName: "LocalizableExt", comment: "")
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
                return "\(dpi) "+NSLocalizedString("dpi", comment: "")
            } else {
                return self.formatND(useEmptyData: useEmptyData)
            }
        
        case "[[print:cm]]", "[[print:mm]]", "[[print:in]]":
            if dpi > 0 {
                return processPlaceholder(placeholder[placeholder.startIndex..<placeholder.index(placeholder.endIndex, offsetBy: -2)]+":\(dpi)]]", settings: settings, isFilled: &isFilled, forItem: itemIndex)
            } else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]":
            return self.processFilePlaceholder(placeholder, settings: settings, isFilled: &isFilled)
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
                    return "\(w_print) × \(h_print) \(unit.label) (\(dpi) "+NSLocalizedString("dpi", tableName: "LocalizableExt", comment: "")+")"
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            } else {
                return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
            }
        }
    }
    
    override func processSpecialMenuItem(_ item: Settings.MenuItem, atIndex itemIndex: Int, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
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
        } else if item.template == "[[metadata]]" {
            guard !self.metadata.isEmpty else {
                return false
            }
            let metadata_submenu = NSMenu(title: NSLocalizedString("Metadata", tableName: "LocalizableExt", comment: ""))
            let keys = self.metadata.keys.sorted()
            let image = settings.isIconHidden
            settings.isIconHidden = true
            for key in keys {
                let items = self.metadata[key]!
                let mnu_item = NSMenuItem(title: key, action: nil, keyEquivalent: "")
                mnu_item.submenu = NSMenu(title: key)
                for item in items {
                    guard !item.isHidden, !item.value.isEmpty else {
                        continue
                    }
                    if item.label == "-" {
                        mnu_item.submenu!.addItem(NSMenuItem.separator())
                    } else {
                        let mnu_tag = self.createMenuItem(title: "\(item.label): \(item.value)", image: nil, settings: settings)
                        mnu_item.submenu!.addItem(mnu_tag)
                    }
                }
                if !mnu_item.submenu!.items.isEmpty {
                    metadata_submenu.addItem(mnu_item)
                }
            }
            settings.isIconHidden = image
            let metadata_mnu = self.createMenuItem(title: NSLocalizedString("Metadata", tableName: "LocalizableExt", comment: ""), image: item.image, settings: settings)
            metadata_mnu.submenu = metadata_submenu
            destination_sub_menu.addItem(metadata_mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, atIndex: itemIndex, inMenu: destination_sub_menu, withSettings: settings)
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
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
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

