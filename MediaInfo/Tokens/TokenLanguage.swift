//
//  TokenLanguage.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenLanguage: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case name = 1
        case flag
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenLanguage
        }
        
        var title: String {
            switch self {
            case .name: return NSLocalizedString("Language ISO country code", comment: "")
            case .flag: return NSLocalizedString("Language country flag", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .name: return "EN"
            case .flag: return "🇺🇸"
            }
        }
        
        var placeholder: String {
            switch self {
            case .name: return "[[language]]"
            case .flag: return "[[language-flag]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[language]]": self = .name
            case "[[language-flag]]": self = .flag
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.video, .audio, .subtitle]
    }
    
    override var title: String {
        return NSLocalizedString("Language", comment: "")
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
        menu.addItem(withTitle: NSLocalizedString("Language", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenLanguage.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
