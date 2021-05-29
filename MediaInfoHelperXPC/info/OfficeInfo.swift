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
    
    required init?(coder: NSCoder) {
        self.charactersCount = coder.decodeInteger(forKey: "charactersCount")
        self.charactersWithSpacesCount = coder.decodeInteger(forKey: "charactersWithSpacesCount")
        self.wordsCount = coder.decodeInteger(forKey: "wordsCount")
        self.pagesCount = coder.decodeInteger(forKey: "pagesCount")
        
        self.width = coder.decodeDouble(forKey: "width")
        self.height = coder.decodeDouble(forKey: "height")
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.charactersCount, forKey: "charactersCount")
        coder.encode(self.charactersWithSpacesCount, forKey: "charactersWithSpacesCount")
        coder.encode(self.wordsCount, forKey: "wordsCount")
        coder.encode(self.pagesCount, forKey: "pagesCount")
        
        coder.encode(self.width, forKey: "width")
        coder.encode(self.height, forKey: "height")
        
        super.encode(with: coder)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "office" {
            return getImage(for: "doc")
        } else if name == "doc" && width > height {
            return Self.getImage(for: "doc_h")
        }
        
        return Self.getImage(for: name)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        let formatCount: (Any?, String, String, inout Bool) -> String = { v, single, plural, isFilled in
            guard let n = v as? Int else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            isFilled = true
            if n == 1 {
                return "1 " + NSLocalizedString(single, tableName: "LocalizableExt", comment: "")
            } else {
                if n == 0 && !useEmptyData {
                    return ""
                }
                return "\(n) " +  NSLocalizedString(plural, tableName: "LocalizableExt", comment: "")
            }
        }
        
        switch placeholder {
        case "[[pages]]":
            return formatCount(values?["pages"] ?? self.pagesCount, "page", "pages", &isFilled)
        case "[[characters]]":
            return formatCount(values?["characters"] ?? self.charactersCount, "character", "characters", &isFilled)
        case "[[characters-space]]":
            return formatCount(values?["characters-space"] ?? self.charactersWithSpacesCount, "character (spaces included)", "characters (spaces included)", &isFilled)
        case "[[words]]":
            return formatCount(values?["words"] ?? self.wordsCount, "word", "words", &isFilled)
    
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
                return self.processPlaceholder("[[size:"+placeholder.suffix(4), settings: settings, isFilled: &isFilled)
            }
        case "[[size:cm]]", "[[size:mm]]", "[[size:in]]":
            return format(value: [values?["width"] ?? width, values?["height"] ?? height], isFilled: &isFilled) { v, isFilled in
                guard let dim = v as? [Double], dim.count == 2, dim[0] > 0 && dim[1] > 0 else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let um = placeholder.suffix(4).prefix(2)
                guard let unit = PrintUnit(placeholder: String(um)) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                
                guard let w = Self.numberFormatter.string(from: NSNumber(floatLiteral: dim[0] * unit.scale)), let h = Self.numberFormatter.string(from: NSNumber(floatLiteral: dim[1] * unit.scale)) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return "\(w) × \(h) \(unit.label)"
            }
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[size:paper:cm]], [[title]], [[pages]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled)
        return isFilled ? title : ""
    }
}

// MARK: - Excel
class ExcelInfo: BaseOfficeInfo {
    let sheets: [String]
    
    init(file: URL, creator: String, creationDate: Date?, modified: String, modificationDate: Date?, title: String, subject: String, keywords: [String], description: String, application: String, sheets: [String]) {
        self.sheets = sheets
        
        super.init(file: file, creator: creator, creationDate: creationDate, modified: modified, modificationDate: modificationDate, title: title, subject: subject, keywords: keywords, description: description, application: application)
    }
    
    required init?(coder: NSCoder) {
        let n = coder.decodeInteger(forKey: "sheets_count")
        var sheets: [String] = []
        for i in 0 ..< n {
            sheets.append(coder.decodeObject(forKey: "sheet_\(i)") as! String)
        }
        self.sheets = sheets
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.sheets.count, forKey: "sheets_count")
        for i in 0 ..< self.sheets.count {
            coder.encode(self.sheets[i], forKey: "sheet_\(i)")
        }
        
        super.encode(with: coder)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "office" {
            return Self.getImage(for: "xls")
        }
        
        return Self.getImage(for: name)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        
        switch placeholder {
        case "[[pages]]":
            return format(value: values?["sheets"] ?? self.sheets, isFilled: &isFilled) { v, isFilled in
                guard let sheets = v as? [String] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let n = sheets.count
                isFilled = n > 0
                if n == 1 {
                    return "1 " + NSLocalizedString("sheet", tableName: "LocalizableExt", comment: "")
                } else {
                    if n == 0 && !useEmptyData {
                        return ""
                    }
                    return "\(n) " +  NSLocalizedString("sheets", tableName: "LocalizableExt", comment: "")
                }
            }
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[title]], [[pages]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled)
        return isFilled ? title : ""
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
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
            let mnu = self.createMenuItem(title: title, image: "no-image", settings: settings)
            let submenu = NSMenu(title: title)
            for sheet in self.sheets {
                submenu.addItem(createMenuItem(title: sheet, image: "-", settings: settings))
            }
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(submenu, for: mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}

// MARK: - Powerpoint
class PowerpointInfo: BaseOfficeInfo {
    let slidesCount: Int
    let presentationFormat: String
    
    init(file: URL, creator: String, creationDate: Date?, modified: String, modificationDate: Date?, title: String, subject: String, keywords: [String], description: String, application: String, slidesCount: Int, presentationFormat: String) {
        self.slidesCount = slidesCount
        self.presentationFormat = presentationFormat
        
        super.init(file: file, creator: creator, creationDate: creationDate, modified: modified, modificationDate: modificationDate, title: title, subject: subject, keywords: keywords, description: description, application: application)
    }
    
    required init?(coder: NSCoder) {
        self.slidesCount = coder.decodeInteger(forKey: "slides_count")
        self.presentationFormat = coder.decodeObject(forKey: "presentationFormat") as? String ?? ""
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.slidesCount, forKey: "slides_count")
        coder.encode(self.presentationFormat, forKey: "presentationFormat")
        
        super.encode(with: coder)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "office" {
            return Self.getImage(for: "ppt")
        }
        
        return Self.getImage(for: name)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        
        switch placeholder {
        case "[[pages]]":
            return format(value: values?["slides"] ?? self.slidesCount, isFilled: &isFilled) { v, isFilled in
                guard let n = v as? Int else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = n > 0
                if n == 1 {
                    return "1 " + NSLocalizedString("slide", tableName: "LocalizableExt", comment: "")
                } else {
                    if n == 0 && !useEmptyData {
                        return ""
                    }
                    return "\(n) " +  NSLocalizedString("slides", tableName: "LocalizableExt", comment: "")
                }
            }
        case "[[presentation-format]]":
            return format(value: values?["presentation-format"] ?? self.presentationFormat, isFilled: &isFilled)
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[title]], [[pages]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled)
        return isFilled ? title : ""
    }
}
