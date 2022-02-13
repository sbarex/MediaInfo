//
//  PDFInfoItem.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

extension CGRect {
    func encode(_ coder: NSCoder, withKey key: String) {
        let c = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
        c.encode(Double(self.origin.x), forKey: "x")
        c.encode(Double(self.origin.y), forKey: "y")
        c.encode(Double(self.width), forKey: "w")
        c.encode(Double(self.height), forKey: "h")
        coder.encode(c.encodedData, forKey: key)
    }
    
    init?(_ coder: NSCoder, withKey key: String) {
        if let data = coder.decodeObject(of: NSData.self, forKey: key) as Data?, let d = try? NSKeyedUnarchiver(forReadingFrom: data) {
            defer {
                d.finishDecoding()
            }
            guard d.containsValue(forKey: "x") && d.containsValue(forKey: "y") && d.containsValue(forKey: "q") && d.containsValue(forKey: "h") else {
                return nil
            }
            let x = d.decodeDouble(forKey: "x")
            let y = d.decodeDouble(forKey: "y")
            let w = d.decodeDouble(forKey: "w")
            let h = d.decodeDouble(forKey: "h")
            
            self.init(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
        } else {
            return nil
        }
    }
}

class PDFInfo: DimensionalInfo, FileInfo, PaperInfo {
    enum CodingKeys: String, CodingKey {
        case version
        case author
        case subject
        case title
        case producer
        case creationDate
        case creator
        case modificationDate
        case keywords
        case isLocked
        case isEncrypted
        case pagesCount
        case allowsCopying
        case allowsPrinting
        case cropBox
        case artBox
        case bleedBox
        case mediaBox
        case trimBox
    }
    
    enum PrintUnit: Int, CaseIterable {
        case pt = 1
        case cm
        case mm
        case inch
        case paper
        case paper_pt
        case paper_cm
        case paper_mm
        case paper_inch
        
        var label: String {
            switch self {
            case .pt: return "pt"
            case .cm: return "cm"
            case .mm: return "mm"
            case .inch: return "inch"
            case .paper: return "paper"
            case .paper_pt: return "pt"
            case .paper_cm: return "cm"
            case .paper_mm: return "mm"
            case .paper_inch: return "inch"
            }
        }
        
        var displayString: String {
            // (pt/72)*2.54 = cm
            
            switch self {
            case .pt:
                return "pt"
            case .paper_pt:
                return "A4 / pt"
            case .cm:
                return "cm"
            case .paper_cm:
                return "A4 / cm"
            case .mm:
                return "mm"
            case .paper_mm:
                return "A4 / mm"
            case .inch:
                return "inch"
            case .paper_inch:
                return "A4 / inch"
            case .paper:
                return "A4"
            }
            
            /*
            var w = 210.0
            var h = 297.0
            var prefix = ""
            switch self {
            case .pt, .paper_pt:
                w = round((w / 25.4) * 72)
                h = round((h / 25.4) * 72)
                if self == .paper_pt {
                    prefix = "A4 / "
                }
            case .cm, .paper_cm:
                w /= 10
                h /= 10
                if self == .paper_cm {
                    prefix = "A4 / "
                }
            case .mm, .paper_mm:
                if self == .paper_mm {
                    prefix = "A4 / "
                }
            case .inch, .paper_inch:
                w /= 25.4
                h /= 25.4
                if self == .paper_inch {
                    prefix = "A4 / "
                }
            case .paper:
                return "A4"

            }
            return prefix + DimensionalInfo.numberFormatter.string(from: NSNumber(floatLiteral: w))! + " × " + DimensionalInfo.numberFormatter.string(from: NSNumber(floatLiteral: h))! + " " + NSLocalizedString(self.label, tableName: "LocalizableExt", comment: "")
             */
        }
        
        var placeholder: String {
            switch self {
            case .pt: return "pt"
            case .cm: return "cm"
            case .mm: return "mm"
            case .inch: return "in"
            case .paper: return "paper"
            case .paper_pt: return "paper:pt"
            case .paper_cm: return "paper:cm"
            case .paper_mm: return "paper:mm"
            case .paper_inch: return "paper:in"
            }
        }
        
