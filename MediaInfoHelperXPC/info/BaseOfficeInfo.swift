//
//  BaseOfficeInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class BaseOfficeInfo: FileInfo {
    enum CodingKeys: String, CodingKey {
        case creator
        case title
        case subject
        case keywords
        case description
        case creationDate
        case modificationDate
        case creationDateTimestamp
        case modificationDateTimestamp
        case modified
        case application
    }
    
    override class func updateSettings(_ settings: Settings, forItems items: [Settings.MenuItem]) {
        for item in items {
            if item.template.contains("[[size:") || item.template.contains("[[pages]]") || item.template.contains("[[sheets]]") {
                settings.officeSettings.deepScan = true
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
                    if code.hasPrefix("/* require-deep-scan */") {
                        settings.officeSettings.deepScan = true
                        return
                    }
                }
            }
        }
        settings.officeSettings.deepScan = false
    }
    
    // Dublin Core properties
    let creator: String
    let title: String
    let subject: String
    let keywords: [String]
    let description: String
    
    let creationDate: Date?
    let modificationDate: Date?
    
    // Core properties
    let modified: String
    
    let application: String
    
    override class var infoType: Settings.SupportedFile { return .office }
    override var standardMainItem: MenuItemInfo {
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "office", template: "")) // FIXME: template
    }
    
    init(file: URL, creator: String, creationDate: Date?, modified: String, modificationDate: Date?, title: String, subject: String, keywords: [String], description: String, application: String) {
        self.creator = creator
        self.title = title
        self.subject = subject
        self.keywords = keywords
        self.description = description
        
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        
        self.modified = modified
        
        self.application = application
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.creator = try container.decode(String.self, forKey: .creator)
        self.title = try container.decode(String.self, forKey: .title)
        self.subject = try container.decode(String.self, forKey: .subject)
        self.description = try container.decode(String.self, forKey: .description)
        self.keywords = try container.decode([String].self, forKey: .keywords)
        self.creationDate = try container.decode(Date?.self, forKey: .creationDate)
        self.modificationDate = try container.decode(Date?.self, forKey: .modificationDate)
        self.modified = try container.decode(String.self, forKey: .modified)
        self.application = try container.decode(String.self, forKey: .application)
        
        try super.init(from: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.creator, forKey: .creator)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.subject, forKey: .subject)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.keywords, forKey: .keywords)
        try container.encode(self.creationDate, forKey: .creationDate)
        try container.encode(self.modificationDate, forKey: .modificationDate)
        try container.encode(self.modified, forKey: .modified)
        try container.encode(self.application, forKey: .application)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.creationDate?.timeIntervalSince1970, forKey: .creationDateTimestamp)
            try container.encode(self.modificationDate?.timeIntervalSince1970, forKey: .modificationDateTimestamp)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        
        switch placeholder {
        case "[[creator]]":
            isFilled = !self.creator.isEmpty
            return self.creator
        case "[[creation]]":
            var template = ""
            if !self.creator.isEmpty {
                template += String(format: NSLocalizedString("created by %@", tableName: "LocalizableExt",comment: ""), "[[creator]]")
            }
            if self.creationDate != nil {
                if !self.creator.isEmpty {
                    template += ", [[creation-date]]"
                } else {
                    template += String(format: NSLocalizedString("created %@", tableName: "LocalizableExt", comment: ""), "[[creation-date]]")
                }
            }
            return self.replacePlaceholders(in: template, isFilled: &isFilled, forItem: item ?? MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "", template: template)))
        case "[[last-author]]":
            isFilled = !self.modified.isEmpty
            return self.modified
        case "[[last-modification]]":
            var template = ""
            if !self.modified.isEmpty {
                template += String(format: NSLocalizedString("last saved by %@", tableName: "LocalizableExt", comment: ""), "[[last-author]]")
            }
            if self.modificationDate != nil {
                if !self.modified.isEmpty {
                    template += ", [[modification-date]]"
                } else {
                    template += String(format: NSLocalizedString("last saved %@", tableName: "LocalizableExt",comment: ""), "[[modification-date]]")
                }
            }
            return self.replacePlaceholders(in: template, isFilled: &isFilled, forItem: item ?? MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "", template: template)))
        case "[[title]]":
            isFilled = !self.title.isEmpty
            return self.title
        case "[[subject]]":
            isFilled = !self.subject.isEmpty
            return self.subject
        case "[[description]]":
            isFilled = !self.description.isEmpty
            return self.description
        case "[[keywords]]":
            isFilled = !self.keywords.isEmpty
            return self.keywords.joined(separator: ", ")
    
        case "[[creation-date]]", "[[modification-date]]":
            let d = placeholder == "[[creation-date]]" ? self.creationDate : self.modificationDate
            guard let v = d else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            isFilled = true
            return PDFInfo.dateFormatter.string(from: v)
        case "[[application]]":
            isFilled = !self.application.isEmpty
            return self.application
        
        case "[[sheets]]",
             "[[size:paper]]",
             "[[size:paper:cm]]", "[[size:paper:mm]]", "[[size:paper:in]]",
             "[[size:cm]]", "[[size:mm]]", "[[size:in]]":
            isFilled = false
            return ""
        default:
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        if item.menuItem.template == "[[keywords]]" {
            let n = self.keywords.count
            guard n>0 || !(self.globalSettings?.isEmptyItemsSkipped ?? true) else {
                return true
            }
            let title = self.formatCount(n, noneLabel: "no Keyword", singleLabel: "1 Keyword", manyLabel: "%d Keywords", useEmptyData: !(self.globalSettings?.isEmptyItemsSkipped ?? true), formatAsString: false)
            let mnu = self.createMenuItem(title: title, image: "no-image", representedObject: item)
            let submenu = NSMenu(title: title)
            for (i, k) in keywords.enumerated() {
                var info = item
                info.userInfo["keyword_index"] = i
                let mnu = createMenuItem(title: k, image: "-", representedObject: info)
                submenu.addItem(mnu)
            }
            mnu.submenu = submenu
            
            destination_sub_menu.addItem(mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
        }
    }
}
