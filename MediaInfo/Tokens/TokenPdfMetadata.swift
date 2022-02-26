//
//  TokenPdfMetadata.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenPdfMetadata: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case author = 1
        case producer
        case creator
        case creationDate
        case modificationDate
        case keywords
        case subject
        case title
        case locked
        case encrypted
        case security
        case allowCopy
        case allowPrint
        case version
        case pages
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenPDFMetadata
        }
        
        var title: String {
            switch self {
            case .author: return NSLocalizedString("Author", comment: "")
            case .producer: return NSLocalizedString("Producer", comment: "")
            case .creator: return NSLocalizedString("Creator", comment: "")
            case .creationDate: return NSLocalizedString("Creation date", comment: "")
            case .modificationDate: return NSLocalizedString("Modification date", comment: "")
            case .keywords: return NSLocalizedString("Keywords list", comment: "")
            case .subject: return NSLocalizedString("Subject", comment: "")
            case .title: return NSLocalizedString("Title", comment: "")
            case .locked: return NSLocalizedString("Locked status", comment: "")
            case .encrypted: return NSLocalizedString("Encrypted status", comment: "")
            case .security: return NSLocalizedString("Security", comment: "")
            case .allowCopy: return NSLocalizedString("Allow copy", comment: "")
            case .allowPrint: return NSLocalizedString("Allow print", comment: "")
            case .version: return NSLocalizedString("PDF Version", comment: "")
            case .pages: return NSLocalizedString("Number of pages", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .pages: return String(format: NSLocalizedString("%d Pages", tableName: "LocalizableExt", comment: ""), 10)
            default: return self.title
            }
        }
        
        var placeholder: String {
            switch self {
            case .author: return "[[author]]"
            case .producer: return "[[producer]]"
            case .creator: return "[[creator]]"
            case .creationDate: return "[[creation-date]]"
            case .modificationDate: return "[[modification-date]]"
            case .keywords: return "[[keywords]]"
            case .subject: return "[[subject]]"
            case .title: return "[[title]]"
            case .locked: return "[[locked]]"
            case .encrypted: return "[[encrypted]]"
            case .security: return "[[security]]"
            case .allowCopy: return "[[allows-copy]]"
            case .allowPrint: return "[[allows-print]]"
            case .version: return "[[version]]"
            case .pages: return "[[pages]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .allowCopy: return NSLocalizedString("Allow copy status (Yes/No).", comment: "")
            case .allowPrint: return NSLocalizedString("Allow print status (Yes/No).", comment: "")
            default: return nil
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[author]]": self = .author
            case "[[producer]]": self = .producer
            case "[[creator]]": self = .creator
            case "[[creation-date]]": self = .creationDate
            case "[[modification-date]]": self = .modificationDate
            case "[[keywords]]": self = .keywords
            case "[[subject]]": self = .subject
            case "[[title]]": self = .title
            case "[[locked]]": self = .locked
            case "[[encrypted]]": self = .encrypted
            case "[[security]]": self = .security
            case "[[allows-copy]]": self = .allowCopy
            case "[[allows-print]]": self = .allowPrint
            case "[[version]]": self = .version
            case "[[pages]]": self = .pages
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.pdf]
    }
    
    override var title: String {
        return NSLocalizedString("PDF metadata", comment: "")
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
    
    override func createMenu() -> NSMenu? {
        let menu = NSMenu()
        
        menu.addItem(withTitle: NSLocalizedString("Metadata", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenPdfMetadata.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
