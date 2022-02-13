//
//  TokenOfficeSize.swift
//  MediaInfoEx
//
//  Created by Sbarex on 27/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenOfficeSize: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case print_cm
        case print_mm
        case print_inch
        case print_paper
        case print_paper_cm
        case print_paper_mm
        case print_paper_inch
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenOfficeSize
        }
        
        var displayString: String {
            switch self {
            case .print_cm: return "21 × 29.7 cm"
            case .print_mm: return "210 × 297 mm"
            case .print_inch: return "8.26 × 11,69 inch"
            case .print_paper: return "A4"
            case .print_paper_cm: return "A4 / 21 × 29.7 cm"
            case .print_paper_mm: return "A4 / 210 × 297 mm"
            case .print_paper_inch: return "A4 / 8.26 × 11,69 inch"
                
            }
        }
        
        var placeholder: String {
            switch self {
            case .print_cm: return "[[size:cm]]"
            case .print_mm: return "[[size:mm]]"
            case .print_inch: return "[[size:in]]"
            case .print_paper: return "[[size:paper]]"
            case .print_paper_cm: return "[[size:paper:cm]]"
            case .print_paper_mm: return "[[size:paper:mm]]"
            case .print_paper_inch: return "[[size:paper:in]]"
            }
        }
        
        var tooltip: String? {
            switch self {
            case .print_cm, .print_mm, .print_inch, .print_paper: return NSLocalizedString("Page size (for document files).", comment: "")
            case .print_paper_cm, .print_paper_mm, .print_paper_inch: return NSLocalizedString("Page format or page size (for document files).", comment: "")
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[size:cm]]": self = .print_cm
            case "[[size:mm]]": self = .print_mm
            case "[[size:in]]": self = .print_inch
            case "[[size:paper]]": self = .print_paper
            case "[[size:paper:cm]]": self = .print_paper_cm
            case "[[size:paper:mm]]": self = .print_paper_mm
            case "[[size:paper:in]]": self = .print_paper_inch
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.office]
    }
    
    override var informativeMessage: String {
        guard let mode = self.mode as? Mode else {
            return super.informativeMessage
        }
        return String(format: NSLocalizedString("The token '%@' require the deep scan of the file and can slow down menu generation.", comment: ""), mode.displayString)
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
        
        menu.addItem(withTitle: NSLocalizedString("Dimensions", comment: ""), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        for mode in Mode.allCases {
            menu.addItem(self.createMenuItem(title: mode.displayString, state: self.mode as! TokenOfficeSize.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        self.callbackMenu = callback
        return menu
    }
}
