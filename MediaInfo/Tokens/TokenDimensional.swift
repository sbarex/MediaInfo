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
        case pixelCount
        case megapixel
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenDimensional
        }
        
        var title: String {
            switch self {
            case .widthHeight: return NSLocalizedString("Size (width × height)", comment: "")
            case .width: return NSLocalizedString("Width", comment: "")
            case .height: return NSLocalizedString("Height", comment: "")
            case .ratio: return NSLocalizedString("Ratio", comment: "")
            case .resolution: return NSLocalizedString("Resolution name", comment: "")
            case .pixelCount: return NSLocalizedString("Number of pixel", comment: "")
            case .megapixel: return NSLocalizedString("Number of pixel (Mpx)", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .widthHeight: return "1920 × 1080 px"
            case .width: return "1920 px"
            case .height: return "1080 px"
            case .ratio: return "16 : 9"
            case .resolution: return "FullHD"
            case .pixelCount: return "786432"
            case .megapixel: return "0.78 Mpx"
            }
        }
        
        var placeholder: String {
            switch self {
            case .widthHeight: return "[[size]]"
            case .width: return "[[width]]"
            case .height: return "[[height]]"
            case .ratio: return "[[ratio]]"
            case .resolution: return "[[resolution]]"
            case .pixelCount: return "[[pixel-count]]"
            case .megapixel: return "[[mega-pixel]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[size]]": self = .widthHeight
            case "[[width]]": self = .width
            case "[[height]]": self = .height
            case "[[ratio]]": self = .ratio
            case "[[resolution]]": self = .resolution
            case "[[pixel-count]]": self = .pixelCount
            case "[[mega-pixel]]": self = .megapixel
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.image, .video]
    }

    override var title: String {
        return NSLocalizedString("Dimensions", comment: "Token dimensional name.")
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
    
    override func createMenu() -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Dimensions", comment: "Token dimensional name."), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenDimensional.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        return menu
    }
}
