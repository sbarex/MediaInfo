//
//  TokenMediaExtra.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenImageExtra: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case filesize = 1
        case animated
        case is_animated
        case alpha
        case is_alpha
        case fileName
        case fileExtension
        case paper
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenImageExtra
        }
        
        var displayString: String {
            switch self {
            case .filesize: return "12 MB"
            case .animated: return NSLocalizedString("animated", tableName: "LocalizableExt", comment: "") + " / " + NSLocalizedString("static", tableName: "LocalizableExt", comment: "")
            case .is_animated: return NSLocalizedString("animated", tableName: "LocalizableExt", comment: "")
            case .alpha: return NSLocalizedString("transparent", tableName: "LocalizableExt", comment: "") + " / " + NSLocalizedString("opaque", tableName: "LocalizableExt", comment: "")
            case .is_alpha: return NSLocalizedString("with alpha channel", tableName: "LocalizableExt", comment: "")
            case .fileName: return "filename.ext"
            case .fileExtension: return "ext"
            case .paper: return "A4"
            }
        }
        
        var placeholder: String {
            switch self {
            case .filesize: return "[[filesize]]"
            case .animated: return "[[animated]]"
            case .is_animated: return "[[is-animated]]"
            case .alpha: return "[[alpha]]"
            case .is_alpha: return "[[is-alpha]]"
            case .fileName: return "[[file-name]]"
            case .fileExtension: return "[[file-ext]]"
            case .paper: return "[[paper]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .filesize: return NSLocalizedString("File size.", comment: "")
            case .animated: return NSLocalizedString("Animated/static.", comment: "")
            case .is_animated: return NSLocalizedString("Animated status.", comment: "")
            case .alpha: return NSLocalizedString("With/Without alpha channel.", comment: "")
            case .is_alpha: return NSLocalizedString("With alpha channel.", comment: "")
            case .fileName: return NSLocalizedString("File name.", comment: "")
            case .fileExtension: return NSLocalizedString("File extension.", comment: "")
            case .paper: return NSLocalizedString("File extension.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[filesize]]": self = .filesize
            case "[[animated]]": self = .animated
            case "[[is-animated]]": self = .is_animated
            case "[[alpha]]": self = .alpha
            case "[[is-alpha]]": self = .is_alpha
            case "[[file-name]]": self = .fileName
            case "[[file-ext]]": self = .fileExtension
            case "[[paper]]": self = .paper
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.image]
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
    
    override func getMenu(extra: [String : AnyHashable] = [:], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = NSMenu()
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenImageExtra.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        self.callbackMenu = callback
        return menu
    }
}

class TokenMediaExtra: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case codec_short_name = 1
        case codec_full_name
        case codec
        case filesize
        case fileName
        case fileExtension
        case engine
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenVideoExtra
        }
        
        var displayString: String {
            switch self {
            case .codec_short_name: return "hevc"
            case .codec_full_name: return "H265 HEVC"
            case .codec: return "hevc / H265 HEVC"
            case .filesize: return "450 MB"
            case .fileName: return "filename.ext"
            case .fileExtension: return "ext"
            case .engine: return NSLocalizedString("Media engine", comment: "")
            }
        }
        
        var placeholder: String {
            switch self {
            case .codec_short_name: return "[[codec-short]]"
            case .codec_full_name: return "[[codec-long]]"
            case .codec: return "[[codec]]"
            case .filesize: return "[[filesize]]"
            case .fileName: return "[[file-name]]"
            case .fileExtension: return "[[file-ext]]"
            case .engine: return "[[engine]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .codec_short_name: return NSLocalizedString("Codec (short name).", comment: "")
            case .codec_full_name: return NSLocalizedString("Codec (full name).", comment: "")
            case .codec: return NSLocalizedString("Codec.", comment: "")
            case .filesize: return NSLocalizedString("File size.", comment: "")
            case .fileName: return NSLocalizedString("File name.", comment: "")
            case .fileExtension: return NSLocalizedString("File extension.", comment: "")
            case .engine: return NSLocalizedString("Media engine.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[codec-short]]": self = .codec_short_name
            case "[[codec-long]]": self = .codec_full_name
            case "[[codec]]": self = .codec
            case "[[filesize]]": self = .filesize
            case "[[file-name]]": self = .fileName
            case "[[file-ext]]": self = .fileExtension
            case "[[engine]]": self = .engine
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.video, .audio]
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
    
    override func getMenu(extra: [String : AnyHashable] = [:], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = NSMenu()
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        self.callbackMenu = callback
        return menu
    }
}

class TokenMediaTrack: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case chaptersCount
        case chapters
        case video
        case videoCount
        case audio
        case audioCount
        case subtitle
        case subtitleCount
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenMediaTrack
        }
        
        var displayString: String {
            switch self {
            case .chaptersCount: return String(format: NSLocalizedString("%d Chapters", tableName: "LocalizableExt", comment: ""), 2)
            case .chapters: return NSLocalizedString("Chapters list", comment: "")
            case .video: return NSLocalizedString("Video tracks", comment: "")
            case .videoCount: return NSLocalizedString("1 Video track", tableName: "LocalizableExt", comment: "")
            case .audio: return NSLocalizedString("Audio tracks", comment: "")
            case .audioCount: return NSLocalizedString("1 Audio track", tableName: "LocalizableExt", comment: "")
            case .subtitle: return NSLocalizedString("Subtitle list", comment: "")
            case .subtitleCount: return NSLocalizedString("1 Subtitle", tableName: "LocalizableExt", comment: "")
            }
        }
        
        var placeholder: String {
            switch self {
            case .chaptersCount: return "[[chapters-count]]"
            case .chapters: return "[[chapters]]"
            case .video: return "[[video]]"
            case .videoCount: return "[[video-count]]"
            case .audio: return "[[audio]]"
            case .audioCount: return "[[audio-count]]"
            case .subtitle: return "[[subtitles]]"
            case .subtitleCount: return "[[subtitles-count]]"
            
            }
        }
        
        var tooltip: String? {
            switch self {
            case .chapters: return NSLocalizedString("List of chapters.", comment: "")
            case .chaptersCount: return NSLocalizedString("Number of chapters.", comment: "")
            case .video: return NSLocalizedString("List of video tracks.", comment: "")
            case .videoCount: return NSLocalizedString("Number of video tracks.", comment: "")
            case .audio: return NSLocalizedString("List of audio tracks.", comment: "")
            case .audioCount: return NSLocalizedString("Number of audio tracks.", comment: "")
            case .subtitle: return NSLocalizedString("List of subtitles.", comment: "")
            case .subtitleCount: return NSLocalizedString("Number of available subtitles.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[chapters]]": self = .chapters
            case "[[chapters-count]]": self = .chaptersCount
            case "[[video]]": self = .video
            case "[[video-count]]": self = .videoCount
            case "[[audio]]": self = .audio
            case "[[audio-count]]": self = .audioCount
            case "[[subtitles]]": self = .subtitle
            case "[[subtitle-count]]": self = .subtitleCount
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.video]
    }
    
    override var requireSingle: Bool {
        guard let mode = self.mode as? Mode else {
            return false
        }
        switch mode {
        case .audio, .video, .subtitle, .chapters:
            return true
        default:
            return false
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
    
    override func getMenu(extra: [String : AnyHashable] = [:], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = NSMenu()
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        self.callbackMenu = callback
        return menu
    }
}

