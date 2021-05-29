//
//  TokenPdfBox.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenPdfBox: Token {
    enum Mode: Int, BaseMode {
        case mediaBox = 1
        case bleedBox
        case cropBox
        case artBox
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenPDFBox
        }
        
        var displayString: String {
            switch self {
            case .mediaBox: return NSLocalizedString("Media Box", comment: "")
            case .bleedBox: return NSLocalizedString("Bleed Box", comment: "")
            case .cropBox: return NSLocalizedString("Crop Box", comment: "")
            case .artBox: return NSLocalizedString("Art Box", comment: "")
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.pdf]
    }
    
    var unit: PDFInfo.PrintUnit
    
    override var displayString: String {
        return mode.displayString+" ("+unit.displayString+")"
    }
    
    override var placeholder: String {
        switch self.mode as! Mode {
        case .mediaBox: return "[[mediabox:\(unit.placeholder)]]"
        case .bleedBox: return "[[bleedbox:\(unit.placeholder)]]"
        case .cropBox: return "[[cropbox:\(unit.placeholder)]]"
        case .artBox: return "[[artbox:\(unit.placeholder)]]"
        }
    }
    
    required convenience init?(mode: BaseMode) {
        guard let m = mode as? Mode else { return nil }
        self.init(mode: m, unit: .pt)
    }
    
    required init(mode: Mode, unit: PDFInfo.PrintUnit) {
        self.unit = unit
        super.init()
        self.mode = mode
    }
    
    required convenience init?(placeholder: String) {
        let t = placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).split(separator: ":", maxSplits: 1)
        var unit: PDFInfo.PrintUnit = .pt
        if t.count == 2, let u = PDFInfo.PrintUnit(placeholder: String(t[1])) {
            unit = u
        }
        switch t[0] {
        case "mediabox": self.init(mode: .mediaBox, unit: unit)
        case "bleedbox": self.init(mode: .bleedBox, unit: unit)
        case "cropbox": self.init(mode: .cropBox, unit: unit)
        case "artbox": self.init(mode: .artBox, unit: unit)
        default:
            return nil
        }
    }
    
    // MARK: - Pasteboard Writing Protocol
    @objc override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        return "\((mode as! Mode).rawValue):\(unit.placeholder)"
    }
    
    
    // MARK: - Pasteboard Reading Protocol
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        guard type == Self.ModeClass.pasteboardType, let data = propertyList as? Data, let t = String(data: data, encoding: .utf8) else {
            return nil
        }
        let n = t.split(separator: ":", maxSplits: 1)
        guard n.count > 0 else {
            return nil
        }
        if n.count == 2 {
            guard let u = PDFInfo.PrintUnit(placeholder: String(n[1])) else {
                return nil
            }
            self.unit = u
        } else {
            self.unit = .pt
        }
        
        guard let i = Int(n[0]), let mode = Mode(rawValue: i) else {
            return nil
        }
        
        super.init()
        self.mode = mode
    }
    
    override func getMenu(extra: [String : AnyHashable] = [:], callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = NSMenu()
        
        menu.addItem(withTitle: self.mode.displayString, action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for unit in PDFInfo.PrintUnit.allCases {
            menu.addItem(self.createMenuItem(title: unit.displayString, state: self.unit == unit, tag: unit.rawValue, tooltip: ""))
        }
        
        self.callbackMenu = callback
        return menu
    }
    
    @IBAction override func handleTokenMenu(_ sender: NSMenuItem) {
        if let token = sender.representedObject as? TokenPdfBox, let unit = PDFInfo.PrintUnit(rawValue: sender.tag) {
            token.unit = unit
        }
        self.callbackMenu?(self, sender)
    }
}
