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
        case filesize
        case fileName
        case fileExtension
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenPDFMetadata
        }
        
        var displayString: String {
            switch self {
            case .author: return NSLocalizedString("Author", comment: "")
            case .producer: return NSLocalizedString("Producer", comment: "")
            case .creator: return NSLocalizedString("Creator", comment: "")
            case .creationDate: return NSLocalizedString("Creation Date", comment: "")
            case .modificationDate: return NSLocalizedString("Modification Date", comment: "")
            case .keywords: return NSLocalizedString("Keywords", comment: "")
            case .subject: return NSLocalizedString("Subject", comment: "")
            case .title: return NSLocalizedString("Title", comment: "")
            case .locked: return NSLocalizedString("Locked", comment: "")
            case .encrypted: return NSLocalizedString("Encrypted", comment: "")
            case .security: return NSLocalizedString("Security", comment: "")
            case .allowCopy: return NSLocalizedString("Allow copy", comment: "")
            case .allowPrint: return NSLocalizedString("Allow print", comment: "")
            case .version: return NSLocalizedString("PDF Version", comment: "")
            case .pages: return "10 " + NSLocalizedString("pages", tableName: "LocalizableExt", comment: "")
            case .filesize: return "2.5 Mb"
            case .fileName: return "filename.ext"
            case .fileExtension: return "ext"
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
            case .filesize: return "[[filesize]]"
            case .fileName: return "[[file-name]]"
            case .fileExtension: return "[[file-ext]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .author: return ""
            case .producer: return ""
            case .creator: return ""
            case .creationDate: return ""
            case .modificationDate: return ""
            case .keywords: return ""
            case .subject: return ""
            case .title: return ""
            case .locked: return ""
            case .encrypted: return ""
            case .security: return ""
            case .allowCopy: return NSLocalizedString("Allow copy status (Yes/No).", comment: "")
            case .allowPrint: return NSLocalizedString("Allow print status (Yes/No).", comment: "")
            case .version: return ""
            case .pages: return NSLocalizedString("Number of pages.", comment: "")
            case .filesize: return NSLocalizedString("File size.", comment: "")
            case .fileName: return NSLocalizedString("File name.", comment: "")
            case .fileExtension: return NSLocalizedString("File extension.", comment: "")
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
            case "[[filesize]]": self = .filesize
            case "[[file-name]]": self = .fileName
            case "[[file-ext]]": self = .fileExtension
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.pdf]
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
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenPdfMetadata.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}
