//
//  BaseOfficeInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class BaseOfficeInfo: BaseInfo, FileInfo {
    let file: URL
    let fileSize: Int64
    
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
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        
        self.creator = creator
        self.title = title
        self.subject = subject
        self.keywords = keywords
        self.description = description
        
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        
        self.modified = modified
        
        self.application = application
        super.init()
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        
        self.creator = coder.decodeObject(forKey: "creator") as? String ?? ""
        self.title = coder.decodeObject(forKey: "title") as? String ?? ""
        self.subject = coder.decodeObject(forKey: "subject") as? String ?? ""
        self.description = coder.decodeObject(forKey: "description") as? String ?? ""
        
        let n = coder.decodeInteger(forKey: "keywords_count")
        var keywords: [String] = []
        for i in 0 ..< n {
            if let k = coder.decodeObject(forKey: "keyword_\(i)") as? String {
                keywords.append(k)
            }
        }
        self.keywords = keywords
        
        if let n = coder.decodeObject(forKey: "creationDate") as? TimeInterval {
            self.creationDate = Date(timeIntervalSince1970: n)
        } else {
            self.creationDate = nil
        }
        if let n = coder.decodeObject(forKey: "modificationDate") as? TimeInterval {
            self.modificationDate = Date(timeIntervalSince1970: n)
        } else {
            self.modificationDate = nil
        }
        
        self.modified = coder.decodeObject(forKey: "modified") as? String ?? ""
        
        self.application = coder.decodeObject(forKey: "application") as? String ?? ""
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        
        coder.encode(self.creator, forKey: "creator")
        coder.encode(self.title, forKey: "title")
        coder.encode(self.subject, forKey: "subject")
        coder.encode(self.description, forKey: "description")
        
        coder.encode(self.keywords.count, forKey: "keywords_count")
        for i in 0 ..< self.keywords.count {
            coder.encode(self.keywords[i], forKey: "keyword_\(i)")
        }
        
        coder.encode(self.creationDate?.timeIntervalSince1970, forKey: "creationDate")
        coder.encode(self.modificationDate?.timeIntervalSince1970, forKey: "modificationDate")
        
        coder.encode(self.modified, forKey: "modified")
        
        coder.encode(self.application, forKey: "application")
        
        super.encode(with: coder)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        
        switch placeholder {
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]":
            return self.processFilePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[creator]]":
            return format(value: values?["creator"] ?? self.creator, isFilled: &isFilled)
        case "[[creation]]":
            var template = ""
            if !self.creator.isEmpty {
                template += String(format: NSLocalizedString("created by %@", tableName: "LocalizableExt",comment: ""), "[[creator]]")
            }
            if self.creationDate != nil {
                if !self.creator.isEmpty {
                    template += " " + String(format: NSLocalizedString("on %@", tableName: "LocalizableExt",comment: ""), "[[creation-date]]")
                } else {
                    template += String(format: NSLocalizedString("created on %@", tableName: "LocalizableExt",comment: ""), "[[creation-date]]")
                }
            }
            return self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled)
        case "[[last-author]]":
            return format(value: values?["modified"] ?? self.modified, isFilled: &isFilled)
        case "[[last-modification]]":
            var template = ""
            if !self.modified.isEmpty {
                template += String(format: NSLocalizedString("last saved by %@", tableName: "LocalizableExt", comment: ""), "[[last-author]]")
            }
            if self.modificationDate != nil {
                if !self.modified.isEmpty {
                    template += " " + String(format: NSLocalizedString("on %@", tableName: "LocalizableExt",comment: ""), "[[modification-date]]")
                } else {
                    template += String(format: NSLocalizedString("last saved on %@", tableName: "LocalizableExt",comment: ""), "[[modification-date]]")
                }
            }
            return self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled)
        case "[[title]]":
            return format(value: values?["title"] ?? self.title, isFilled: &isFilled)
        case "[[subject]]":
            return format(value: values?["subject"] ?? self.subject, isFilled: &isFilled)
        case "[[description]]":
            return format(value: values?["description"] ?? self.description, isFilled: &isFilled)
        case "[[keywords]]":
            return format(value: values?["keywords"] ?? self.keywords, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? [String] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !v.isEmpty
                return v.joined(separator: ", ")
            }
    
        case "[[creation-date]]", "[[modification-date]]":
            let d: Any? = placeholder == "[[creation-date]]" ? (values?["creation-date"] ?? self.creationDate) : (values?["modification-date"] ?? self.modificationDate)
            return format(value: d, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Date? else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                if let v = v {
                    isFilled = true
                    return PDFInfo.dateFormatter.string(from: v)
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        case "[[application]]":
            return format(value: values?["application"] ?? self.application, isFilled: &isFilled)
        
        case "[[sheets]]",
             "[[size:paper]]",
             "[[size:paper:cm]]", "[[size:paper:mm]]", "[[size:paper:in]]",
             "[[size:cm]]", "[[size:mm]]", "[[size:in]]":
            isFilled = false
            return ""
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled)
        }
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.officeMenuItems, image: self.getImage(for: "office"), withSettings: settings)
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template == "[[keywords]]" {
            guard !self.keywords.isEmpty else {
                return true
            }
            
            let title: String
            let n = self.keywords.count
            if n == 1 {
                title = NSLocalizedString("1 Keyword", tableName: "LocalizableExt", comment: "")
            } else {
                title = String(format: NSLocalizedString("%d Keywords", tableName: "LocalizableExt", comment: ""), n)
            }
            let mnu = self.createMenuItem(title: title, image: "no-image", settings: settings)
            
            let submenu = NSMenu(title: title)
            for k in keywords {
                submenu.addItem(createMenuItem(title: k, image: "-", settings: settings))
            }
            mnu.submenu = submenu
            
            destination_sub_menu.addItem(mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}
