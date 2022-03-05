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
        
        var title: String {
            switch self {
            case .creator: return NSLocalizedString("Creator", comment: "")
            case .creationDate: return NSLocalizedString("Creation date", comment: "")
            case .creation: return NSLocalizedString("Creator name and date", comment: "")
            case .modified: return NSLocalizedString("Last author", comment: "")
            case .modificationDate: return NSLocalizedString("Modification date", comment: "")
            case .modification: return NSLocalizedString("Last author and date", comment: "")
            case .title: return NSLocalizedString("Title", comment: "")
            case .subject: return NSLocalizedString("Subject", comment: "")
            case .keywords: return NSLocalizedString("Keywords list", comment: "")
            case .description: return NSLocalizedString("Description", comment: "")
                
            case .pages: return NSLocalizedString("Number of pages/sheets/slides", comment: "")
            case .words: return NSLocalizedString("Number of words", comment: "")
            case .characters: return NSLocalizedString("Number of characters", comment: "")
            case .charactersWithSpacesCount: return NSLocalizedString("Number of characters (spaces included)", comment: "")
            case .sheets: return NSLocalizedString("Sheets list", comment: "")
            case .application: return NSLocalizedString("Application name", tableName: "LocalizableExt", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .pages: return NSLocalizedString("pages/sheets/slides count", comment: "")
            case .words: return String(format: NSLocalizedString("%d Words", tableName: "LocalizableExt", comment: ""), 500)
            case .characters: return String(format: NSLocalizedString("%d characters", tableName: "LocalizableExt", comment: ""), 1850)
            case .charactersWithSpacesCount: return String(format:  NSLocalizedString("%d characters (spaces included)", tableName: "LocalizableExt", comment: ""), 200)
            default: return self.title
            }
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
            
            case .application: return "[[application]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .keywords: return NSLocalizedString("Submenu with all keywords.", comment: "")
            case .sheets: return NSLocalizedString("Submenu with sheets name (for spreadsheet files).", comment: "")
            case .words: return NSLocalizedString("Number of words (for document files).", comment: "")
            case .characters: return NSLocalizedString("Number of characters (for document files).", comment: "")
            case .charactersWithSpacesCount: return NSLocalizedString("Number of characters, spaces included (for document files).", comment: "")
            default: return nil
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
    
    override var title: String {
        return NSLocalizedString("Office metadata", comment: "")
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
    
    override func validate(with info: BaseInfo?) -> (info: String, warnings: String) {
        guard let mode = self.mode as? Mode, mode.requireDeepScan else {
            return super.validate(with: info)
        }
        return (
            info: String(format: NSLocalizedString("The token ‘%@’ require the deep scan of the file and can slow down menu generation.", comment: ""), mode.displayString),
            warnings: ""
        )
    }
    
    override func createMenu() -> NSMenu? {
        let menu = NSMenu()
        
        menu.addItem(withTitle: NSLocalizedString("Metadata", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenOfficeMetadata.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
