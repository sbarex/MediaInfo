//
//  BaseInfoItems.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

// MARK: - BaseInfo
class BaseInfo: NSCoding {
    static let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = true
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        
        return numberFormatter
    }()
    static let byteCountFormatter:ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        
        return formatter
    }()
    
    static func getImage(for mode: String) -> NSImage? {
        var img: NSImage?
        var isColor = false
        switch mode {
        case "image":
            img = NSImage(named: "image")
        case "image_v":
            img = NSImage(named: "image_v")
        case "color":
            img = NSImage(named: "color")
        case "color_rgb":
            img = NSImage(named: "color_rgb")
            isColor = true
        case "color_cmyk":
            img = NSImage(named: "color_cmyk")
            isColor = true
        case "color_gray":
            img = NSImage(named: "color_gray")
            isColor = true
        case "color_lab":
            img = NSImage(named: "color_lab")
            isColor = true
        case "color_bw":
            img = NSImage(named: "color_bw")
            isColor = true
        case "print":
            img = NSImage(named: "print")
        case "video":
            img = NSImage(named: "video")
        case "video_v":
            img = NSImage(named: "video_v")
        case "audio":
            img = NSImage(named: "audio")
        case "text":
            img = NSImage(named: "txt")
        case "ratio":
            img = NSImage(named: "aspectratio")
        case "ratio_v":
            img = NSImage(named: "aspectratio_v")
        case "size":
            img = NSImage(named: "size")
        case "page":
            img = NSImage(named: "page")
        case "page_v":
            img = NSImage(named: "page_v")
            
        case "pages":
            img = NSImage(named: "pages")
        case "tag":
            img = NSImage(named: "tag")
        case "pencil":
            img = NSImage(named: "pencil")
            
        case "office":
            img = NSImage(named: "doc")
        case "doc", "docx", "word":
            img = NSImage(named: "doc")
        case "xls", "xlsx", "excel":
            img = NSImage(named: "xls")
        case "ppt", "pptx", "powerpoint":
            img = NSImage(named: "ppt")
        case "abc":
            img = NSImage(named: "abc")
        case "speaker":
            img = NSImage(named: "speaker_mono")
            
        case "3d", "3D":
            img = NSImage(named: "3d")
        case "3d_color":
            img = NSImage(named: mode)
            isColor = true
        case "3d_occlusion":
            img = NSImage(named: mode)
            isColor = true
            
        default:
            img = NSImage(named: mode)
        }
        
        img = img?.resized(to: NSSize(width: 16, height: 16))
        if !isColor {
            img?.isTemplate = true
            let i = img?.image(withTintColor: NSColor.labelColor)
            i?.isTemplate = true
            return i
        } else {
            return img
        }
    }
    
    init() { }
    required init?(coder: NSCoder) {
        
    }
    func encode(with coder: NSCoder) {
        
    }
    
    internal func format(value: Any?, isFilled: inout Bool, convert: ((Any?, inout Bool)->String)? = nil) -> String {
        let v = value
        let s: String
        if let convert = convert {
            s = convert(v, &isFilled)
        } else if let t = v as? String {
            isFilled = !t.isEmpty
            s = t
        } else if let t = v {
            isFilled = true
            s = "\(t)"
        } else {
            isFilled = false
            s = self.formatND(useEmptyData: false)
        }
        
        return s
    }
    
    internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String: Any]? = nil, isFilled: inout Bool) -> String {
        isFilled = false
        return placeholder
    }
    
    func purgeString(_ text: String) -> String {
        var text = text
        // Remove empty brackets: empty, or with only spaces, comma, semicolon or pipe.
        text = text.replacingOccurrences(of: #"\s*\([\s,;|]*\)"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s*\[[\s,;|]*\]"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s*\<[\s,;|]*\>"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s*\{[\s,;|]*\}"#, with: " ", options: .regularExpression)
        // Remove consecutive comma (or semicolon or pipe) separated only by spaces.
        text = text.replacingOccurrences(of: #"[,;|]\s*([,;|])"#, with: "$1", options: .regularExpression)
        // Remove multiple spaces
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        // Trim spaces, comma, semicolon and pipe.
        text = text.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ",;|")))
        // Capitalize first letter.
        text = text.capitalizingFirstLetter()
        
        return text
    }
    
    /// Translate the placeholder inside the template
    /// - parameters:
    ///   - template: Template with the placeholders to replace.
    ///   - settings: Settings used to customize the data.
    ///   - values: Values that override the standard value.
    ///   - isFilled: Set to `true` when at least one placeholder is replaced.
    func replacePlaceholders(in template: String, settings: Settings, values: [String: Any]? = nil, isFilled: inout Bool) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return template
        }
        let results = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        
        var text = template
       
        isFilled = false
        var isPlaceholderFilled = false
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r = processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isPlaceholderFilled)
            if isPlaceholderFilled {
                isFilled = true
            }
            text = text.replacingOccurrences(of: placeholder, with: r)
        }
        
        text = purgeString(text)
        
        return text
    }
    
    /// Translate the placeholder inside the template
    /// - parameters:
    ///   - template: Template with the placeholders to replace.
    ///   - settings: Settings used to customize the data.
    ///   - attributes: Attributes used to format the value of placeholders.
    ///   - values: Values that override the standard value.
    ///   - isFilled: Set to `true` when at least one placeholder is replaced.
    func replacePlaceholders(in template: String, settings: Settings, values: [String: Any]? = nil, attributes: [NSAttributedString.Key: Any]? = nil, isFilled: inout Bool) -> NSMutableAttributedString {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return NSMutableAttributedString(string: template)
        }
        let results = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        
        let text = NSMutableAttributedString(string: template)
        
        isFilled = false
        var isPlaceholderFilled = false
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r = processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isPlaceholderFilled)
            if isPlaceholderFilled {
                isFilled = true
            }
            guard r != placeholder else {
                continue
            }
            while text.mutableString.contains(placeholder) {
                let range = text.mutableString.range(of: placeholder)
                text.replaceCharacters(in: range, with: NSAttributedString(string: r, attributes: attributes))
            }
        }
        
        // Remove empty brackets: empty, or with only spaces, comma, semicolon or pipe.
        text.mutableString.replaceOccurrences(of: #"\s*\([\s,;|]*\)"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        text.mutableString.replaceOccurrences(of: #"\s*\[[\s,;|]*\]"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        text.mutableString.replaceOccurrences(of: #"\s*\<[\s,;|]*\>"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        text.mutableString.replaceOccurrences(of: #"\s*\{[\s,;|]*\}"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        // Remove consecutive comma (or semicolon or pipe) separated only by spaces.
        text.mutableString.replaceOccurrences(of: #"[,;|]\s*([,;|])"#, with: "$1", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        // Remove multiple spaces
        text.mutableString.replaceOccurrences(of: #"\s+"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        
        // Trim spaces, comma, semicolon and pipe.
        text.trimCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ",;|")))
        // Capitalize first letter.
        return text.capitalizingFirstLetter()
    }
    
    static func replacePlaceholdersFake(in template: String, settings: Settings, attributes: [NSAttributedString.Key: Any]? = nil) -> NSMutableAttributedString {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return NSMutableAttributedString(string: template)
        }
        let results = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        
        let text = NSMutableAttributedString(string: template)
        
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r = "<" + placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "[]")) + ">"
            guard r != placeholder else {
                continue
            }
            while text.mutableString.contains(placeholder) {
                let range = text.mutableString.range(of: placeholder)
                text.replaceCharacters(in: range, with: NSAttributedString(string: r, attributes: attributes))
            }
        }
        
        return text
    }
    
    func getStandardTitle(forSettings settings: Settings) -> String {
        return ""
    }
    
    internal func getImage(for name: String) -> NSImage? {
        return Self.getImage(for: name)
    }
    
    internal func createMenuItem(title: String, image: String?, settings: Settings) -> NSMenuItem {
        let mnu = NSMenuItem(title: title, action: #selector(self.fakeMenuAction(_:)), keyEquivalent: "")
        mnu.isEnabled = true
        mnu.target = self
        if !settings.isIconHidden {
            if let image = image, !image.isEmpty {
                mnu.image = self.getImage(for: image)
            } else {
                mnu.image = self.getImage(for: "no-image")
            }
        } else {
            mnu.image = nil
        }
        return mnu
    }
    
    func getMenu(withSettings settings: Settings) -> NSMenu? {
        return nil
    }
    
    internal func generateMenu(items: [Settings.MenuItem], image: NSImage?, withSettings settings: Settings) -> NSMenu? {
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let use_submenu  = settings.isInfoOnSubMenu
        
        // ALERT: NSMenuItem in the extension do not preserve the image template rendering mode, delegate, attributedTitle (rendered as simple string), isAlternate, separator (render as a menu item with an empty title). See the FIFinderSyncProtocol source file for the list of valid properties.
        
        let destination_sub_menu: NSMenu
        if use_submenu {
            let info_sub_menu = NSMenu(title: "MediaInfo")
            let info_mnu = menu.addItem(withTitle: "MediaInfo", action: nil, keyEquivalent: "")
            info_mnu.image = image
            
            menu.setSubmenu(info_sub_menu, for: info_mnu)
            destination_sub_menu = info_sub_menu
        } else {
            destination_sub_menu = menu
        }
        
        var isFirst = true
        var isFirstFilled = false
        for item in items {
            defer {
                isFirst = false
            }
            if self.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings) {
                continue
            }
            
            var isFilled = false
            let s = self.replacePlaceholders(in: item.template, settings: settings, isFilled: &isFilled)
            if s.isEmpty || (settings.isEmptyItemsSkipped && !isFilled) {
                continue
            }
            if isFirst {
                isFirstFilled = true
            }
            let mnu = self.createMenuItem(title: s, image: item.image, settings: settings)
            destination_sub_menu.addItem(mnu)
        }
        
        self.formatMainTitleMenu(mainMenu: menu, destination_sub_menu: destination_sub_menu, isFirstFilled: isFirstFilled, settings: settings)
        
        return menu
    }
    
    internal func processSpecialMenuItem(_ item: Settings.MenuItem, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template == "-" {
            destination_sub_menu.addItem(NSMenuItem.separator())
            return true
        } else {
            return false
        }
    }
    
    internal func formatMainTitleMenu(mainMenu menu: NSMenu, destination_sub_menu: NSMenu, isFirstFilled: Bool, settings: Settings) {
        if settings.isInfoOnSubMenu && settings.isInfoOnMainItem {
            if settings.useFirstItemAsMain && isFirstFilled {
                if let item = destination_sub_menu.items.first, !item.isSeparatorItem {
                    menu.items.first!.title = item.title
                    destination_sub_menu.items.remove(at: 0)
                }
            } else {
                let mainTitle = self.getStandardTitle(forSettings: settings)
                if !mainTitle.isEmpty {
                    menu.items.first!.title = mainTitle
                }
            }
        }
    }
    
    @objc internal func fakeMenuAction(_ sender: Any) {
        print(sender)
    }
    
    func formatND(useEmptyData: Bool) -> String {
        return useEmptyData ? NSLocalizedString("N/D", tableName: "LocalizableExt", comment: "") : ""
    }
    func formatERR(useEmptyData: Bool) -> String {
        return useEmptyData ? NSLocalizedString("ERR", tableName: "LocalizableExt", comment: "") : ""
    }
}

