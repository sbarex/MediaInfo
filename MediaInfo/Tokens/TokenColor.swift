//
//  TokenColor.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenColor: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case colorSpace = 1
        case depth
        case colorSpaceDepth
        case profileName
        case colorTable
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenColor
        }
        
        var title: String {
            switch self {
            case .colorSpaceDepth: return NSLocalizedString("Color space and depth", comment: "")
            case .colorSpace: return NSLocalizedString("Color space", comment: "")
            case .depth: return NSLocalizedString("Color depth", comment: "")
            case .profileName: return NSLocalizedString("Profile name", comment: "")
            case .colorTable: return NSLocalizedString("Color table", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .colorSpaceDepth: return "RGB 8 bit"
            case .colorSpace: return "RGB"
            case .depth: return "8 bit"
            case .profileName: return "LCD Display"
            case .colorTable: return "floating/indexed/regular"
            }
        }
        
        var placeholder: String {
            switch self {
            case .colorSpaceDepth: return "[[color-depth]]"
            case .colorSpace: return "[[color]]"
            case .depth: return "[[depth]]"
            case .profileName: return "[[profile-name]]"
            case .colorTable: return "[[color-table]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[color]]": self = .colorSpace
            case "[[color-depth]]": self = .colorSpaceDepth
            case "[[depth]]": self = .depth
            case "[[profile-name]]": self = .profileName
            case "[[color-table]]": self = .colorTable
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.image]
    }
    
    override var title: String {
        return NSLocalizedString("Color info", comment: "")
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
        menu.addItem(withTitle: NSLocalizedString("Color info", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenColor.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
