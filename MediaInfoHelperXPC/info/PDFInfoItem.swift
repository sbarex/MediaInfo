//
//  PDFInfoItem.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class PDFInfo: FileInfo, DimensionalInfo, PaperInfo {
    enum CodingKeys: String, CodingKey {
        case version
        case author
        case subject
        case title
        case producer
        case creationDate
        case creationDateTimestamp
        case creator
        case modificationDate
        case modificationDateTimestamp
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
    
    let version: String
    let width: Int
    let height: Int
    let unit: String
    
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
        
        self.width = Int(bounds.width)
        self.height = Int(bounds.height)
        self.unit = "pt"
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let dim = try Self.decodeDimension(from: decoder)
        self.width = dim.width
        self.height = dim.height
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(String.self, forKey: .version)
        self.author = try container.decode(String?.self, forKey: .author)
        self.subject = try container.decode(String?.self, forKey: .subject)
        self.title = try container.decode(String?.self, forKey: .title)
        self.producer = try container.decode(String?.self, forKey: .producer)
        self.creator = try container.decode(String?.self, forKey: .creator)
        
        self.modificationDate = try container.decode(Date?.self, forKey: .modificationDate)
        self.creationDate = try container.decode(Date?.self, forKey: .creationDate)
        self.isLocked = try container.decode(Bool.self, forKey: .isLocked)
        self.isEncrypted = try container.decode(Bool.self, forKey: .isEncrypted)
        self.pagesCount = try container.decode(Int.self, forKey: .pagesCount)
        self.allowsCopying = try container.decode(Bool.self, forKey: .allowsCopying)
        self.allowsPrinting = try container.decode(Bool.self, forKey: .allowsPrinting)
        self.mediaBox = try container.decode(CGRect.self, forKey: .mediaBox)
        self.cropBox = try container.decode(CGRect.self, forKey: .cropBox)
        self.artBox = try container.decode(CGRect.self, forKey: .artBox)
        self.bleedBox = try container.decode(CGRect.self, forKey: .bleedBox)
        self.trimBox = try container.decode(CGRect.self, forKey: .trimBox)
        self.keywords = try container.decode([String].self, forKey: .keywords)
        
        self.unit = "pt"
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeDimension(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.author, forKey: .author)
        try container.encode(self.subject, forKey: .subject)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.producer, forKey: .producer)
        try container.encode(self.creator, forKey: .creator)
        try container.encode(self.modificationDate, forKey: .modificationDate)
        try container.encode(self.creationDate, forKey: .creationDate)
        try container.encode(self.isLocked, forKey: .isLocked)
        try container.encode(self.isEncrypted, forKey: .isEncrypted)
        try container.encode(self.pagesCount, forKey: .pagesCount)
        try container.encode(self.allowsCopying, forKey: .allowsCopying)
        try container.encode(self.allowsPrinting, forKey: .allowsPrinting)
        try container.encode(self.mediaBox, forKey: .mediaBox)
        try container.encode(self.cropBox, forKey: .cropBox)
        try container.encode(self.artBox, forKey: .artBox)
        try container.encode(self.bleedBox, forKey: .bleedBox)
        try container.encode(self.trimBox, forKey: .trimBox)
        try container.encode(self.keywords, forKey: .keywords)
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.modificationDate?.timeIntervalSince1970, forKey: .modificationDateTimestamp)
            try container.encode(self.creationDate?.timeIntervalSince1970, forKey: .creationDateTimestamp)
        }
        
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
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        switch placeholder {
        case "[[size]]", "[[width]]", "[[height]]", "[[ratio]]", "[[resolution]]":
            return self.processDimensionPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        case "[[pages]]":
            isFilled = true
            if pagesCount == 0 {
                return useEmptyData ? NSLocalizedString("No Page", tableName: "LocalizableExt", comment: "") : ""
            } else if self.pagesCount == 1 {
                return NSLocalizedString("1 Page", tableName: "LocalizableExt", comment: "")
            } else {
                return String(format: NSLocalizedString("%@ Pages", tableName: "LocalizableExt", comment: ""), BaseInfo.numberFormatter.string(from: NSNumber(integerLiteral: self.pagesCount)) ?? "\(self.pagesCount)")
            }
        case "[[locked]]":
            isFilled = self.isLocked
            return self.isLocked ? "🔒" : ""
        case "[[encrypted]]":
            isFilled = self.isEncrypted
            return self.isEncrypted ? "🔑" : ""
        case "[[version]]":
            isFilled = !self.version.isEmpty
            return String(format: NSLocalizedString("Version %@", tableName: "LocalizableExt", comment: ""), self.version)
        case "[[author]]":
            isFilled = !(self.author?.isEmpty ?? true)
            return self.author ?? self.formatND(useEmptyData: useEmptyData)
        case "[[subject]]":
            isFilled = !(self.subject?.isEmpty ?? true)
            return self.subject ?? self.formatND(useEmptyData: useEmptyData)
        case "[[title]]":
            isFilled = !(self.title?.isEmpty ?? true)
            return self.title ?? self.formatND(useEmptyData: useEmptyData)
        case "[[producer]]":
            isFilled = !(self.producer?.isEmpty ?? true)
            return self.producer ?? self.formatND(useEmptyData: useEmptyData)
        case "[[creator]]":
            isFilled = !(self.creator?.isEmpty ?? true)
            return self.creator ?? self.formatND(useEmptyData: useEmptyData)
        case "[[creation-date]]":
            guard let v = self.creationDate else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
            isFilled = true
            return Self.dateFormatter.string(from: v)
        case "[[modification-date]]":
            guard let v = self.modificationDate else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
            isFilled = true
            return Self.dateFormatter.string(from: v)
            
        case "[[keywords]]":
            isFilled = !self.keywords.isEmpty
            return self.keywords.joined(separator: " ")
        case "[[mediabox]]":
            return self.processPlaceholder("[[mediabox:pt]]", settings: settings, isFilled: &isFilled, forItem: itemIndex)
        case "[[bleedbox]]":
            return self.processPlaceholder("[[bleedbox:pt]]", settings: settings, isFilled: &isFilled, forItem: itemIndex)
        case "[[cropbox]]":
            return self.processPlaceholder("[[cropbox:pt]]", settings: settings, isFilled: &isFilled, forItem: itemIndex)
        case "[[artbox]]":
            return self.processPlaceholder("[[artbox:pt]]", settings: settings, isFilled: &isFilled, forItem: itemIndex)
        case "[[security]]":
            var s: [String] = []
            if isLocked {
                s.append("🔒")
            }
            if self.isEncrypted {
                s.append("🔑")
            }
            if !self.allowsCopying {
                s.append(NSLocalizedString("No copy", tableName: "LocalizableExt", comment: ""))
            }
            if !self.allowsPrinting {
                s.append(NSLocalizedString("No print", tableName: "LocalizableExt", comment: ""))
            }
            isFilled = !s.isEmpty
            return s.joined(separator: " ")
        case "[[allows-copy]]":
            return NSLocalizedString(self.allowsCopying ? "Yes" : "No", comment: "")
        case "[[allows-print]]":
            return NSLocalizedString(self.allowsPrinting ? "Yes" : "No", comment: "")
        default:
            if placeholder.hasPrefix("[[mediabox:") {
                let v = self.bounds(for: .mediaBox)
                isFilled = true
                return Self.formatBox(v, placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
            } else if placeholder.hasPrefix("[[bleedbox:") {
                isFilled = !self.bleedBox.isEmpty
                return Self.formatBox(self.bounds(for: .bleedBox), placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
            } else if placeholder.hasPrefix("[[cropbox:") {
                isFilled = !self.cropBox.isEmpty
                return Self.formatBox(self.bounds(for: .cropBox), placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
            } else if placeholder.hasPrefix("[[artbox:") {
                isFilled = !self.artBox.isEmpty
                return Self.formatBox(self.bounds(for: .artBox), placeholder: placeholder) ?? self.formatND(useEmptyData: useEmptyData)
            } else {
                return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
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