// MARK: -
protocol FileInfo: BaseInfo {
    static func getFileSize(_ file: URL) -> Int64?
    
    var file: URL { get }
    var fileSize: Int64 { get }
    func processFilePlaceholder(_ placeholder: String, settings: Settings, values: [String: Any]?, isFilled: inout Bool) -> String
    
    func encodeFileInfo(_ encoder: NSCoder)
    static func decodeFileInfo(_ coder: NSCoder) -> (URL, Int64?)?
}

extension FileInfo {
    static func getFileSize(_ file: URL) -> Int64? {
        if let attr = try? FileManager.default.attributesOfItem(atPath: file.path), let fileSize = attr[FileAttributeKey.size] as? Int64 {
            return fileSize
        } else {
            return nil
        }
    }
    
    static func decodeFileInfo(_ coder: NSCoder) -> (URL, Int64?)? {
        guard let u = coder.decodeObject(forKey: "file") as? String else {
            return nil
        }
        let file = URL(fileURLWithPath: u)
        let fileSize = coder.decodeInt64(forKey: "fileSize")
        return (file, fileSize)
    }
    
    func encodeFileInfo(_ coder: NSCoder) {
        coder.encode(self.file.path, forKey: "file")
        coder.encode(self.fileSize, forKey: "fileSize")
    }
    
