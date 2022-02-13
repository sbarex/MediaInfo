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
        
        var displayString: String {
           switch self {
           case .inline: return "<inline script>"
           case .global: return "<global script>"
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
            case .inline: return NSLocalizedString("Inline script.", comment: "")
            case .global: return NSLocalizedString("Global script.", comment: "")
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
    
    override func getMenu(extra: [String : AnyHashable] = [:], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let mode = self.mode as! Mode
        let isInline: Bool
        switch mode {
        case .inline:
            isInline = true
        case .global:
            isInline = false
        }
       
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Script", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(self.createMenuItem(title: NSLocalizedString("Inline script", comment: ""), state: isInline, tag: 0, tooltip: Mode.inline(code: "").tooltip))
        menu.addItem(self.createMenuItem(title: NSLocalizedString("Global script", comment: ""), state: !isInline, tag: 1, tooltip: Mode.global(code: "").tooltip))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.createMenuItem(title: NSLocalizedString("Customize the script…", comment: ""), state: false, tag: 3, tooltip: ""))
        
        self.callbackMenu = callback
        return menu
    }
    
    @IBAction override func handleTokenMenu(_ sender: NSMenuItem) {
        guard let token = sender.representedObject as? TokenScript else {
            return
        }
        let code = self.code
        
        switch sender.tag {
        case 0:
            token.mode = Mode.inline(code: code)
        case 1:
            token.mode = Mode.global(code: code)
        case 3:
            guard let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ScriptEditorController") as? ScriptViewController else {
                return
            }
            vc.token = token
            NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(vc)
            break
        default:
            return
        }
        
        super.handleTokenMenu(sender)
    }
}

