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
        
        var title: String {
            switch self {
            case .frames: return NSLocalizedString("Number of frames", comment: "")
            case .fps: return NSLocalizedString("Frames per second", comment: "")
            case .profile: return NSLocalizedString("Profile name", comment: "")
            case .title: return NSLocalizedString("Title", comment: "")
            case .encoder: return NSLocalizedString("Encoder", comment: "")
            case .fieldOrder: return NSLocalizedString("Field order", comment: "")
            case .pixelFormat: return NSLocalizedString("Pixel format", comment: "")
            case .colorSpace: return NSLocalizedString("Color space", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .frames: return String(format: NSLocalizedString("%d frames", tableName: "LocalizableExt", comment: ""), 1500)
            case .fps: return String(format: NSLocalizedString("%d fps", tableName: "LocalizableExt", comment: ""), 24)
            case .profile: return "Main"
            case .title: return "title"
            case .encoder: return "encoder"
            case .fieldOrder: return VideoTrackInfo.VideoFieldOrder.topFirst.label
            case .pixelFormat: return VideoTrackInfo.VideoPixelFormat.yuv420p.label
            case .colorSpace: return VideoTrackInfo.VideoColorSpace.gbr.label
            }
        }
        
        var placeholder: String {
            switch self {
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
        
        init?(placeholder: String) {
            switch placeholder {
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
    
    override var title: String {
        return NSLocalizedString("Video metadata", comment: "")
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
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}

class TokenAudioTrackMetadata: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case title
        case encoder
        case sampleRate
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenAudioTrackMetadata
        }
        
        var title: String {
            switch self {
            case .title: return NSLocalizedString("Title", comment: "")
            case .encoder: return NSLocalizedString("Encoder", comment: "")
            case .sampleRate: return NSLocalizedString("Sample Rate", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .title: return "title"
            case .encoder: return "encoder"
            case .sampleRate: return "sample rate"
            }
        }
        
        var placeholder: String {
            switch self {
            case .title: return "[[title]]"
            case .encoder: return "[[encoder]]"
            case .sampleRate: return "[[sample-rate]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[title]]": self = .title
            case "[[encoder]]": self = .encoder
            case "[[sample-rate]]": self = .sampleRate
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.audio]
    }
    
    override var title: String {
        return NSLocalizedString("Audio metadata", comment: "")
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
        menu.addItem(withTitle: self.title, action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
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
        case sampleRate
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenAudioMetadata
        }
        
        var title: String {
            switch self {
            case .title: return NSLocalizedString("Title", comment: "")
            case .encoder: return NSLocalizedString("Encoder", comment: "")
            case .chaptersCount: return NSLocalizedString("Number of chapters", comment: "")
            case .chapters: return NSLocalizedString("Chapters list", comment: "")
            case .channels: return NSLocalizedString("Number of channels", comment: "")
            case .channels_name: return NSLocalizedString("Channels", comment: "")
            case .sampleRate: return NSLocalizedString("Sample Rate", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .title: return "title"
            case .encoder: return "encoder"
            case .chaptersCount: return String(format: NSLocalizedString("%d Chapters", tableName: "LocalizableExt", comment: ""), 2)
            case .chapters: return NSLocalizedString("Chapters list", comment: "")
            case .channels: return String(format: NSLocalizedString("%d channels", tableName: "LocalizableExt", comment: ""), 2)
            case .channels_name: return NSLocalizedString("stereo", tableName: "LocalizableExt", comment: "")
            case .sampleRate: return NSLocalizedString("Sample Rate", comment: "")
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
            case .sampleRate: return "[[sample-rate]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .channels_name: return NSLocalizedString("Mono, Stereo, or number of channels.", comment: "")
            default: return nil
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
            case "[[sample-rate]]": self = .sampleRate
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.audio]
    }
    
    override var title: String {
        return NSLocalizedString("Audio metadata", comment: "")
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
        menu.addItem(withTitle: NSLocalizedString("Metadata", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