        var scale: Double {
            switch self {
            case .pt: return 1
            case .cm: return 72/2.54
            case .mm: return 72/25.4
            case .inch: return 72
            case .paper: return 1
            case .paper_pt: return 1
            case .paper_cm: return 72/2.54
            case .paper_mm: return 72/25.4
            case .paper_inch: return 72
            }
        }
        
        var isPaper: Bool {
            switch self {
            case .pt, .cm, .mm, .inch: return false
            case .paper, .paper_pt, .paper_cm, .paper_mm, .paper_inch: return true
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "pt": self = .pt
            case "cm": self = .cm
            case "mm": self = .mm
            case "in": self = .inch
            case "paper": self = .paper
            case "paper:pt": self = .paper_pt
            case "paper:cm": self = .paper_cm
            case "paper:mm": self = .paper_mm
            case "paper:in": self = .paper_inch
            default: return nil
            }
        }
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // formatter.setLocalizedDateFormatFromTemplate("dd MMMM YYYY HH:mm")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    internal static func formatBox(_ rect: CGRect?, unit: PrintUnit) -> String? {
        guard let v = rect, !v.isEmpty else {
            return nil
        }
        
        var width = Double(v.width)
        var height = Double(v.height)
        
        if unit.isPaper {
            let paper = Self.getPaperSize(width: width / PrintUnit.mm.scale, height: height / PrintUnit.mm.scale)
            if unit == .paper || paper != nil {
                return paper
            }
        }
        
        width /= unit.scale
        height /= unit.scale
        let w = Self.numberFormatter.string(from: NSNumber(floatLiteral: width))!
        let h = Self.numberFormatter.string(from: NSNumber(floatLiteral: height))!
            
        return "\(w) × \(h) "+NSLocalizedString(unit.label, tableName: "LocalizableExt", comment: "")
    }
    
    internal static func formatBox(_ rect: CGRect?, placeholder: String) -> String? {
        guard let u = placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).split(separator: ":", maxSplits: 1).last, let unit = PrintUnit(placeholder: String(u)) else {
            return nil
        }
        return formatBox(rect, unit: unit)
    }
    
    let file: URL
    let fileSize: Int64
    let version: String
    let author: String?
    let subject: String?
    let title: String?
    let producer: String?
    let creationDate: Date?
    let creator: String?
    let modificationDate: Date?
    let keywords: [String]
    let isLocked: Bool
    let isEncrypted: Bool
    let pagesCount: Int
    let allowsCopying: Bool
    let allowsPrinting: Bool
    let cropBox: CGRect
    let artBox: CGRect
    let bleedBox: CGRect
    let mediaBox: CGRect
    let trimBox: CGRect
    
    /*
    let allowsCommenting: Bool
    let allowsContentAccessibility: Bool
    let allowsDocumentAssembly: Bool
    let allowsDocumentChanges: Bool
    let allowsFormFieldEntry: Bool
    */
    static func getPDFString(info: CGPDFDictionaryRef?, key: String) -> String? {
        guard let info = info, let k = key.cString(using: .utf8) else {
            return nil
        }
        
        var string: CGPDFStringRef?
        CGPDFDictionaryGetString(info, k, &string)
        if let s = string, let t = CGPDFStringCopyTextString(s) {
            return (t as String).trimmingCharacters(in: .whitespaces)
        } else {
            return nil
        }
    }
    
    static func getPDFDate(info: CGPDFDictionaryRef?, key: String) -> Date? {
        guard let info = info, let k = key.cString(using: .utf8) else {
            return nil
        }
        var string: CGPDFStringRef?
        CGPDFDictionaryGetString(info, k, &string)
        if let s = string, let d = CGPDFStringCopyDate(s) {
            return d as Date
        } else {
            return nil
        }
    }
    
