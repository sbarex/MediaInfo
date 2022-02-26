//
//  OfficeInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa


// MARK: - Word
class WordInfo: BaseOfficeInfo, PaperInfo {
    enum CodingKeys: String, CodingKey {
        case charactersCount
        case charactersWithSpacesCount
        case wordsCount
        case pagesCount
        
        case unit
        case width
        case height
    }
    let charactersCount: Int
    let charactersWithSpacesCount: Int
    let wordsCount: Int
    let pagesCount: Int
    
    let unit: String = "inch"
    let width: Double
    let height: Double
    
    init(file: URL, charactersCount: Int, charactersWithSpacesCount: Int, wordsCount: Int, pagesCount: Int, creator: String, creationDate: Date?, modified: String, modificationDate: Date?, title: String, subject: String, keywords: [String], description: String, application: String, width: Double, height: Double) {
        self.charactersCount = charactersCount
        self.charactersWithSpacesCount = charactersWithSpacesCount
        self.wordsCount = wordsCount
        self.pagesCount = pagesCount
        
        self.width = width
        self.height = height
        
        super.init(file: file, creator: creator, creationDate: creationDate, modified: modified, modificationDate: modificationDate, title: title, subject: subject, keywords: keywords, description: description, application: application)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.charactersCount = try container.decode(Int.self, forKey: .charactersCount)
        self.charactersWithSpacesCount = try container.decode(Int.self, forKey: .charactersWithSpacesCount)
        self.wordsCount = try container.decode(Int.self, forKey: .wordsCount)
        self.pagesCount = try container.decode(Int.self, forKey: .pagesCount)
        self.width = try container.decode(Double.self, forKey: .width)
        self.height = try container.decode(Double.self, forKey: .height)
        
        try super.init(from: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.charactersCount, forKey: .charactersCount)
        try container.encode(self.charactersWithSpacesCount, forKey: .charactersWithSpacesCount)
        try container.encode(self.wordsCount, forKey: .wordsCount)
        try container.encode(self.pagesCount, forKey: .pagesCount)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "office" {
            return getImage(for: "doc")
        } else if name == "doc" && width > height {
            return Self.getImage(for: "doc_h")
        }
        
        return Self.getImage(for: name)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        
        switch placeholder {
        case "[[pages]]":
            return self.formatCount(self.pagesCount, noneLabel: "No Page", singleLabel: "1 Page", manyLabel: "%@ Pages", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[characters]]":
            return self.formatCount(self.charactersCount, noneLabel: "Character", singleLabel: "1 Character", manyLabel: "%@ Characters", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[characters-space]]":
            return self.formatCount(self.charactersWithSpacesCount, noneLabel: "No Character (spaces included)", singleLabel: "1 Character (spaces included)", manyLabel: "%@ Characters (spaces included)", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[words]]":
            return self.formatCount(self.wordsCount, noneLabel: "No Word", singleLabel: "1 Word", manyLabel: "%@ Words", isFilled: &isFilled, useEmptyData: useEmptyData)
    
        case "[[size:paper]]":
            if let s = Self.getPaperSize(width: width * 25.4, height: height * 25.4) {
                isFilled = true
                return s
            } else {
                isFilled = false
                return ""
            }
        case "[[size:paper:cm]]", "[[size:paper:mm]]", "[[size:paper:in]]":
            if let s = Self.getPaperSize(width: width * 25.4, height: height * 25.4) {
                isFilled = true
                return s
            } else {
                return self.processPlaceholder("[[size:"+placeholder.suffix(4), settings: settings, isFilled: &isFilled, forItem: itemIndex)
            }
        case "[[size:cm]]", "[[size:mm]]", "[[size:in]]":
            guard width > 0 && height > 0 else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            let um = placeholder.suffix(4).prefix(2)
            guard let unit = PrintUnit(placeholder: String(um)) else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            
            guard let w = Self.numberFormatter.string(from: NSNumber(floatLiteral: width * unit.scale)), let h = Self.numberFormatter.string(from: NSNumber(floatLiteral: height * unit.scale)) else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            isFilled = true
            return "\(w) × \(h) \(unit.label)"
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[size:paper:cm]], [[title]], [[pages]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
}

// MARK: - Excel
class ExcelInfo: BaseOfficeInfo {
    enum CodingKeys: String, CodingKey {
        case sheets
    }
    let sheets: [String]
    
    init(file: URL, creator: String, creationDate: Date?, modified: String, modificationDate: Date?, title: String, subject: String, keywords: [String], description: String, application: String, sheets: [String]) {
        self.sheets = sheets
        
        super.init(file: file, creator: creator, creationDate: creationDate, modified: modified, modificationDate: modificationDate, title: title, subject: subject, keywords: keywords, description: description, application: application)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sheets = try container.decode([String].self, forKey: .sheets)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.sheets, forKey: .sheets)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "office" {
            return Self.getImage(for: "xls")
        }
        
        return Self.getImage(for: name)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIdex: Int) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        
        switch placeholder {
        case "[[pages]]":
            return self.formatCount(sheets.count, noneLabel: "No Sheet", singleLabel: "1 Sheet", manyLabel: "%d Sheets", isFilled: &isFilled, useEmptyData: useEmptyData, formatAsString: false)
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIdex)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[title]], [[pages]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, atIndex itemIndex: Int, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template == "[[sheets]]" || item.template == "[[pages]]" && !self.sheets.isEmpty {
            guard !self.sheets.isEmpty else {
                return true
            }
            let title: String
            let n = self.sheets.count
            if n == 1 {
                title = NSLocalizedString("1 Sheet", tableName: "LocalizableExt", comment: "")
            } else {
                title = String(format: NSLocalizedString("%d Sheets", tableName: "LocalizableExt", comment: ""), n)
            }
            let mnu = self.createMenuItem(title: title, image: "no-image", settings: settings, tag: itemIndex)
            let submenu = NSMenu(title: title)
            for sheet in self.sheets {
                submenu.addItem(createMenuItem(title: sheet, image: "-", settings: settings, tag: itemIndex))
            }
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(submenu, for: mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, atIndex: itemIndex, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}

// MARK: - Powerpoint
class PowerpointInfo: BaseOfficeInfo {
    enum CodingKeys: String, CodingKey {
        case slidesCount
        case presentationFormat
    }
    
    let slidesCount: Int
    let presentationFormat: String
    
    init(file: URL, creator: String, creationDate: Date?, modified: String, modificationDate: Date?, title: String, subject: String, keywords: [String], description: String, application: String, slidesCount: Int, presentationFormat: String) {
        self.slidesCount = slidesCount
        self.presentationFormat = presentationFormat
        
        super.init(file: file, creator: creator, creationDate: creationDate, modified: modified, modificationDate: modificationDate, title: title, subject: subject, keywords: keywords, description: description, application: application)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.slidesCount = try container.decode(Int.self, forKey: .slidesCount)
        self.presentationFormat = try container.decode(String.self, forKey: .presentationFormat)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.slidesCount, forKey: .slidesCount)
        try container.encode(self.presentationFormat, forKey: .presentationFormat)
        try super.encode(to: encoder)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "office" {
            return Self.getImage(for: "ppt")
        }
        
        return Self.getImage(for: name)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        
        switch placeholder {
        case "[[pages]]":
            return self.formatCount(slidesCount, noneLabel: "No Slide", singleLabel: "1 Slide", manyLabel: "%d Slides", isFilled: &isFilled, useEmptyData: useEmptyData, formatAsString: false)
        case "[[presentation-format]]":
            isFilled = !self.presentationFormat.isEmpty
            return self.presentationFormat
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[title]], [[pages]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
}
