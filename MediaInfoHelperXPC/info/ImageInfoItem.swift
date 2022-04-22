//
//  ImageInfoItem.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import AVFoundation

extension BaseInfo.ExtraName {
    static let svg_responsive = BaseInfo.ExtraName(name: "svg_responsive")
}

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
                settings.imageSettings.extractMetadata = true
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
                        settings.imageSettings.extractMetadata = true
                        return
                    }
                }
            }
        }
        settings.imageSettings.extractMetadata = false
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
    
    override class var infoType: Settings.SupportedFile { return .image }
    
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
    
    override func fetchMetadata(from metadata: MDItem) {
        super.fetchMetadata(from: metadata)
        
        var i: Int = 0
        var i64: Int = 0
        var d: Double = 0
        if let m = MDItemCopyAttribute(metadata, kMDItemPixelHeight), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The height, in pixels, of the contents. For example, the image height or the video frame height. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemPixelHeight as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemPixelWidth), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The width, in pixels, of the contents. For example, the image width or the video frame width. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemPixelWidth as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemPixelCount), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The total number of pixels in the contents. Same as kMDItemPixelWidth x kMDItemPixelHeight. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemPixelCount as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemColorSpace), CFGetTypeID(m) == CFStringGetTypeID() {
            // The color space model used by the document contents. For example, “RGB”, “CMYK”, “YUV”, or “YCbCr”. A CFString.
            self.spotlightMetadata[kMDItemColorSpace as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemBitsPerSample), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The number of bits per sample. For example, the bit depth of an image (8-bit, 16-bit etc...) or the bit depth per audio sample of uncompressed audio data (8, 16, 24, 32, 64, etc..). A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemBitsPerSample as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemFlashOnOff), CFGetTypeID(m) == CFNumberGetTypeID() {
            // Indicates if a camera flash was used. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemFlashOnOff as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemFocalLength), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The actual focal length of the lens, in millimeters. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemFocalLength as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAcquisitionMake), CFGetTypeID(m) == CFStringGetTypeID() {
            // The manufacturer of the device used to aquire the document contents. A CFString.
            self.spotlightMetadata[kMDItemAcquisitionMake as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAcquisitionModel), CFGetTypeID(m) == CFStringGetTypeID() {
            // The model of the device used to aquire the document contents. For example, 100, 200, 400, etc. A CFString.
            self.spotlightMetadata[kMDItemAcquisitionModel as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemISOSpeed), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The ISO speed used to acquire the document contents. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemISOSpeed as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemOrientation), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The orientation of the document contents. Possible values are 0 (landscape) and 1 (portrait). A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.sInt64Type, &i64)
            self.spotlightMetadata[kMDItemOrientation as String] = i64 == 0 ? "landscape" : "portrait"
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemLayerNames), CFGetTypeID(m) == CFArrayGetTypeID() {
            // The names of the layers in the file. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemLayerNames as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemWhiteBalance), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The white balance setting used to acquire the document contents. Possible values are 0 (auto white balance) and 1 (manual). A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemWhiteBalance as String] = i == 0 ? "auto" : "manual"
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAperture), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The aperture setting used to acquire the document contents. This unit is the APEX value. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemAperture as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemProfileName), CFGetTypeID(m) == CFStringGetTypeID() {
            // The name of the color profile used by the document contents. A CFString.
            self.spotlightMetadata[kMDItemProfileName as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemResolutionWidthDPI), CFGetTypeID(m) == CFNumberGetTypeID() {
            // Resolution width, in DPI, of this image. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemResolutionWidthDPI as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemResolutionHeightDPI), CFGetTypeID(m) == CFNumberGetTypeID() {
            // Resolution height, in DPI, of this image. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemResolutionHeightDPI as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemExposureMode), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The exposure mode used to acquire the document contents. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemExposureMode as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemExposureTimeSeconds), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The exposure time, in seconds, used to acquire the document contents. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemExposureTimeSeconds as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemEXIFVersion), CFGetTypeID(m) == CFStringGetTypeID() {
            // The version of the EXIF header used to generate the metadata. A CFString.
            self.spotlightMetadata[kMDItemEXIFVersion as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAlbum), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The title for a collection of media. This is analagous to a record album, or photo album. A CFString.
            self.spotlightMetadata[kMDItemAlbum as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemHasAlphaChannel), CFGetTypeID(m) == CFBooleanGetTypeID() {
            // Indicates if this image file has an alpha channel. A CFBoolean.
            let b = CFBooleanGetValue((m as! CFBoolean))
            self.spotlightMetadata[kMDItemHasAlphaChannel as String] = NSLocalizedString(b ? "Yes" : "No", tableName: "LocalizableExt", comment: "")
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemRedEyeOnOff), CFGetTypeID(m) == CFBooleanGetTypeID() {
            // Indicates if red-eye reduction was used to take the picture. A CFBoolean.
            let b = CFBooleanGetValue((m as! CFBoolean))
            self.spotlightMetadata[kMDItemRedEyeOnOff as String] = NSLocalizedString(b ? "Yes" : "No", tableName: "LocalizableExt", comment: "")
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemMeteringMode), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The metering mode used to take the image. A Int64.
            CFNumberGetValue((m as! CFNumber), CFNumberType.sInt64Type, &i64)
            self.spotlightMetadata[kMDItemMeteringMode as String] = i64
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemMaxAperture), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The smallest f-number of the lens. Ordinarily it is given in the range of 00.00 to 99.99. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemMaxAperture as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemFNumber), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The diameter of the diaphragm aperture in terms of the effective focal length of the lens.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemFNumber as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemExposureProgram), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The class of the exposure program used by the camera to set exposure when the image is taken. Possible values include: Manual, Normal, and Aperture priority. A Int64.
            CFNumberGetValue((m as! CFNumber), CFNumberType.sInt64Type, &i64)
            self.spotlightMetadata[kMDItemExposureProgram as String] = i64
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemExposureTimeString), CFGetTypeID(m) == CFStringGetTypeID() {
            // The time of the exposure. A CFString.
            self.spotlightMetadata[kMDItemExposureTimeString as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemEXIFGPSVersion), CFGetTypeID(m) == CFStringGetTypeID() {
            // The version of GPSInfoIFD in EXIF used to generate the metadata. A CFString.
            self.spotlightMetadata[kMDItemEXIFGPSVersion as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAltitude), CFGetTypeID(m) == CFStringGetTypeID() {
            // The altitude of the item in meters above sea level, expressed using the WGS84 datum. Negative values lie below sea level. A CFString.
            self.spotlightMetadata[kMDItemAltitude as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemLatitude), CFGetTypeID(m) == CFStringGetTypeID() {
            // The latitude of the item in degrees north of the equator, expressed using the WGS84 datum. Negative values lie south of the equator. A CFString.
            self.spotlightMetadata[kMDItemLatitude as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemLongitude), CFGetTypeID(m) == CFStringGetTypeID() {
            // The longitude of the item in degrees east of the prime meridian, expressed using the WGS84 datum. Negative values lie west of the prime meridian. A CFString.
            self.spotlightMetadata[kMDItemLongitude as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemTimestamp), CFGetTypeID(m) == CFStringGetTypeID() {
            // The timestamp on the item. This generally is used to indicate the time at which the event captured by the item took place. A CFString.
            self.spotlightMetadata[kMDItemTimestamp as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemSpeed), CFGetTypeID(m) == CFStringGetTypeID() {
            // The speed of the item, in kilometers per hour. A CFString.
            self.spotlightMetadata[kMDItemSpeed as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemGPSTrack), CFGetTypeID(m) == CFStringGetTypeID() {
            // The direction of travel of the item, in degrees from true north. A CFString.
            self.spotlightMetadata[kMDItemGPSTrack as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemImageDirection), CFGetTypeID(m) == CFStringGetTypeID() {
            // The direction of the item's image, in degrees from true north. A CFString.
            self.spotlightMetadata[kMDItemImageDirection as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemNamedLocation), CFGetTypeID(m) == CFStringGetTypeID() {
            // The name of the location or point of interest associated with the item. The name may be user provided. A CFString.
            self.spotlightMetadata[kMDItemNamedLocation as String] = m as! String
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[size]]", "[[width]]", "[[height]]", "[[ratio]]", "[[resolution]]", "[[pixel-count]]", "[[mega-pixel]]":
            return self.processDimensionPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
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
                return processPlaceholder(placeholder[placeholder.startIndex..<placeholder.index(placeholder.endIndex, offsetBy: -2)]+":\(dpi)]]", isFilled: &isFilled, forItem: item)
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
                return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
            }
        }
    }
    
    override func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        if item.menuItem.template.hasPrefix("[[print:") {
            let s = item.menuItem.template.trimmingCharacters(in: CharacterSet(charactersIn: "[]")) .split(separator: ":")
            guard s.count > 2 else {
                return false
            }
            
            guard let um = PrintUnit(placeholder: String(s[1])),  let dpi = Int(String(s[2])), dpi == self.dpi else {
                return false
            }
            
            for item2 in self.currentSettings?.templates ?? [] {
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
            let iconHidden = (self.globalSettings?.isIconHidden ?? false)
            self.globalSettings?.isIconHidden = true
            for key in keys {
                var subItemInfo = item
                subItemInfo.userInfo["metadata_key"] = String(key)
                
                let items = self.metadata[key]!
                let mnu_item = NSMenuItem(title: key, action: nil, keyEquivalent: "")
                mnu_item.submenu = NSMenu(title: key)
                mnu_item.representedObject = subItemInfo
                
                let sorted: [(item: MetadataInfo, index: Int)] = items.enumerated().map({ (item: $0.element, index: $0.offset )}).sorted(by: { a, b in
                    return a.item.label < b.item.label
                })
                
                for element in sorted {
                    let item = element.item
                    let i = element.index
                    guard !item.isHidden, !item.value.isEmpty else {
                        continue
                    }
                    if item.label == "-" {
                        mnu_item.submenu!.addItem(NSMenuItem.separator())
                    } else {
                        var subItemInfo2 = subItemInfo
                        subItemInfo2.userInfo["metadata_key_index"] = i
                        let mnu_tag: NSMenuItem
                        if self.globalSettings?.isMetadataExpanded ?? false {
                            mnu_tag = self.createMenuItem(title: item.label, image: nil, representedObject: subItemInfo2)
                            mnu_tag.submenu = NSMenu()
                            mnu_tag.submenu?.addItem(self.createMenuItem(title: item.value, image: nil, representedObject: subItemInfo2))
                        } else {
                            mnu_tag = self.createMenuItem(title: "\(item.label): \(item.value)", image: nil, representedObject: subItemInfo2)
                        }
                        mnu_item.submenu!.addItem(mnu_tag)
                    }
                }
                if !mnu_item.submenu!.items.isEmpty {
                    metadata_submenu.addItem(mnu_item)
                }
            }
            self.globalSettings?.isIconHidden = iconHidden
            let metadata_mnu = self.createMenuItem(title: NSLocalizedString("Metadata", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, representedObject: item)
            metadata_mnu.submenu = metadata_submenu
            destination_sub_menu.addItem(metadata_mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
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
        
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "image", template: template))
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