    init(file: URL, pdf: CGPDFDocument) {
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        
        var majorVersion: Int32 = 0
        var minorVersion: Int32 = 0
        pdf.getVersion(majorVersion: &majorVersion, minorVersion: &minorVersion)
        self.version = "\(majorVersion).\(minorVersion)"
        
        self.author = Self.getPDFString(info: pdf.info, key: "Author")
        self.subject = Self.getPDFString(info: pdf.info, key: "Subject")
        self.title = Self.getPDFString(info: pdf.info, key: "Title")
        self.producer = Self.getPDFString(info: pdf.info, key: "Producer")
        self.creator = Self.getPDFString(info: pdf.info, key: "Creator")
        self.creationDate = Self.getPDFDate(info: pdf.info, key: "CreationDate")
        self.modificationDate = Self.getPDFDate(info: pdf.info, key: "ModDate")
        
        self.keywords = [] // pdf.documentAttributes?[PDFDocumentAttribute.keywordsAttribute] as? [String] : []
        
        self.isLocked = !pdf.isUnlocked
        self.isEncrypted = pdf.isEncrypted
        self.pagesCount = pdf.numberOfPages
        
        self.allowsCopying = pdf.allowsCopying
        self.allowsPrinting = pdf.allowsPrinting
        /*
        self.allowsCommenting = pdf.allowsCommenting
        self.allowsContentAccessibility = pdf.allowsContentAccessibility
        self.allowsDocumentAssembly = pdf.allowsDocumentAssembly
        self.allowsDocumentChanges = pdf.allowsDocumentChanges
        self.allowsFormFieldEntry = pdf.allowsFormFieldEntry
    */
        
        var page: CGPDFPage?
        if let p = pdf.page(at: 0) {
            page = p
        } else if let p = pdf.page(at: 1) {
            page = p
        } else {
            page = nil
        }
        if let page = page {
            let rotation = Int(page.rotationAngle)
            let processBox: (CGRect, Int)->CGRect = { r, rotation in
                if abs(rotation) == 90 || abs(rotation) == 270 {
                    return CGRect(x: r.minY, y: r.minX, width: r.height, height: r.width)
                } else {
                    return r
                }
            }
            
            self.cropBox  = processBox(page.getBoxRect(.cropBox), rotation)
            self.artBox   = processBox(page.getBoxRect(.artBox), rotation)
            self.bleedBox = processBox(page.getBoxRect(.bleedBox), rotation)
            self.mediaBox = processBox(page.getBoxRect(.mediaBox), rotation)
            self.trimBox  = processBox(page.getBoxRect(.trimBox), rotation)
            
        } else {
            self.cropBox  = .zero
            self.artBox   = .zero
            self.bleedBox = .zero
            self.mediaBox = .zero
            self.trimBox  = .zero
        }
        let bounds = self.mediaBox
        
        super.init(width: Int(bounds.width), height: Int(bounds.height))
        self.unit = "pt"
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        
        self.version = coder.decodeObject(of: NSString.self, forKey: "version") as String? ?? ""
        self.author = coder.decodeObject(of: NSString.self, forKey: "author") as String?
        self.subject = coder.decodeObject(of: NSString.self, forKey: "subject") as String?
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        self.producer = coder.decodeObject(of: NSString.self, forKey: "producer") as String?
        if let n = (coder.decodeObject(of: NSNumber.self, forKey: "creationDate")?.doubleValue) {
            self.creationDate = Date(timeIntervalSince1970: n)
        } else {
            self.creationDate = nil
        }
        self.creator = coder.decodeObject(of: NSString.self, forKey: "creator") as String?
        if let n = coder.decodeObject(of: NSNumber.self, forKey: "modificationDate")?.doubleValue {
            self.modificationDate = Date(timeIntervalSince1970: n)
        } else {
            self.modificationDate = nil
        }
        self.isLocked = coder.decodeBool(forKey: "isLocked")
        self.isEncrypted = coder.decodeBool(forKey: "isEncrypted")
        self.pagesCount = coder.decodeInteger(forKey: "pagesCount")
        self.allowsCopying = coder.decodeBool(forKey: "allowsCopying")
        self.allowsPrinting = coder.decodeBool(forKey: "allowsPrinting")
        self.cropBox = CGRect(coder, withKey: "cropBox") ?? .zero
        self.artBox = CGRect(coder, withKey: "artBox") ?? .zero
        self.bleedBox = CGRect(coder, withKey: "bleedBox") ?? .zero
        self.mediaBox = CGRect(coder, withKey: "mediaBox") ?? .zero
        self.trimBox = CGRect(coder, withKey: "trimBox") ?? .zero
        
        let n = coder.decodeInteger(forKey: "keywords_count")
        var keywords: [String] = []
        for i in 0 ..< n {
            if let k = coder.decodeObject(of: NSString.self, forKey: "keyword_\(i)") as String? {
                keywords.append(k)
            }
        }
        self.keywords = keywords
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        
        coder.encode(self.version as String, forKey: "version")
        coder.encode(self.author as String?, forKey: "author")
        coder.encode(self.subject as String?, forKey: "subject")
        coder.encode(self.title as String?, forKey: "title")
        coder.encode(self.producer as String?, forKey: "producer")
        coder.encode((self.creationDate?.timeIntervalSince1970) as NSNumber?, forKey: "creationDate")
        coder.encode(self.creator as String?, forKey: "creator")
        coder.encode((self.modificationDate?.timeIntervalSince1970) as NSNumber?, forKey: "modificationDate")
        coder.encode(self.isLocked, forKey: "isLocked")
        coder.encode(self.isEncrypted, forKey: "isEncrypted")
        coder.encode(self.pagesCount, forKey: "pagesCount")
        coder.encode(self.allowsCopying, forKey: "allowsCopying")
        coder.encode(self.allowsPrinting, forKey: "allowsPrinting")
        
        self.cropBox.encode(coder, withKey: "cropBox")
        self.artBox.encode(coder, withKey: "artBox")
        self.bleedBox.encode(coder, withKey: "bleedBox")
        self.mediaBox.encode(coder, withKey: "mediaBox")
        self.trimBox.encode(coder, withKey: "trimBox")
        
        coder.encode(self.keywords.count, forKey: "keywords_count")
        for (i, k) in keywords.enumerated() {
            coder.encode(k as String, forKey: "keyword_\(i)")
        }
        
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeFileInfo(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.author, forKey: .author)
        try container.encode(self.subject, forKey: .subject)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.producer, forKey: .producer)
        try container.encode(self.creator, forKey: .creator)
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.modificationDate?.timeIntervalSince1970, forKey: .modificationDate)
            try container.encode(self.creationDate?.timeIntervalSince1970, forKey: .creationDate)
        } else {
            try container.encode(self.modificationDate, forKey: .modificationDate)
            try container.encode(self.creationDate, forKey: .creationDate)
        }
        try container.encode(self.isLocked, forKey: .isLocked)
        try container.encode(self.isEncrypted, forKey: .isEncrypted)
        try container.encode(self.pagesCount, forKey: .pagesCount)
        try container.encode(self.allowsCopying, forKey: .allowsCopying)
        try container.encode(self.allowsPrinting, forKey: .allowsPrinting)
        try container.encode(self.cropBox, forKey: .cropBox)
        try container.encode(self.artBox, forKey: .artBox)
        try container.encode(self.bleedBox, forKey: .bleedBox)
        try container.encode(self.trimBox, forKey: .trimBox)
        try container.encode(self.keywords, forKey: .keywords)
    }
    
    func bounds(for box: CGPDFBox) -> CGRect {
        switch box {
        case .mediaBox:
            return self.mediaBox
        case .cropBox:
            return self.cropBox == .zero ? self.mediaBox : self.cropBox
        case .artBox:
            return self.artBox != .zero ? self.artBox : bounds(for: .cropBox)
        case .bleedBox:
            return self.bleedBox != .zero ? self.bleedBox : bounds(for: .cropBox)
        case .trimBox:
            return self.trimBox != .zero ? self.trimBox : bounds(for: .cropBox)
        default:
            return .zero
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[pages]]":
            return format(value: values?["pages"] ?? self.pagesCount, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Int else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                if v == 1 {
                    return "1 " + NSLocalizedString("page", tableName: "LocalizableExt", comment: "")
                } else {
                    if v == 0 && !useEmptyData {
                        return ""
                    }
                    return "\(v) " +  NSLocalizedString("pages", tableName: "LocalizableExt", comment: "")
                }
            }
        case "[[locked]]":
            return format(value: values?["locked"] ?? self.isLocked, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Bool else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v
                return v ? "🔒" : ""
            }
        case "[[encrypted]]":
            return format(value: values?["encrypted"] ?? self.isEncrypted, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Bool else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v
                return v ? "🔑" : ""
            }
        case "[[version]]":
            return format(value: values?["version"] ?? self.version, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !v.isEmpty
                return NSLocalizedString("version", tableName: "LocalizableExt", comment: "") + " \(v)"
            }
            
        case "[[author]]":
            return format(value: values?["author"] ?? self.author, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !v.isEmpty
                return v
            }
        case "[[subject]]":
            return format(value: values?["subject"] ?? self.subject, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !v.isEmpty
                return v
            }
        case "[[title]]":
            return format(value: values?["title"] ?? self.title, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !v.isEmpty
                return v
            }
            
        case "[[producer]]":
            return format(value: values?["producer"] ?? self.producer, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !v.isEmpty
                return v
            }
        case "[[creator]]":
            return format(value: values?["creator"] ?? self.creator, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !v.isEmpty
                return v
            }
        case "[[creation-date]]":
            return format(value: values?["creation-date"] ?? self.creationDate, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Date else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
                isFilled = true
                return Self.dateFormatter.string(from: v)
            }
        case "[[modification-date]]":
            return format(value: values?["modification-date"] ?? self.modificationDate, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Date else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
                isFilled = true
                return Self.dateFormatter.string(from: v)
            }
            
        case "[[keywords]]":
            return format(value: values?["keywords"] ?? self.keywords, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? [String] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v.isEmpty
                return v.joined(separator: " ")
            }
        case "[[mediabox]]":
            return self.processPlaceholder("[[mediabox:pt]]", settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        case "[[bleedbox]]":
            return self.processPlaceholder("[[bleedbox:pt]]", settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        case "[[cropbox]]":
            return self.processPlaceholder("[[cropbox:pt]]", settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        case "[[artbox]]":
            return self.processPlaceholder("[[artbox:pt]]", settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        case "[[security]]":
            var s: [String] = []
            if isLocked {
                s.append("🔒")
            }
            if self.isEncrypted {
                s.append("🔑")
            }
            if !self.allowsCopying {
                s.append(NSLocalizedString("no copy", tableName: "LocalizableExt", comment: ""))
            }
            if !self.allowsPrinting {
                s.append(NSLocalizedString("no print", tableName: "LocalizableExt", comment: ""))
            }
            isFilled = !s.isEmpty
            return s.joined(separator: " ")
        case "[[allows-copy]]":
            return NSLocalizedString(self.allowsCopying ? "Yes" : "No", comment: "")
        case "[[allows-print]]":
            return NSLocalizedString(self.allowsPrinting ? "Yes" : "No", comment: "")
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]":
            return self.processFilePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        default:
            if placeholder.hasPrefix("[[mediabox:") {
                return format(value: values?["mediabox"] ?? self.bounds(for:.mediaBox), isFilled: &isFilled) { v, isFilled in
                    isFilled = true
                    return Self.formatBox(v as? CGRect, placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
                }
            } else if placeholder.hasPrefix("[[bleedbox:") {
                isFilled = !self.bleedBox.isEmpty || !(values?["bleedbox"] as? CGRect ?? .zero).isEmpty
                return format(value: values?["bleedbox"] ?? self.bounds(for:.bleedBox), isFilled: &isFilled) { v, isFilled in
                    return Self.formatBox(v as? CGRect, placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
                }
            } else if placeholder.hasPrefix("[[cropbox:") {
                isFilled = !self.cropBox.isEmpty || !(values?["cropbox"] as? CGRect ?? .zero).isEmpty
                return format(value: values?["cropbox"] ?? self.bounds(for:.cropBox), isFilled: &isFilled) { v, isFilled in
                    return Self.formatBox(v as? CGRect, placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
                }
            } else if placeholder.hasPrefix("[[artbox:") {
                isFilled = !self.artBox.isEmpty || !(values?["artbox"] as? CGRect ?? .zero).isEmpty
                return format(value: values?["artbox"] ?? self.bounds(for:.artBox), isFilled: &isFilled) { v, isFilled in
                    return Self.formatBox(v as? CGRect, placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
                }
            } else {
                return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
            }
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[mediabox:cm]], [[pages]], [[security]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.pdfMenuItems, image: self.getImage(for: "pdf"), withSettings: settings)
    }
}