    func processFilePlaceholder(_ placeholder: String, settings: Settings, values: [String: Any]?, isFilled: inout Bool) -> String {
        let useEmptyData = false
        
        switch placeholder {
        case "[[filesize]]":
            return format(value: fileSize, isFilled: &isFilled) { v, isFilled in
                guard let fileSize = v as? Int64 else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = fileSize > 0
                return fileSize >= 0 ? Self.byteCountFormatter.string(fromByteCount: fileSize) : self.formatND(useEmptyData: useEmptyData)
            }
        case "[[file-name]]":
            return format(value: values?["file"] ?? self.file, isFilled: &isFilled) { v, isFilled in
                guard let file = v as? URL else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return file.lastPathComponent
            }
        case "[[file-ext]]":
            return format(value: values?["file"] ?? self.file, isFilled: &isFilled) { v, isFilled in
                guard let file = v as? URL else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return file.pathExtension
            }
        default:
            isFilled = false
            return placeholder
        }
    }
}

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


// MARK: - DimensionalInfo
class DimensionalInfo: BaseInfo {
    enum Orientation {
        case landscape
        case portrait
    }
    
    static func getRatio(width: Int, height: Int, approximate: Bool) -> String? {
        var gcd = Int.gcd(width, height)
        guard gcd != 1 else {
            return nil
        }
            
        var circa = false
        if approximate, gcd < 8, let gcd1 = [Int.gcd(width+1, height), Int.gcd(width-1, height), Int.gcd(width, height+1), Int.gcd(width, height-1)].max(), gcd1 > gcd {
            gcd = gcd1 * Int.gcd(width/gcd1, height / gcd1)
            circa = true
        }
        let w = width / gcd
        let h = height / gcd
        
        guard w <= 30 && h <= 30 else {
            return nil
        }
        
        return "\(circa ? "~ " : "")\(w) : \(h)"
    }
    
