//
//  TokenModelMetadata.swift
//  MediaInfoEx
//
//  Created by Sbarex on 3/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class TokenModelMetadata: Token {
    enum Mode: Int, CaseIterable, BaseMode {
        case meshCount = 1
        case meshes
        case vertex
        case normals
        case tangents
        case textureCoordinates
        case vertexColor
        case occlusion
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MITokenModelMetadata
        }
        
        var title: String {
            switch self {
            case .meshCount: return String(format: NSLocalizedString("Number of meshes", comment: ""), 3)
            case .meshes: return NSLocalizedString("Meshes submenu", comment: "")
            case .vertex: return NSLocalizedString("Number of vertices", comment: "")
            case .normals: return NSLocalizedString("Normals availability", comment: "")
            case .tangents: return NSLocalizedString("Tangents availability", comment: "")
            case .textureCoordinates: return NSLocalizedString("Texture coords availability", comment: "")
            case .vertexColor: return NSLocalizedString("Vertex color availability", comment: "")
            case .occlusion: return NSLocalizedString("Occlusion availability", comment: "")
            }
        }
        
        var displayString: String {
            switch self {
            case .meshCount: return String(format: NSLocalizedString("%d Meshes", tableName: "LocalizableExt", comment: ""), 3)
            case .vertex: return String(format: NSLocalizedString("%d vertices", tableName: "LocalizableExt", comment: ""), 2400)
            case .normals: return NSLocalizedString("with normals", tableName: "LocalizableExt", comment: "")
            case .tangents: return NSLocalizedString("with tangents", tableName: "LocalizableExt", comment: "")
            case .textureCoordinates: return NSLocalizedString("with texture coords", tableName: "LocalizableExt", comment: "")
            case .vertexColor: return NSLocalizedString("with vertex color", tableName: "LocalizableExt", comment: "")
            case .occlusion: return NSLocalizedString("with occlusion", tableName: "LocalizableExt", comment: "")
            default: return self.title
            }
        }
        
        var placeholder: String {
            switch self {
            case .meshCount: return "[[mesh-count]]"
            case .meshes: return "[[meshes]]"
            case .vertex: return "[[vertex]]"
            case .normals: return "[[normals]]"
            case .tangents: return "[[tangents]]"
            case .textureCoordinates: return "[[tex-coords]]"
            case .vertexColor: return "[[vertex-color]]"
            case .occlusion: return "[[occlusion]]"
            }
        }
        
        init?(placeholder: String) {
            switch placeholder {
            case "[[mesh-count]]": self = .meshCount
            case "[[meshes]]": self = .meshes
            case "[[vertex]]": self = .vertex
            case "[[normals]]": self = .normals
            case "[[tangents]]": self = .tangents
            case "[[tex-coords]]": self = .textureCoordinates
            case "[[vertex-color]]": self = .vertexColor
            case "[[occlusion]]": self = .occlusion
            
            default: return nil
            }
        }
    }
    
    override class var ModeClass: BaseMode.Type { return Mode.self }
    
    override class var supportedTypes: [SupportedType] {
        return [.model]
    }
    
    override var requireSingle: Bool {
        switch self.mode as! Mode {
        case .meshes:
            return true
        default:
            return false
        }
    }
    
    override var title: String {
        return "3D info"
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
            menu.addItem(self.createMenuItem(title: mode.title, state: self.mode as! TokenModelMetadata.Mode == mode, tag: mode.rawValue, tooltip: mode.tooltip))
        }
        
        return menu
    }
}
