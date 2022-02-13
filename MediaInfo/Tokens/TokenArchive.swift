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
        // case compressionMethod = 1
        case files = 1
        case filesWithIcon
        case filesPlain
        case filesPlainWithIcon
        case fileCount
        
        case filesize
        case fileName
        case fileExtension
        case uncompressedSize
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenArchiveTrack
        }
        
        var displayString: String {
            switch self {
            // case .compressionMethod: return "deflate"
            case .files: return NSLocalizedString("Files submenu", comment: "")
            case .filesWithIcon: return NSLocalizedString("Files submenu (with icons)", comment: "")
            case .filesPlain: return NSLocalizedString("Plain files submenu", comment: "")
            case .filesPlainWithIcon: return NSLocalizedString("Plain files submenu (with icons)", comment: "")
            case .fileCount: return String(format: NSLocalizedString("%d files", tableName: "LocalizableExt", comment: ""), 3)
                
            case .filesize: return "2.5 Mb"
            case .fileName: return "filename.ext"
            case .fileExtension: return "ext"
            case .uncompressedSize: return "1Mb"
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
            
            case .filesize: return "[[filesize]]"
            case .fileName: return "[[file-name]]"
            case .fileExtension: return "[[file-ext]]"
            case .uncompressedSize: return "[[uncompressed-size]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            // case .compressionMethod: return NSLocalizedString("Compression method.", comment: "")
            case .files: return NSLocalizedString("Files submenu.", comment: "")
            case .filesWithIcon: return NSLocalizedString("Files submenu (with icons).", comment: "")
            case .filesPlain: return NSLocalizedString("Plain files submenu.", comment: "")
            case .filesPlainWithIcon: return NSLocalizedString("Plain files submenu (with icons).", comment: "")
            
            case .fileCount: return NSLocalizedString("File count.", comment: "")
                
            case .filesize: return NSLocalizedString("File size.", comment: "")
            case .fileName: return NSLocalizedString("File name.", comment: "")
            case .fileExtension: return NSLocalizedString("File extension.", comment: "")
            case .uncompressedSize: return NSLocalizedString("Uncompressed size.", comment: "")
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
                
            case "[[filesize]]": self = .filesize
            case "[[file-name]]": self = .fileName
            case "[[file-ext]]": self = .fileExtension
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
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenArchive.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}
