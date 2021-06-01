//
//  TokenVideoMetadata.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenVideoMetadata: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case language_count
        case languages
        case languages_flag
        case frames
        case fps
        case profile
        case title
        case encoder
        case fieldOrder
        case pixelFormat
        case colorSpace
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenVideoMetadata
        }
        
        var displayString: String {
            switch self {
            case .language_count: return "2 "+NSLocalizedString("languages", tableName: "LocalizableExt", comment: "")
            case .languages: return "EN IT"
            case .languages_flag: return "🇺🇸 🇮🇹"
            case .frames: return "1.500 "+NSLocalizedString("frames", tableName: "LocalizableExt", comment: "")
            case .fps: return "24 "+NSLocalizedString("fps", tableName: "LocalizableExt", comment: "")
            case .profile: return "Main"
            case .title: return "title"
            case .encoder: return "encoder"
            case .fieldOrder: return VideoFieldOrder.topFirst.label
            case .pixelFormat: return VideoPixelFormat.yuv420p.label
            case .colorSpace: return VideoColorSpace.gbr.label
            }
        }
        
        var placeholder: String {
            switch self {
            case .language_count: return "[[language-count]]"
            case .languages: return "[[languages]]"
            case .languages_flag: return "[[languages-flag]]"
            case .frames: return "[[frames]]"
            case .fps: return "[[fps]]"
            case .profile: return "[[profile]]"
            case .title: return "[[title]]"
            case .encoder: return "[[encoder]]"
            case .fieldOrder: return "[[field-order]]"
            case .pixelFormat: return "[[pixel-format]]"
            case .colorSpace: return "[[color-space]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .language_count: return NSLocalizedString("Number of available languages.", comment: "")
            case .languages: return NSLocalizedString("List of available languages (on video and audio tracks).", comment: "")
            case .languages_flag: return NSLocalizedString("List of available languages (on video and audio tracks) rendered as a country flag.", comment: "")
            case .frames: return NSLocalizedString("Number of frames.", comment: "")
            case .fps: return NSLocalizedString("Frames per second.", comment: "")
            case .profile: return NSLocalizedString("Profile.", comment: "")
            case .title: return NSLocalizedString("Title.", comment: "")
            case .encoder: return NSLocalizedString("Encoder.", comment: "")
            case .fieldOrder: return NSLocalizedString("Field order.", comment: "")
            case .pixelFormat: return NSLocalizedString("Pixel format.", comment: "")
            case .colorSpace: return NSLocalizedString("Color space.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[language-count]]": self = .language_count
            case "[[languages]]": self = .languages
            case "[[languages-flag]]": self = .languages_flag
            case "[[frames]]": self = .frames
            case "[[fps]]": self = .fps
            case "[[profile]]": self = .profile
            case "[[title]]": self = .title
            case "[[encoder]]": self = .encoder
            case "[[field-order]]": self = .fieldOrder
                
            case "[[pixel-format]]": self = .pixelFormat
            case "[[color-space]]": self = .colorSpace
                
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.video]
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
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}

class TokenAudioMetadata: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case title
        case encoder
        case chapters
        case chaptersCount
        case channels
        case channels_name
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenAudioMetadata
        }
        
        var displayString: String {
            switch self {
            case .title: return "title"
            case .encoder: return "encoder"
            case .chaptersCount: return String(format: NSLocalizedString("%d Chapters", tableName: "LocalizableExt", comment: ""), 2)
            case .chapters: return NSLocalizedString("Chapters list", comment: "")
            case .channels: return NSLocalizedString("1 channel", tableName: "LocalizableExt", comment: "")
            case .channels_name: return NSLocalizedString("mono", tableName: "LocalizableExt", comment: "")
            }
        }
        
        var placeholder: String {
            switch self {
            case .title: return "[[title]]"
            case .encoder: return "[[encoder]]"
            case .chaptersCount: return "[[chapters-count]]"
            case .chapters: return "[[chapters]]"
            case .channels: return "[[channels]]"
            case .channels_name: return "[[channels-name]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .title: return NSLocalizedString("Title.", comment: "")
            case .encoder: return NSLocalizedString("Encoder.", comment: "")
            case .chapters: return NSLocalizedString("List of chapters.", comment: "")
            case .chaptersCount: return NSLocalizedString("Number of chapters.", comment: "")
            case .channels: return NSLocalizedString("Number of channels.", comment: "")
            case .channels_name: return NSLocalizedString("Mono, Stereo, or number of channels.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[title]]": self = .title
            case "[[encoder]]": self = .encoder
            case "[[chapters]]": self = .chapters
            case "[[chapters-count]]": self = .chaptersCount
            case "[[channels]]": self = .channels
            case "[[channels-name]]": self = .channels_name
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.audio]
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
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}
