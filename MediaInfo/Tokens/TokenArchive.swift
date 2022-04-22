//
//  TokenArchive.swift
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
        case processedFileCount
        case fileCountSummary
        
        case compressionMethod
        case uncompressedSize
        case compressionSummary
        case compressionRatio
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenArchiveTrack
        }
        
        var title: String {
            switch self {
            case .uncompressedSize: return NSLocalizedString("Uncompressed file size", comment: "")
            case .files: return NSLocalizedString("Files submenu", comment: "")
            case .filesWithIcon: return NSLocalizedString("Files submenu (with icons)", comment: "")
            case .filesPlain: return NSLocalizedString("Plain files submenu", comment: "")
            case .filesPlainWithIcon: return NSLocalizedString("Plain files submenu (with icons)", comment: "")
            case .fileCount: return NSLocalizedString("Number of files", comment: "")
            case .processedFileCount: return NSLocalizedString("Number of processed files", comment: "")
            case .fileCountSummary: return NSLocalizedString("File Summary", comment: "")
            case .compressionMethod: return NSLocalizedString("Compression format", comment: "")
            case .compressionSummary: return NSLocalizedString("Compression Summary", comment: "")
            case .compressionRatio: return NSLocalizedString("Compression ratio", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .uncompressedSize: return String(format: NSLocalizedString("%@ uncompressed", tableName: "LocalizableExt", comment: ""), "3Mb")
             case .fileCount: return String(format: NSLocalizedString("%@ files", tableName: "LocalizableExt", comment: ""), "30")
            case .processedFileCount: return String(format: NSLocalizedString("%@ processed files", tableName: "LocalizableExt", comment: ""), "10")
            case .fileCountSummary:
                return String(format: NSLocalizedString("%@ files (%@ processed)", comment: ""), "200", "180")
            case .compressionSummary:
                return String(format: NSLocalizedString("%@ = %@", comment: ""), "1Mb", String(format: NSLocalizedString("%@ uncompressed", tableName: "LocalizableExt", comment: ""), "3Mb"))+" (66%)"
            case .compressionRatio:
                return "66%"
            case .compressionMethod: return "gzip"
            default:
                return self.title
            }
        }
        
        var placeholder: String {
            switch self {
            case .files: return "[[files]]"
            case .filesWithIcon: return "[[files-with-icon]]"
            case .filesPlain: return "[[files-plain]]"
            case .filesPlainWithIcon: return "[[files-plain-with-icon]]"
            case .fileCount: return "[[n-files]]"
            case .processedFileCount: return "[[n-files-processed]]"
            case .fileCountSummary: return "[[n-files-all]]"
            
            case .compressionMethod: return "[[compression-format]]"
            case .uncompressedSize: return "[[uncompressed-size]]"
            case .compressionSummary: return "[[compression-summary]]"
            case .compressionRatio: return "[[compression-ratio]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[files]]": self = .files
            case "[[files-with-icon]]": self = .filesWithIcon
            case "[[files-plain]]": self = .filesPlain
            case "[[files-plain-with-icon]]": self = .filesPlainWithIcon
                
            case "[[n-files]]": self = .fileCount
            case "[[n-files-processed]]": self = .processedFileCount
            case "[[n-files-all]]": self = .fileCountSummary
                
            case "[[compression-format]]": self = .compressionMethod
            case "[[uncompressed-size]]": self = .uncompressedSize
            case "[[compression-summary]]": self = .compressionSummary
            case "[[compression-ratio]]": self = .compressionRatio
                
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
        case .files, .filesWithIcon, .filesPlain, .filesPlainWithIcon:
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
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenArchive.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
