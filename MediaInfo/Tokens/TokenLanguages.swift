//
//  TokenLanguages.swift
//  MediaInfoEx
//
//  Created by Sbarex on 25/02/22.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenLanguages: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case names = 1
        case flags
        case count
        case name
        case flag
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenLanguages
        }
        
        var title: String {
            switch self {
            case .names: return NSLocalizedString("Language ISO country codes", comment: "")
            case .flags: return NSLocalizedString("Language country flags", comment: "")
            case .count: return NSLocalizedString("Number of available languages", comment: "")
            case .name: return NSLocalizedString("Main language ISO country code", comment: "")
            case .flag: return NSLocalizedString("Main language country flag", comment: "")
            }
        }
        
        var tooltip: String? {
            switch self {
            case .names: return NSLocalizedString("List of all available language ISO country codes.", comment: "")
            case .flags: return NSLocalizedString("Flags  of all available languages.", comment: "")
            default: return nil
            }
        }
        
        var displayString: String {
            switch self {
            case .names: return "EN IT"
            case .flags: return "🇺🇸 🇮🇹"
            case .count: return String(format: NSLocalizedString("%d Languages", tableName: "LocalizableExt", comment: ""), 2)
            case .name: return "EN"
            case .flag: return "🇺🇸"
            }
        }
        
        var placeholder: String {
            switch self {
            case .count: return "[[language-count]]"
            case .names: return "[[languages]]"
            case .flags: return "[[languages-flag]]"
            case .name: return "[[language]]"
            case .flag: return "[[language-flag]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[language-count]]": self = .count
            case "[[languages]]": self = .names
            case "[[languages-flag]]": self = .flags
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
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenLanguages.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
