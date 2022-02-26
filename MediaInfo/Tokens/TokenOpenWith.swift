//
//  TokenOpenWith.swift
//  MediaInfoEx
//
//  Created by Sbarex on 24/02/22.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit
import UniformTypeIdentifiers

class TokenOpenWith: Token {
    enum Mode: BaseMode {
        case app(path: String)
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenOpenWith
        }
        
        var title: String {
            switch self {
            case .app: return NSLocalizedString("Open with…", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .app: return NSLocalizedString("Open with…", comment: "")
            }
        }
        
        var placeholder: String {
            switch self {
            case .app(let path): return "[[open-with:\(path.toBase64())]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .app: return NSLocalizedString("Open the file with an external app.", comment: "")
            }
        }
        
        init?(placeholder: String) {
            guard placeholder.hasPrefix("[[open-with:") else {
                return nil
            }
            guard let path = String(placeholder.dropFirst(12).dropLast(2)).fromBase64(), !path.isEmpty else {
                return nil
            }
            self = .app(path: path)
        }
        
        init?(integer: Int) {
            return nil
        }
        
        init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
            guard type == Self.pasteboardType, let data = propertyList as? Data, let t = String(data: data, encoding: .utf8) else {
                return nil
            }
            guard t.hasPrefix("open-with:") else {
                return nil
            }
            let path = t.dropFirst(10)
            self = .app(path: String(path))
        }
        
        func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
           switch self {
           case .app(let path):
               return "open-with::\(path)"
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
            }
        }
        set {
            switch self.mode as! Mode {
            case .app:
                self.mode = Mode.app(path: newValue)
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
    
    required init?(placeholder: String) {
        super.init(placeholder: placeholder)
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }
    
    override func createMenu() -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Action", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(self.createMenuItem(title: Self.Mode.app(path: "").title, state: true, tag: 0, tooltip: Mode.app(path: "").tooltip))
        
        if !self.isReadOnly {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(self.createMenuItem(title: NSLocalizedString("Choose the app…", comment: ""), state: false, tag: 3, tooltip: ""))
        }
        return menu
    }
    
    override func getTokenFromSender(_ sender: NSMenuItem) -> BaseMode? {
        guard let _ = sender.representedObject as? TokenScript else {
            return nil
        }
        switch sender.tag {
        case 0:
            return Mode.app(path: path)
        default:
            return nil
        }
    }
    
    @IBAction override func handleTokenMenu(_ sender: NSMenuItem) {
        guard let token = sender.representedObject as? TokenOpenWith else {
            return
        }

        if sender.tag == 3 {
            token.editPath()
            return
        }
        
        super.handleTokenMenu(sender)
    }
    
    func editPath(action: ((TokenOpenWith?)->Void)? = nil) {
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
        self.path = url.path
        action?(self)
    }
}

extension TokenOpenWith: NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        guard let uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier else {
            return false
        }
        return uti == kUTTypeApplication as String || uti == kUTTypeApplicationBundle as String
    }
}
