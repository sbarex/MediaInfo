//
//  TokenDimensional.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenDimensional: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case widthHeight = 1
        case width
        case height
        case ratio
        case resolution
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenDimensional
        }
        
        var displayString: String {
            switch self {
            case .widthHeight: return "1920 × 1080 px"
            case .width: return "1920 px"
            case .height: return "1080 px"
            case .ratio: return "16 : 9"
            case .resolution: return "FullHD"
            }
        }
        
        var placeholder: String {
            switch self {
            case .widthHeight: return "[[size]]"
            case .width: return "[[width]]"
            case .height: return "[[height]]"
            case .ratio: return "[[ratio]]"
            case .resolution: return "[[resolution]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .widthHeight: return nil
            case .width: return NSLocalizedString("Width.", comment: "")
            case .height: return NSLocalizedString("Height.", comment: "")
            case .ratio: return NSLocalizedString("Ratio.", comment: "")
            case .resolution: return NSLocalizedString("Resolution name.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[size]]": self = .widthHeight
            case "[[width]]": self = .width
            case "[[height]]": self = .height
            case "[[ratio]]": self = .ratio
            case "[[resolution]]": self = .resolution
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.image, .video]
    }
    
    init(mode: Mode) {
        super.init()
        self.mode = mode
    }
    
    required init?(mode: BaseMode) {
        guard mode is Mode else { return nil }
        super.init(mode: mode)
    }
    
    required init?(placeholder: String) {
        super.init(placeholder: placeholder)
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }
    
    override func getMenu(extra: [String: AnyHashable] = [:], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Dimensions", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenDimensional.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        self.callbackMenu = callback
        return menu
    }
}