    static func getResolutioName(width: Int, height: Int)->String? {
        let resolutions = [
            // Narrowscreen 4:3 computer display resolutions
            "MCGA": [320, 200],
            "QVGA" : [320, 240],
            "VGA" : [640, 480],
            "Super VGA" : [800, 600],
            "XGA" : [1024, 768],
            "SXGA" : [1280, 1024],
            "UXGA" : [1600, 1200],
            
            // Analog
            "CRT monitors": [320, 200],
            "Video CD": [352, 240],
            "VHS": [333, 480],
            "Betamax": [350, 480],
            "Super Betamax": [420, 480],
            "Betacam SP": [460, 480],
            "Super VHS": [580, 480],
            "Enhanced Definition Betamax": [700, 480],
            
            // Digital
            "Digital8": [500, 480],
            "NTSC DV": [720, 480],
            "NTSC D1": [720, 486],
            "NTSC D1 Square pixel": [720, 543],
            "NTSC D1 Widescreen Square Pixel": [782, 486],
            
            "EDTV (Enhanced Definition Television)": [854, 480],
            "D-VHS, DVD, miniDV, Digital8, Digital Betacam (PAL/SECAM)": [720, 576],
            "PAL D1/DV": [720, 576],
            "PAL D1/DV Square pixel": [788, 576],
            "PAL D1/DV Widescreen Square pixel": [1050, 576],
            
            
            "HDV/HDTV 720": [1280, 720],
            "HDTV 1080": [1440, 1080],
            "DVCPRO HD 720": [960, 720],
            "DVCPRO HD 1080": [1440, 1080],
            
            "HDTV 1080 (FullHD)": [1920, 1080],
            
            // "HDV (miniDV), AVCHD, HD DVD, Blu-ray, HDCAM SR": [1920, 1080],
            "2K Flat (1.85:1)": [1998, 1080],
            "UHD 4K": [3840, 2160],
            "UHD 8K": [7680, 4320],
            "Cineon Half": [1828, 1332],
            "Cineon Full": [3656, 2664],
            "Film (2K)": [2048, 1556],
            "Film (4K)": [4096, 3112],
            "Digital Cinema (2K)": [2048, 1080],
            "Digital Cinema (4K)": [4096, 2160],
            "Digital Cinema (16K)": [15360, 8640],
            "Digital Cinema (64K)": [61440, 34560],
        ]
        return resolutions.first(where: { $1[0] == width && $1[1] == height })?.key
    }
    
