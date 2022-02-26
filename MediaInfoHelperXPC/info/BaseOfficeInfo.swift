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
    
    required init?(coder: NSCoder) {
        self.creator = coder.decodeObject(of: NSString.self, forKey: "creator") as String? ?? ""
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String? ?? ""
        self.subject = coder.decodeObject(of: NSString.self, forKey: "subject") as String? ?? ""
        self.description = coder.decodeObject(of: NSString.self, forKey: "description") as String? ?? ""
        
        let n = coder.decodeInteger(forKey: "keywords_count")
        var keywords: [String] = []
        for i in 0 ..< n {
            if let k = coder.decodeObject(of: NSString.self, forKey: "keyword_\(i)") as String? {
                keywords.append(k)
            }
        }
        self.keywords = keywords
        
        if let n = coder.decodeObject(of: NSNumber.self, forKey: "creationDate")?.doubleValue {
            self.creationDate = Date(timeIntervalSince1970: n)
        } else {
            self.creationDate = nil
        }
        if let n = coder.decodeObject(of: NSNumber.self, forKey: "modificationDate")?.doubleValue {
            self.modificationDate = Date(timeIntervalSince1970: n)
        } else {
            self.modificationDate = nil
        }
        
        self.modified = coder.decodeObject(of: NSString.self, forKey: "modified") as String? ?? ""
        
        self.application = coder.decodeObject(of: NSString.self, forKey: "application") as String? ?? ""
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.creator as NSString, forKey: "creator")
        coder.encode(self.title as NSString, forKey: "title")
        coder.encode(self.subject as NSString, forKey: "subject")
        coder.encode(self.description as NSString, forKey: "description")
        
        coder.encode(self.keywords.count, forKey: "keywords_count")
        for i in 0 ..< self.keywords.count {
            coder.encode(self.keywords[i] as NSString, forKey: "keyword_\(i)")
        }
        
        coder.encode((self.creationDate?.timeIntervalSince1970) as NSNumber?, forKey: "creationDate")
        coder.encode((self.modificationDate?.timeIntervalSince1970) as NSNumber?, forKey: "modificationDate")
        
        coder.encode(self.modified as NSString, forKey: "modified")
        
        coder.encode(self.application as NSString, forKey: "application")
        
        super.encode(with: coder)
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
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        
        switch placeholder {
        case "[[creator]]":
            isFilled = !self.creator.isEmpty
            return self.creator
        case "[[creation]]":
            var template = ""
            if !self.creator.isEmpty {
                template += String(format: NSLocalizedString("Created by %@", tableName: "LocalizableExt",comment: ""), "[[creator]]")
            }
            if self.creationDate != nil {
                if !self.creator.isEmpty {
                    template += " " + String(format: NSLocalizedString("on %@", tableName: "LocalizableExt",comment: ""), "[[creation-date]]")
                } else {
                    template += String(format: NSLocalizedString("Created on %@", tableName: "LocalizableExt",comment: ""), "[[creation-date]]")
                }
            }
            return self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        case "[[last-author]]":
            isFilled = !self.modified.isEmpty
            return self.modified
        case "[[last-modification]]":
            var template = ""
            if !self.modified.isEmpty {
                template += String(format: NSLocalizedString("Last saved by %@", tableName: "LocalizableExt", comment: ""), "[[last-author]]")
            }
            if self.modificationDate != nil {
                if !self.modified.isEmpty {
                    template += " " + String(format: NSLocalizedString("on %@", tableName: "LocalizableExt",comment: ""), "[[modification-date]]")
                } else {
                    template += String(format: NSLocalizedString("Last saved on %@", tableName: "LocalizableExt",comment: ""), "[[modification-date]]")
                }
            }
            return self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: itemIndex)
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
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.officeMenuItems, image: self.getImage(for: "office"), withSettings: settings)
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, atIndex itemIndex: Int, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template == "[[keywords]]" {
            let title: String
            let n = self.keywords.count
            if n == 0 {
                guard !settings.isEmptyItemsSkipped else {
                    return true
                }
                title = NSLocalizedString("No Keyword", tableName: "LocalizableExt", comment: "")
            } else if n == 1 {
                title = NSLocalizedString("1 Keyword", tableName: "LocalizableExt", comment: "")
            } else {
                title = String(format: NSLocalizedString("%d Keywords", tableName: "LocalizableExt", comment: ""), n)
            }
            let mnu = self.createMenuItem(title: title, image: "no-image", settings: settings, tag: itemIndex)
            let submenu = NSMenu(title: title)
            for k in keywords {
                let mnu = createMenuItem(title: k, image: "-", settings: settings, tag: itemIndex)
                submenu.addItem(mnu)
            }
            mnu.submenu = submenu
            
            destination_sub_menu.addItem(mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, atIndex: itemIndex, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}
