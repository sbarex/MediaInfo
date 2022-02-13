//
//  TokenPrint.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenPrint: Token {
    static let dpiView = DPIView(frame: CGRect(x: 0, y: 0, width: 200, height: 25))
    
    enum Mode: Equatable, BaseMode {
        case dpi
        case print(dpi: Int, unit: PrintUnit)
        
        static var pasteboardType: NSPasteboard.PasteboardType {
           return .MITokenPrint
        }
        
        var displayString: String {
           switch self {
           case .dpi: return "150 dpi"
           case .print(let d, let unit):
               let dpi = d <= 0 ? 150 : d
               let w = (1920.0 / Double(dpi)) * unit.scale
               let h = (1080.0 / Double(dpi)) * unit.scale
               let w1 = BaseInfo.numberFormatter.string(from: NSNumber(value: w)) ?? "\(w)"
               let h1 = BaseInfo.numberFormatter.string(from: NSNumber(value: h)) ?? "\(h)"
               return "\(w1) × \(h1) \(unit.label)"+(dpi != 150 ? " (\(dpi) dpi)" : "")
           }
        }
        
        var placeholder: String {
            switch self {
            case .dpi: return "[[dpi]]"
            case .print(let dpi, let unit):
                if dpi <= 0 {
                    return "[[print:\(unit.label)]]"
                } else {
                    return "[[print:\(unit.label):\(dpi)]]"
                }
            }
        }
        
        var tooltip: String? {
            switch self {
            case .dpi: return NSLocalizedString("Resolution.", comment: "")
            case .print(_, let unit): return NSLocalizedString("Printed size", comment: "")+" ("+NSLocalizedString(unit.label, tableName: "LocalizableExt", comment: "")+")."
            }
        }
        
        init?(integer: Int) {
            return nil
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[dpi]]": self = .dpi
            case "[[print:mm]]": self = .print(dpi: -1, unit: .mm)
            case "[[print:cm]]": self = .print(dpi: -1, unit: .cm)
            case "[[print:in]]": self = .print(dpi: -1, unit: .inch)
            
            default:
                guard placeholder.hasPrefix("[[print:") else {
                    return nil
                }
                let tokens = placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).split(separator: ":")
                guard tokens.count == 3, let dpi = Int(tokens[2]) else {
                    return nil
                }
                
                let unit: PrintUnit
                switch tokens[1] {
                case "cm":
                    unit = .cm
                case "mm":
                    unit = .mm
                case "inch":
                    unit = .inch
                default:
                    unit = .cm
                }
                
                self = .print(dpi: dpi, unit: unit)
            }
        }
        
        init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
            guard type == Self.pasteboardType, let data = propertyList as? Data, let t = String(data: data, encoding: .utf8) else {
                return nil
            }
            if t == "dpi" {
                self = .dpi
                return
            }
            guard t.hasPrefix("print:") else {
                return nil
            }
            
            let c = t.split(separator: ":")
            guard c.count==3, let dpi = Int(c[1]), let u = Int(c[2]), let unit = PrintUnit(rawValue: u) else {
                return nil
            }
            self = .print(dpi: dpi, unit: unit)
        }
        
        func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
           switch self {
           case .dpi:
               return "dpi"
           case .print(let dpi, let unit):
               return "print:\(dpi):\(unit.rawValue)"
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
        let dpi: Int
        let unit: PrintUnit?
        switch mode {
        case .dpi:
            dpi = -1
            unit = nil
        case .print(let d, let u):
            dpi = d
            unit = u
        }
       
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Resolution", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(self.createMenuItem(title: Mode.dpi.displayString, state: mode == .dpi, tag: 0, tooltip: Mode.dpi.tooltip))
        menu.addItem(NSMenuItem.separator())

        for mode_unit in PrintUnit.allCases {
            let mode = Mode.print(dpi: 150, unit: mode_unit)
            menu.addItem(self.createMenuItem(title: mode.displayString, state: unit == mode_unit, tag: mode_unit.rawValue, tooltip: mode.tooltip))
        }
        
    
        let item = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        Self.dpiView.isEnabled = dpi > 0
        Self.dpiView.dpi = dpi > 0 ? dpi : 300
        Self.dpiView.token = self
        item.view = Self.dpiView
        
        self.callbackMenu = callback
        return menu
    }
    
    @IBAction override func handleTokenMenu(_ sender: NSMenuItem) {
        if let token = sender.representedObject as? TokenPrint {
            switch sender.tag {
            case 0:
                token.mode = Mode.dpi
            case 1:
                token.mode = Mode.print(dpi: Self.dpiView.isEnabled ? Self.dpiView.dpi : -1, unit: .cm)
            case 2:
                token.mode = Mode.print(dpi: Self.dpiView.isEnabled ? Self.dpiView.dpi : -1, unit: .mm)
            case 3:
                token.mode = Mode.print(dpi: Self.dpiView.isEnabled ? Self.dpiView.dpi : -1, unit: .inch)
            default:
                return
            }
        } else {
            return
        }
        
        super.handleTokenMenu(sender)
    }
}