    var unit = "px"
    
    let width: Int
    let height: Int
    
    var orientation: DimensionalInfo.Orientation {
        return width < height ? .portrait : .landscape
    }
    var isLandscape: Bool {
        return orientation == .landscape
    }
    var isPortrait: Bool {
        return orientation == .portrait
    }
    
    lazy var resolutionName: String? = {
        return Self.getResolutioName(width: max(width, height), height: min(width, height))
    }()
    
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.width = coder.decodeInteger(forKey: "width")
        self.height = coder.decodeInteger(forKey: "height")
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.width, forKey: "width")
        coder.encode(self.height, forKey: "height")
        super.encode(with: coder)
    }
    
    func getRatio(approximate: Bool) -> String? {
        return Self.getRatio(width: width, height: height, approximate: approximate)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String: Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[size]]":
            return format(value: [values?["width"] ?? width, values?["height"] ?? height], isFilled: &isFilled) { v, isFilled in
                guard let dim = v as? [Int], dim.count == 2, let w = Self.numberFormatter.string(from: NSNumber(integerLiteral: dim[0])), let h = Self.numberFormatter.string(from: NSNumber(integerLiteral: dim[1])) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return "\(w) × \(h) \(self.unit)"
            }
        case "[[width]]":
            return format(value: values?["width"] ?? width, isFilled: &isFilled) { v, isFilled in
                isFilled = true
                if let size = v as? Int, let w = Self.numberFormatter.string(from: NSNumber(integerLiteral: size)) {
                    return "\(w) \(self.unit)"
                } else if let size = v {
                    return "\(size)"
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        case "[[height]]":
            return format(value: values?["height"] ?? height, isFilled: &isFilled) { v, isFilled in
                isFilled = true
                if let size = v as? Int, let h = Self.numberFormatter.string(from: NSNumber(integerLiteral: size)) {
                    return "\(h) \(self.unit)"
                } else if let size = v {
                    return "\(size)"
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        case "[[ratio]]":
            return format(value: [values?["width"] ?? width, values?["height"] ?? height], isFilled: &isFilled) { v, isFilled in
                guard let dim = v as? [Int], dim.count == 2 else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let width = dim[0]
                let height = dim[1]
                guard let ratio = Self.getRatio(width: width, height: height, approximate: !settings.isRatioPrecise) else {
                    isFilled = false
                    return ""
                }
                isFilled = true
                return ratio
            }
        case "[[resolution]]":
            return format(value: [values?["width"] ?? width, values?["height"] ?? height], isFilled: &isFilled) { v, isFilled in
                guard let dim = v as? [Int], dim.count == 2 else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                let width = dim[0]
                let height = dim[1]
                return Self.getResolutioName(width: width, height: height) ?? ""
            }
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        }
    }
    
    override internal func getImage(for name: String) -> NSImage? {
        var image: String
        switch name {
        case "image":
            image = self.isPortrait ? "image_v" : "image"
        case "video":
            image = isPortrait ? "video_v" : "video"
        case "ratio":
            image = isPortrait ? "ratio_v" : "ratio"
        case "page":
            image = isPortrait ? "page_v" : "page"
        case "artbox":
            image = self.isPortrait ? "artbox_v" : "artbox"
        case "bleed":
            image = self.isPortrait ? "bleed_v" : "bleed"
        case "pdf":
            image = self.isPortrait ? "pdf_v" : "pdf"
        default:
            image = name
        }
        return super.getImage(for: image)
    }
}
