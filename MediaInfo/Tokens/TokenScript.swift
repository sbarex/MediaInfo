//
//  TokenScript.swift
//  MediaInfo
//
//  Created by Sbarex on 08/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import AppKit

class TokenScript: Token {
    enum Mode: Equatable, BaseMode {
        case inline(code: String)
        case global(code: String)
        
        static var pasteboardType: NSPasteboard.PasteboardType {
           return .MITokenScript
        }
        var isGlobal: Bool {
           switch self {
           case .global: return true
           default: return false
           }
        }
        var isInline: Bool {
           switch self {
           case .inline: return true
           default: return false
           }
        }
        
        var displayString: String {
           switch self {
           case .inline: return "<inline script>"
           case .global: return "<global script>"
           }
        }
        
        var title: String {
           switch self {
           case .inline: return NSLocalizedString("Inline script", comment: "")
           case .global: return NSLocalizedString("Global script", comment: "")
           }
        }
        
        var placeholder: String {
            switch self {
            case .inline(let code): return "[[script-inline:\(code.toBase64())]]"
            case .global(let code): return "[[script-global:\(code.toBase64())]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .inline: return NSLocalizedString("Inline script to compose with other tokens.", comment: "")
            case .global: return NSLocalizedString("Global script to generate multiple menu items.", comment: "")
            }
        }
        
        init?(integer: Int) {
            return nil
        }
        
        init?(placeholder: String) {
            guard placeholder.hasPrefix("[[script-") else {
                return nil
            }
            let p = placeholder.dropFirst(2).dropLast(2).split(separator: ":", maxSplits: 2)
            let code = p.count > 1 ? String(p[1]) : ""
            if p[0] == "script-inline" {
                self = .inline(code: code.fromBase64() ?? "")
            } else if p[0] == "script-global" {
                self = .global(code: code.fromBase64() ?? "")
            } else {
                return nil
            }
        }
        
        init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
            guard type == Self.pasteboardType, let data = propertyList as? Data, let t = String(data: data, encoding: .utf8) else {
                return nil
            }
            guard t.hasPrefix("script-") else {
                return nil
            }
            
            let c = t.split(separator: ":", maxSplits: 2)
            let code = c.count > 1 ? String(c[1]) : ""
            if t.hasPrefix("script-inline:") {
                self = .inline(code: code)
            } else if t.hasPrefix("script-global:") {
                self = .global(code: code)
            } else {
                return nil
            }
        }
        
        func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
           switch self {
           case .inline(let code):
               return "script-inline:\(code)"
           case .global(let code):
               return "script-global:\(code)"
           }
       }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return SupportedType.allCases
    }
    
    override var requireSingle: Bool {
        guard let mode = self.mode as? Mode else {
            return false
        }
        
        switch mode {
        case .inline: return false
        case .global: return true
        }
    }
    
    var code: String {
        get {
            switch self.mode as! Mode {
            case .inline(let code):
                return code
            case .global(let code):
                return code
            }
        }
        set {
            switch self.mode as! Mode {
            case .inline:
                self.mode = Mode.inline(code: newValue)
            case .global:
                self.mode = Mode.global(code: newValue)
            }
        }
    }
    
    override var title: String {
        return NSLocalizedString("Scripts", comment: "")
    }
    
    init(mode: Mode) {
        super.init()
        self.mode = mode
    }
    
    required init?(mode: BaseMode) {
        guard mode is Mode else { return nil }
        super.init(mode: mode)
    }
    
    required convenience init?(placeholder: String) {
        if let mode = Mode(placeholder: placeholder) {
            self.init(mode: mode)
        } else {
            return nil
        }
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
    }
    
    override func validate(with info: BaseInfo?) -> (info: String, warnings: String) {
        if let info = info {
            let msg = info.getScriptInfo(token: self)
            return (info: msg, warnings: "")
        }
        return (info: "", warnings: "")
    }
    
    override func createMenu() -> NSMenu? {
        let mode = self.mode as! Mode
       
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Script", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        let allCases = [Mode.inline(code: ""), Mode.global(code: "")]
        for (i, item) in allCases.enumerated() {
            let on = (mode.isInline && item.isInline) || (mode.isGlobal && item.isGlobal)
            menu.addItem(self.createMenuItem(title: item.title, state: on, tag: i, tooltip: item.tooltip))
        }
        if !self.isReadOnly {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(self.createMenuItem(title: NSLocalizedString("Customize the script…", comment: ""), state: false, tag: 3, tooltip: ""))
        }
        
        return menu
    }
    
    override func getTokenFromSender(_ sender: NSMenuItem) -> BaseMode? {
        guard let _ = sender.representedObject as? TokenScript else {
            return nil
        }
        switch sender.tag {
        case 0:
            return Mode.inline(code: code)
        case 1:
            return Mode.global(code: code)
        default:
            return nil
        }
    }
    
    @IBAction override func handleTokenMenu(_ sender: NSMenuItem) {
        guard let token = sender.representedObject as? TokenScript else {
            return
        }

        if sender.tag == 3 {
            token.editScript() { _ in
                self.callbackMenu?(self, sender)
            }
            return
        }
        
        super.handleTokenMenu(sender)
    }
    
    func editScript(action: ((String)->Void)? = nil ) {
        ScriptViewController.editCode(self.code, mode: (self.mode as! Mode).isInline ? .inline : .global) { code in
            self.code = code
            action?(code)
        }
    }
}

