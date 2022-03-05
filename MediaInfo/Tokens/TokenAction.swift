//
//  TokenAction.swift
//  MediaInfoEx
//
//  Created by Sbarex on 24/02/22.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit
import UniformTypeIdentifiers

class TokenAction: Token {
    enum Mode: BaseMode {
        case app(path: String)
        case defaultApp
        case openSettings
        case about
        case copyToClipboard
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenAction
        }
        
        var title: String {
            switch self {
            case .app: return NSLocalizedString("Open with…", comment: "")
            case .defaultApp: return NSLocalizedString("Open with the default app", comment: "")
            case .openSettings: return NSLocalizedString("MediaInfo Settings…", tableName: "LocalizableExt", comment: "")
            case .about: return NSLocalizedString("About…", comment: "")
            case .copyToClipboard: return NSLocalizedString("Copy path to the clipboard", tableName: "LocalizableExt", comment: "")
            }
        }
        
        var displayString: String {
            return self.title
        }
        
        var placeholder: String {
            switch self {
            case .app(let path): return "[[open-with:\(path.toBase64())]]"
            case .defaultApp: return "[[open-with-default]]"
            case .openSettings: return "[[open-settings]]"
            case .about: return "[[about]]"
            case .copyToClipboard: return "[[clipboard]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .app: return NSLocalizedString("Open the file with an external app.", comment: "")
            default: return nil
            }
        }
        
        init?(placeholder: String) {
            if placeholder == "[[open-with-default]]" {
                self = .defaultApp
            } else if placeholder == "[[open-settings]]" {
                self = .openSettings
            } else if placeholder == "[[about]]" {
                self = .about
            } else if placeholder == "[[clipboard]]" {
                self = .copyToClipboard
            } else {
                guard placeholder.hasPrefix("[[open-with:") else {
                    return nil
                }
                let path = String(placeholder.dropFirst(12).dropLast(2)).fromBase64() ?? ""
                self = .app(path: path)
            }
        }
        
        init?(integer: Int) {
            return nil
        }
        
        init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
            guard type == Self.pasteboardType, let data = propertyList as? Data, let t = String(data: data, encoding: .utf8) else {
                return nil
            }
            if t == "open-with-default" {
                self = .defaultApp
            } else if t == "open-settings" {
                self = .openSettings
            } else if t == "about" {
                self = .about
            } else if t == "clipboard" {
                self = .copyToClipboard
            } else {
                guard t.hasPrefix("open-with:") else {
                    return nil
                }
                let path = t.dropFirst(10)
                self = .app(path: String(path))
            }
        }
        
        func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
           switch self {
           case .defaultApp: return "open-with-default"
           case .openSettings: return "open-settings"
           case .about: return "about"
           case .copyToClipboard: return "clipboard"
           case .app(let path):
               return "open-with:\(path)"
           }
       }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return SupportedType.allCases
    }
    
    override var requireSingle: Bool {
        return true
    }
    
    override var title: String {
        return NSLocalizedString("Actions", comment: "")
    }
    
    var path: String {
        get {
            switch self.mode as! Mode {
            
            case .app(let path):
                return path
            default: return ""
            }
        }
        set {
            switch self.mode as! Mode {
            case .app:
                self.mode = Mode.app(path: newValue)
            default:
                break
            }
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
    
    override func validate(with info: BaseInfo?) -> (info: String, warnings: String) {
        switch self.mode as! Mode {
        case .app(let path):
            if path.isEmpty {
                return (info: "", warnings: NSLocalizedString("You must specify the application used to open the file!", comment: ""))
            }
        default:
            break
        }
        return (info: "", warnings: "")
    }
    
    required init?(placeholder: String) {
        super.init(placeholder: placeholder)
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }
    
    override func createMenu() -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Actions", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        var isOpenWith = false
        var isDefault = false
        var isAbout = false
        var isClipboard = false
        var isSettings = false
        switch self.mode as! Mode {
        case .app: isOpenWith = true
        case .defaultApp: isDefault = true
        case .openSettings: isSettings = true
        case .about: isAbout = true
        case .copyToClipboard: isClipboard = true
        }
        
        let mnu = self.createMenuItem(title: Self.Mode.app(path: "").title, state: isOpenWith || isDefault, tag: -1, tooltip: Mode.app(path: "").tooltip)
        mnu.submenu = NSMenu()
        mnu.submenu?.addItem(self.createMenuItem(title: Self.Mode.app(path: "").title, state: isOpenWith, tag: 0, tooltip: Mode.app(path: "").tooltip))
        mnu.submenu?.addItem(self.createMenuItem(title: Self.Mode.defaultApp.title, state: isDefault, tag: 1, tooltip: Mode.defaultApp.tooltip))
        if !self.isReadOnly {
            mnu.submenu?.addItem(NSMenuItem.separator())
            mnu.submenu?.addItem(self.createMenuItem(title: NSLocalizedString("Choose the app…", comment: ""), state: false, tag: 10, tooltip: ""))
        }
        
        menu.addItem(mnu)
        
        menu.addItem(self.createMenuItem(title: Self.Mode.openSettings.title, state: isSettings, tag: 2, tooltip: Mode.openSettings.tooltip))
        menu.addItem(self.createMenuItem(title: Self.Mode.copyToClipboard.title, state: isClipboard, tag: 4, tooltip: Mode.copyToClipboard.tooltip))
        menu.addItem(self.createMenuItem(title: Self.Mode.about.title, state: isAbout, tag: 3, tooltip: Mode.about.tooltip))
        
        return menu
    }
    
    override func getTokenFromSender(_ sender: NSMenuItem) -> BaseMode? {
        guard let _ = sender.representedObject as? TokenAction else {
            return nil
        }
        switch sender.tag {
        case 0:
            return Mode.app(path: path)
        case 1:
            return Mode.defaultApp
        case 2:
            return Mode.openSettings
        case 3:
            return Mode.about
        case 4:
            return Mode.copyToClipboard
        default:
            return nil
        }
    }
    
    @IBAction override func handleTokenMenu(_ sender: NSMenuItem) {
        guard let token = sender.representedObject as? TokenAction else {
            return
        }

        if sender.tag == 10 {
            token.editPath() { _ in
                self.callbackMenu?(self, sender)
            }
            return
        }
        
        super.handleTokenMenu(sender)
    }
    
    func editPath(action: ((TokenAction?)->Void)? = nil) {
        let dialog = NSOpenPanel()

        dialog.title = NSLocalizedString("Choose the Application", comment: "")
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        dialog.canCreateDirectories = false
        dialog.directoryURL = path.isEmpty ? nil : URL(fileURLWithPath: path).deletingLastPathComponent()
        dialog.nameFieldStringValue = path
        if #available(macOS 11.0, *) {
            dialog.allowedContentTypes = [.application]
        } else {
            dialog.delegate = self
            // Fallback on earlier versions
        }
        guard dialog.runModal() == .OK, let url = dialog.url else {
            return
        }
        self.mode = Mode.app(path: url.path)

        action?(self)
    }
}

extension TokenAction: NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        guard let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier else {
            return false
        }
        return uti == kUTTypeApplication as String || uti == kUTTypeApplicationBundle as String
    }
}
