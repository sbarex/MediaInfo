//
//  TokenFolder.swift
//  MediaInfoEx
//
//  Created by Sbarex on 05/03/22.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenFolder: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case files = 1
        case filesWithIcon
        case filesPlain
        case filesPlainWithIcon
        case fileCount
        case processedFileCount
        case fileCountSummary
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenFolderTrack
        }
        
        var title: String {
            switch self {
            case .files: return NSLocalizedString("Files submenu", comment: "")
            case .filesWithIcon: return NSLocalizedString("Files submenu (with icons)", comment: "")
            case .filesPlain: return NSLocalizedString("Plain files submenu", comment: "")
            case .filesPlainWithIcon: return NSLocalizedString("Plain files submenu (with icons)", comment: "")
            case .fileCount: return NSLocalizedString("Number of files", comment: "")
            case .processedFileCount: return NSLocalizedString("Number of processed files", comment: "")
            case .fileCountSummary:
                return NSLocalizedString("Files Summary", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .fileCount: return String(format: NSLocalizedString("%@ files", tableName: "LocalizableExt", comment: ""), "20")
            case .processedFileCount: return String(format: NSLocalizedString("%@ processed files", tableName: "LocalizableExt", comment: ""), "10")
            case .fileCountSummary:
                return String(format: NSLocalizedString("%@ files (%@ processed)", comment: ""), "200", "180")
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
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.folder]
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
        return NSLocalizedString("Folder info", comment: "")
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
        
        menu.addItem(withTitle: NSLocalizedString("Folder", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        var isFiles = true
        var plain = false
        var icons = false
        switch self.mode as! Mode {
        case .files:
            break
        case .filesWithIcon:
            icons = true
        case .filesPlain:
            plain = true
        case .filesPlainWithIcon:
            plain = true
            icons = true
        case .fileCount, .processedFileCount, .fileCountSummary:
            isFiles = false
        }
        let mnu = self.createMenuItem(title: NSLocalizedString("Files menu", comment: ""), state: isFiles, tag: -1, tooltip: nil)
        mnu.submenu = NSMenu()
        mnu.submenu?.addItem(self.createMenuItem(title: NSLocalizedString("Plain", comment: ""), state: isFiles && plain, tag: 1, tooltip: nil))
        mnu.submenu?.addItem(self.createMenuItem(title: NSLocalizedString("Hierarchical", comment: ""), state: isFiles && !plain, tag: 2, tooltip: nil))
        mnu.submenu?.addItem(NSMenuItem.separator())
        mnu.submenu?.addItem(self.createMenuItem(title: NSLocalizedString("Show Icons", comment: ""), state: isFiles && icons, tag: 3, tooltip: nil))
        mnu.submenu?.addItem(self.createMenuItem(title: NSLocalizedString("Hide Icons", comment: ""), state: isFiles && !icons, tag: 4, tooltip: nil))
        menu.addItem(mnu)
        menu.addItem(self.createMenuItem(title: Mode.fileCount.title, state: self.mode as! TokenFolder.Mode == Mode.fileCount, tag: 5, tooltip: Mode.fileCount.tooltip))
        menu.addItem(self.createMenuItem(title: Mode.processedFileCount.title, state: self.mode as! TokenFolder.Mode == Mode.processedFileCount, tag: 6, tooltip: Mode.processedFileCount.tooltip))
        menu.addItem(self.createMenuItem(title: Mode.fileCountSummary.title, state: self.mode as! TokenFolder.Mode == Mode.fileCountSummary, tag: 7, tooltip: Mode.fileCountSummary.tooltip))
        
        return menu
    }
    
    override func handleTokenMenu(_ sender: NSMenuItem) {
        let mode: Mode
        if sender.tag == 5 {
            mode = Mode.fileCount
        } else if sender.tag == 6 {
            mode = Mode.processedFileCount
        } else if sender.tag == 7 {
            mode = Mode.fileCountSummary
        } else {
            var plain = false
            var icons = false
            switch self.mode as! Mode {
            case .files:
                break
            case .filesWithIcon:
                icons = true
            case .filesPlain:
                plain = true
            case .filesPlainWithIcon:
                plain = true
                icons = true
            case .fileCount, .processedFileCount, .fileCountSummary:
                break
            }
            
            if sender.tag == 1 {
                mode = icons ? .filesPlainWithIcon : .filesPlain
            } else if sender.tag == 2 {
                mode = icons ? .filesWithIcon : .files
            } else if sender.tag == 3 {
                mode = plain ? .filesPlainWithIcon : .filesWithIcon
            } else if sender.tag == 4 {
                mode = plain ? .filesPlain : .files
            } else {
                return
            }
        }
        
        if self.isReadOnly {
            if let t = Self.init(mode: mode) {
                self.callbackMenu?(t, sender)
            }
        } else {
            self.mode = mode
            self.callbackMenu?(self, sender)
        }
    }
}
