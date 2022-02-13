//
//  TokenOfficeMetadata.swift
//  MediaInfoEx
//
//  Created by Sbarex on 26/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenOfficeMetadata: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case creator = 1
        case creationDate
        case creation
        case modified
        case modificationDate
        case modification
        case title
        case subject
        case keywords
        case description
        
        case pages
        case characters
        case charactersWithSpacesCount
        case words
        case sheets
        
        case filesize
        case fileName
        case fileExtension
        
        case application
        
        var requireDeepScan: Bool {
            switch self {
            case .pages, .sheets:
                return true
            default:
                return false
            }
        }
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenOfficeMetadata
        }
        
        var displayString: String {
            let s: String
            switch self {
            case .creator: s = NSLocalizedString("Creator", comment: "")
            case .creationDate: s = NSLocalizedString("Creation Date", comment: "")
            case .creation: s = NSLocalizedString("Creator name and date", comment: "")
            case .modified: s = NSLocalizedString("Last author", comment: "")
            case .modificationDate: s = NSLocalizedString("Modification Date", comment: "")
            case .modification: s = NSLocalizedString("Last author and date", comment: "")
            case .title: s = NSLocalizedString("Title", comment: "")
            case .subject: s = NSLocalizedString("Subject", comment: "")
            case .keywords: s = NSLocalizedString("Keywords", comment: "")
            case .description: s = NSLocalizedString("Description", comment: "")
                
            case .pages: s = NSLocalizedString("pages/sheets/slides count", comment: "")
            case .words: s = "235 " + NSLocalizedString("words", tableName: "LocalizableExt", comment: "")
            case .characters: s = "1850 " + NSLocalizedString("characters", tableName: "LocalizableExt", comment: "")
            case .charactersWithSpacesCount: s = "2000 " + NSLocalizedString("characters (spaces included)", tableName: "LocalizableExt", comment: "")
            case .sheets: s = NSLocalizedString("sheets", tableName: "LocalizableExt", comment: "")
            case .filesize: s = "2.5 Mb"
            case .fileName: s = "filename.ext"
            case .fileExtension: s = "ext"
            case .application: s = NSLocalizedString("Application name", tableName: "LocalizableExt", comment: "")
            }
            return s //  + (self.requireDeepScan ? " " + NSLocalizedString("[deep scan required]", tableName: "LocalizableExt", comment: "") : "")
        }
        
        var placeholder: String {
            switch self {
            case .creator: return "[[creator]]"
            case .creationDate: return "[[creation-date]]"
            case .creation: return "[[creation]]"
            case .modified: return "[[last-author]]"
            case .modification: return "[[last-modification]]"
            case .modificationDate: return "[[modification-date]]"
            case .title: return "[[title]]"
            case .subject: return "[[subject]]"
            case .description: return "[[description]]"
            case .keywords: return "[[keywords]]"
                
            case .pages: return "[[pages]]"
            case .words: return "[[words]]"
            case .characters: return "[[characters]]"
            case .charactersWithSpacesCount: return "[[characters-space]]"
            case .sheets: return "[[sheets]]"
            
            case .filesize: return "[[filesize]]"
            case .fileName: return "[[file-name]]"
            case .fileExtension: return "[[file-ext]]"
            case .application: return "[[application]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .creator: return ""
            case .creationDate: return ""
            case .creation: return ""
            case .modified: return ""
            case .modificationDate: return ""
            case .modification: return ""
            case .title: return ""
            case .subject: return ""
            case .keywords: return NSLocalizedString("Submenu with all keywords.", comment: "")
                
            case .description: return ""
            case .sheets: return NSLocalizedString("Submenu with sheets name (for spreadsheet files).", comment: "")
            case .pages: return ""
            case .words: return NSLocalizedString("Number of words (for document files).", comment: "")
            case .characters: return NSLocalizedString("Number of characters (for document files).", comment: "")
            case .charactersWithSpacesCount: return NSLocalizedString("Number of characters, spaces included (for document files).", comment: "")
            case .filesize: return NSLocalizedString("File size.", comment: "")
            case .fileName: return NSLocalizedString("File name.", comment: "")
            case .fileExtension: return NSLocalizedString("File extension.", comment: "")
            case .application: return ""
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[creator]]": self = .creator
            case "[[creation-date]]": self = .creationDate
            case "[[creation]]": self = .creation
            case "[[last-author]]": self = .modified
            case "[[modification-date]]": self = .modificationDate
            case "[[last-modification]]": self = .modification
            case "[[title]]": self = .title
            case "[[subject]]": self = .subject
            case "[[description]]": self = .description
            case "[[keywords]]": self = .keywords
            
            case "[[pages]]": self = .pages
            case "[[words]]": self = .words
            case "[[characters]]": self = .characters
            case "[[characters-space]]": self = .charactersWithSpacesCount
            case "[[sheets]]": self = .sheets
            
            case "[[filesize]]": self = .filesize
            case "[[file-name]]": self = .fileName
            case "[[file-ext]]": self = .fileExtension
                
            case "[[application]]": self = .application
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.office]
    }
    
    override var requireSingle: Bool {
        switch self.mode as! Mode {
        case .sheets, .keywords:
            return true
        default:
            return false
        }
    }
    
    override var informativeMessage: String {
        guard let mode = self.mode as? Mode else {
            return super.informativeMessage
        }
        if mode.requireDeepScan {
            return String(format: NSLocalizedString("The token '%@' require the deep scan of the file and can slow down menu generation.", comment: ""), mode.displayString)
        }
        return super.informativeMessage
    }
    
    required convenience init?(mode: BaseMode) {
        guard let m = mode as? Mode else { return nil }
        self.init(mode: m)
    }
    
    required init(mode: Mode) {
        super.init()
        self.mode = mode
    }
    
    required init?(placeholder: String) {
        super.init(placeholder: placeholder)
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }
    
    override func getMenu(extra: [String : AnyHashable] = [:], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = NSMenu()
        
        menu.addItem(withTitle: NSLocalizedString("Metadata", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenOfficeMetadata.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}
