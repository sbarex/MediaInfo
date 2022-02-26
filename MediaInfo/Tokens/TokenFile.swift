//
//  TokenFile.swift
//  MediaInfoEx
//
//  Created by Sbarex on 24/02/22.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenFile: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case filesize = 1
        case fileName
        case fileExtension
        case fileCreationDate
        case fileModificationDate
        case fileAccessDate
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenFile
        }
        
        var title: String {
            switch self {
            case .filesize: return NSLocalizedString("File size", comment: "")
            case .fileName: return NSLocalizedString("File name", comment: "")
            case .fileExtension: return NSLocalizedString("File extension", comment: "")
            case .fileCreationDate: return NSLocalizedString("Creation date", comment: "")
            case .fileModificationDate: return NSLocalizedString("Modification date", comment: "")
            case .fileAccessDate: return NSLocalizedString("Last access date", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .filesize: return "12 MB"
            case .fileName: return "filename.ext"
            case .fileExtension: return "ext"
            case .fileCreationDate: return "29 November"
            case .fileModificationDate: return "16 May"
            case .fileAccessDate: return "8 August"
            }
        }
        
        var placeholder: String {
            switch self {
            case .filesize: return "[[filesize]]"
            case .fileName: return "[[file-name]]"
            case .fileExtension: return "[[file-ext]]"
            case .fileCreationDate: return "[[file-cdate]]"
            case .fileModificationDate: return "[[file-mdate]]"
            case .fileAccessDate: return "[[file-adate]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[filesize]]": self = .filesize
            case "[[file-name]]": self = .fileName
            case "[[file-ext]]": self = .fileExtension
            case "[[file-cdate]]": self = .fileCreationDate
            case "[[file-mdate]]": self = .fileModificationDate
            case "[[file-adate]]": self = .fileAccessDate
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return SupportedType.allCases
    }
    
    override var title: String {
        return NSLocalizedString("File properies", comment: "")
    }
    
    init(mode: Mode) {
        super.init()
        self.mode = mode
    }
    
    required convenience init?(mode: BaseMode) {
        guard let m = mode as? Mode else { return nil }
        self.init(mode: m)
    }
    
    required init?(placeholder: String) {
        super.init(placeholder: placeholder)
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }
    
    override func createMenu() -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("File properies", comment: ""), action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(NSMenuItem.separator())
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenFile.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        return menu
    }
}
