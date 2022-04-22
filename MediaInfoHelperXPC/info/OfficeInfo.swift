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
    
    override var standardMainItem: MenuItemInfo {
        let template = "[[size:paper:cm]], [[title]], [[pages]]"
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "doc", template: template))
    }
    
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
        } else if (name == "doc" || name == "docx" || name == "word") {
            return Self.getImage(for: width > height ? "doc_h" : "doc_v")
        } else if name == "doc_v" || name == "docx_v" || name == "word_v" {
            return Self.getImage(for: "doc_v")
        } else if name == "doc_h" || name == "docx_h" || name == "word_h" {
            return Self.getImage(for: "doc_h")
        } else {
            return Self.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        
        switch placeholder {
        case "[[pages]]":
            return self.formatCount(self.pagesCount, noneLabel: "no Page", singleLabel: "1 Page", manyLabel: "%@ Pages", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[characters]]":
            return self.formatCount(self.charactersCount, noneLabel: "no Character", singleLabel: "1 Character", manyLabel: "%@ Characters", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[characters-space]]":
            return self.formatCount(self.charactersWithSpacesCount, noneLabel: "mo Character (spaces included)", singleLabel: "1 Character (spaces included)", manyLabel: "%@ Characters (spaces included)", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[words]]":
            return self.formatCount(self.wordsCount, noneLabel: "no Word", singleLabel: "1 Word", manyLabel: "%@ Words", isFilled: &isFilled, useEmptyData: useEmptyData)
    
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
                return self.processPlaceholder("[[size:"+placeholder.suffix(4), isFilled: &isFilled, forItem: item)
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
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
}

// MARK: - Excel
class ExcelInfo: BaseOfficeInfo {
    enum CodingKeys: String, CodingKey {
        case sheets
    }
    
    let sheets: [String]
    
    override var standardMainItem: MenuItemInfo {
        let template = "[[title]], [[pages]]"
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "xls", template: template))
    }
    
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
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        
        switch placeholder {
        case "[[pages]]":
            return self.formatCount(sheets.count, noneLabel: "no Sheet", singleLabel: "1 Sheet", manyLabel: "%d Sheets", isFilled: &isFilled, useEmptyData: useEmptyData, formatAsString: false)
        default:
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        if item.menuItem.template == "[[sheets]]" || item.menuItem.template == "[[pages]]" && !self.sheets.isEmpty {
            guard !self.sheets.isEmpty else {
                return true
            }
            let n = self.sheets.count
            let title: String = self.formatCount(n, noneLabel: "no Sheet", singleLabel: "1 Sheet", manyLabel: "%d Sheets", useEmptyData: true, formatAsString: false)
            let mnu = self.createMenuItem(title: title, image: "no-image", representedObject: item)
            let submenu = NSMenu(title: title)
            for (i, sheet) in self.sheets.enumerated() {
                var info =  item
                info.userInfo["sheet_index"] = i
                submenu.addItem(createMenuItem(title: sheet, image: "-", representedObject: info))
            }
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(submenu, for: mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
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
    
    override var standardMainItem: MenuItemInfo {
        let template = "[[title]], [[pages]]"
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "ppt", template: template))
    }
    
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
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        
        switch placeholder {
        case "[[pages]]":
            return self.formatCount(slidesCount, noneLabel: "no Slide", singleLabel: "1 Slide", manyLabel: "%d Slides", isFilled: &isFilled, useEmptyData: useEmptyData, formatAsString: false)
        case "[[presentation-format]]":
            isFilled = !self.presentationFormat.isEmpty
            return self.presentationFormat
        default:
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
}
