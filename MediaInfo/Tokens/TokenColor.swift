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
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenColor
        }
        
        var displayString: String {
            switch self {
            case .colorSpaceDepth: return "RGB 8 bit"
            case .colorSpace: return "RGB"
            case .depth: return "8 bit"
            }
        }
        
        var placeholder: String {
            switch self {
            case .colorSpaceDepth: return "[[color-depth]]"
            case .colorSpace: return "[[color]]"
            case .depth: return "[[depth]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .colorSpaceDepth: return NSLocalizedString("Color space and depth.", comment: "")
            case .colorSpace: return NSLocalizedString("Color space.", comment: "")
            case .depth: return NSLocalizedString("Color depth.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[color]]": self = .colorSpace
            case "[[color-depth]]": self = .colorSpaceDepth
            case "[[depth]]": self = .depth
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.image]
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
        menu.addItem(withTitle: NSLocalizedString("Color space", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenColor.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}
