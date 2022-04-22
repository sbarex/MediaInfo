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
        case filesizeFull
        case fileName
        case fileExtension
        case fileCreationDate
        case fileModificationDate
        case fileAccessDate
        case fileMode
        case acl
        case extAttrs
        case fileModeACL
        case fileModeAttrs
        case fileModeACLAttrs
        case uti
        case utiConforms
        case utiDesc
        case spotlight
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenFile
        }
        
        var title: String {
            switch self {
            case .filesize: return NSLocalizedString("File size", comment: "")
            case .filesizeFull: return NSLocalizedString("Allocated file size", comment: "")
            case .fileName: return NSLocalizedString("File name", comment: "")
            case .fileExtension: return NSLocalizedString("File extension", comment: "")
            case .fileCreationDate: return NSLocalizedString("Creation date", comment: "")
            case .fileModificationDate: return NSLocalizedString("Modification date", comment: "")
            case .fileAccessDate: return NSLocalizedString("Last access date", comment: "")
            case .fileMode: return NSLocalizedString("File modes", comment: "")
            case .fileModeACL: return NSLocalizedString("File modes & ACL", comment: "")
            case .fileModeAttrs: return NSLocalizedString("File modes & Extended attributes", comment: "")
            case .fileModeACLAttrs: return NSLocalizedString("File modes & ACL & Extended attributes", comment: "")
            case .extAttrs: return NSLocalizedString("Extended attributes", comment: "")
            case .acl: return NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: "")
            case .uti: return NSLocalizedString("Uniform Type Identifier", comment: "")
            case .utiConforms: return NSLocalizedString("Uniform Type Identifier conformances", comment: "")
            case .utiDesc: return NSLocalizedString("Uniform Type Identifier description", comment: "")
            case .spotlight: return NSLocalizedString("Spotlight medadata", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .filesize: return "12 MB"
            case .filesizeFull: return "13 MB"
            case .fileName: return "filename.ext"
            case .fileExtension: return "ext"
            case .fileCreationDate: return "29 November"
            case .fileModificationDate: return "16 May"
            case .fileAccessDate: return "8 August"
            case .fileMode: return "- rw- r-- r--"
            case .acl: return "<"+NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: "")+">"
            case .extAttrs: return "<"+NSLocalizedString("Extended attributes", comment: "")+">"
            case .fileModeACL: return "- rw- r-- r-- <"+NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: "")+">"
            case .fileModeAttrs: return "- rw- r-- r-- <"+NSLocalizedString("Extended attributes", tableName: "LocalizableExt", comment: "")+">"
            case .fileModeACLAttrs: return "- rw- r-- r-- <"+NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: "")+" & "+NSLocalizedString("Extended attributes", tableName: "LocalizableExt", comment: "")+">"
            case .uti: return "public.jpeg"
            case .utiConforms: return "<uti conformance>"
            case .utiDesc: return "JPEG Image"
            case .spotlight: return "<spotlight>"
            }
        }
        
        var placeholder: String {
            switch self {
            case .filesize: return "[[file-size]]"
            case .filesizeFull: return "[[file-size-full]]"
            case .fileName: return "[[file-name]]"
            case .fileExtension: return "[[file-ext]]"
            case .fileCreationDate: return "[[file-cdate]]"
            case .fileModificationDate: return "[[file-mdate]]"
            case .fileAccessDate: return "[[file-adate]]"
            case .fileMode: return "[[file-modes]]"
            case .acl: return "[[acl]]"
            case .extAttrs: return "[[ext-attributes]]"
            case .fileModeACL: return "[[file-modes:acl]]"
            case .fileModeAttrs: return "[[file-modes:ext-attrs]]"
            case .fileModeACLAttrs: return "[[file-modes:acl:ext-attrs]]"
            case .uti: return "[[uti]]"
            case .utiConforms: return "[[uti-conforms]]"
            case .utiDesc: return "[[uti-desc]]"
            case .spotlight: return "[[spotlight]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[file-size]]", "[[filesize]]": self = .filesize
            case "[[file-size-full]]", "[[filesize-full]]": self = .filesizeFull
            case "[[file-name]]": self = .fileName
            case "[[file-ext]]": self = .fileExtension
            case "[[file-cdate]]": self = .fileCreationDate
            case "[[file-mdate]]": self = .fileModificationDate
            case "[[file-adate]]": self = .fileAccessDate
            case "[[file-modes]]": self = .fileMode
            case "[[acl]]": self = .acl
            case "[[ext-attributes]]": self = .extAttrs
            case "[[file-modes:acl]]": self = .fileModeACL
            case "[[file-modes:ext-attrs]]": self = .fileModeAttrs
            case "[[file-modes:acl:ext-attrs]]": self = .fileModeACLAttrs
            case "[[uti]]": self = .uti
            case "[[uti-conforms]]": self = .utiConforms
            case "[[uti-desc]]": self = .utiDesc
            case "[[spotlight]]": self = .spotlight
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return SupportedType.allCases
    }
    
    override var title: String {
        return NSLocalizedString("File properties", comment: "")
    }
    
    override var requireSingle: Bool {
        switch self.mode as! Mode {
        case .utiConforms: return true
        case .extAttrs: return true
        case .spotlight: return true
        case .acl, .fileModeACL, .fileModeAttrs, .fileModeACLAttrs: return true
        default: return false
        }
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
    
    override func validate(with info: BaseInfo?) -> (info: String, warnings: String) {
        switch self.mode as! Mode {
        case .filesizeFull:
            if let _ = info as? FolderInfo {
                return (info: NSLocalizedString("Calculating the allocated size of the contained files can slow down the menu display.", comment: ""), warnings: "")
            }
        default:
            break
        }
        return super.validate(with: info)
    }
    
    override func createMenu() -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("File properties", comment: ""), action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(NSMenuItem.separator())
        for mode in Mode.allCases {
            guard mode != .fileModeACL, mode != .fileModeAttrs, mode != .fileModeACLAttrs else {
                continue
            }
            let mnu = self.createMenuItem(title: mode.title, state: self.mode as! TokenFile.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip)
            menu.addItem(mnu)
            if mode == .fileMode {
                let submenu = NSMenu()
                submenu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenFile.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
                submenu.addItem(NSMenuItem.separator())
                let modes: [Mode] = [.fileModeACL, .fileModeAttrs, .fileModeACLAttrs]
                for m in modes {
                    submenu.addItem(self.createMenuItem(title: m.title, state: self.mode as! TokenFile.Mode == m, tag: m.rawValue, tooltip: m.tooltip))
                }
                menu.setSubmenu(submenu, for: mnu)
            }
            
        }
        return menu
    }
}
