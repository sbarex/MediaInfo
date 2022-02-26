//
//  TokenArchiveMetadata.swift
//  MediaInfoEx
//
//  Created by Sbarex on 15/01/22.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenArchive: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case files = 1
        case filesWithIcon
        case filesPlain
        case filesPlainWithIcon
        case fileCount
        
        case uncompressedSize
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenArchiveTrack
        }
        
        var title: String {
            switch self {
            case .files: return NSLocalizedString("Files submenu", comment: "")
            case .filesWithIcon: return NSLocalizedString("Files submenu (with icons)", comment: "")
            case .filesPlain: return NSLocalizedString("Plain files submenu", comment: "")
            case .filesPlainWithIcon: return NSLocalizedString("Plain files submenu (with icons)", comment: "")
            case .fileCount: return NSLocalizedString("Number of files", comment: "")
            case .uncompressedSize: return NSLocalizedString("Uncompressed file size", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .fileCount: return String(format: NSLocalizedString("%d files", tableName: "LocalizableExt", comment: ""), 3)
            case .uncompressedSize: return "1Mb"
            default:
                return self.title
            }
        }
        
        var placeholder: String {
            switch self {
            // case .compressionMethod: return "[[compression-method]]"
            case .files: return "[[files]]"
            case .filesWithIcon: return "[[files-with-icon]]"
            case .filesPlain: return "[[files-plain]]"
            case .filesPlainWithIcon: return "[[files-plain-with-icon]]"
            case .fileCount: return "[[n-files]]"
            
            case .uncompressedSize: return "[[uncompressed-size]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            // case "[[compression-method]]": self = .compressionMethod
            case "[[files]]": self = .files
            case "[[files-with-icon]]": self = .filesWithIcon
            case "[[files-plain]]": self = .filesPlain
            case "[[files-plain-with-icon]]": self = .filesPlainWithIcon
                
            case "[[n-files]]": self = .fileCount
                
            case "[[uncompressed-size]]": self = .uncompressedSize
                
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.archive]
    }
    
    override var requireSingle: Bool {
        switch self.mode as! Mode {
        case .files:
            return true
        default:
            return false
        }
    }
    
    required convenience init?(mode: BaseMode) {
        guard let m = mode as? Mode else { return nil }
        self.init(mode: m)
    }
    
    override var title: String {
        return NSLocalizedString("Archive info", comment: "")
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
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenArchive.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
