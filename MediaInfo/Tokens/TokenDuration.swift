//
//  TokenDuration.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenDuration: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case hours = 1
        case seconds
        case bitRate
        case startTime
        case startTimeSeconds
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenDuration
        }
        
        var displayString: String {
            switch self {
            case .hours: return "01:15:23"
            case .seconds: return "4.523 s"
            case .bitRate: return "1 MB/s"
            case .startTime: return NSLocalizedString("start at", comment: "")+" 00:12:00"
            case .startTimeSeconds: return NSLocalizedString("start at second", comment: "")+" 720"
            }
        }
        
        var placeholder: String {
            switch self {
            case .hours: return "[[duration]]"
            case .seconds: return "[[seconds]]"
            case .bitRate: return "[[bitrate]]"
            case .startTime: return "[[start-time]]"
            case .startTimeSeconds: return "[[start-time-s]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .hours: return NSLocalizedString("Time.", comment: "")
            case .seconds: return NSLocalizedString("Duration.", comment: "")
            case .bitRate: return NSLocalizedString("Bit rate.", comment: "")
            case .startTime: return NSLocalizedString("Start time.", comment: "")
            case .startTimeSeconds: return NSLocalizedString("Start time (in seconds).", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[duration]]": self = .hours
            case "[[seconds]]": self = .seconds
            case "[[bitrate]]": self = .bitRate
            case "[[start-time]]": self = .startTime
            case "[[start-time-s]]": self = .startTimeSeconds
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.audio, .video]
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
    
    override func getMenu(extra: [String: AnyHashable], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Duration", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenDuration.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}
