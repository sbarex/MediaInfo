//
//  ModelInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class ModelInfo: FileInfo {
    class SubMesh: Codable {
        enum CodingKeys: String, CodingKey {
            case name
            case material
            case geometryType
        }
        let name: String
        let material: String?
        let geometryType: Int
        
        init(name: String, material: String?, geometryType: Int) {
            self.name = name
            self.material = material
            self.geometryType = geometryType
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.material = try container.decode(String?.self, forKey: .material)
            self.geometryType = try container.decode(Int.self, forKey: .geometryType)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.name, forKey: .name)
            try container.encode(self.material, forKey: .material)
            try container.encode(self.geometryType, forKey: .geometryType)
        }
        
        var imageName: String {
            switch self.geometryType {
            case 0: return "3d_points"
            case 1: return "3d_lines"
            case 2: return "3d_triangle"
            case 3: return "3d_triangle_stripe"
            case 4: return "3d_quads"
            case 5: return "3d_variable" 
            default:
                return "3d"
            }
        }
    }
    
    class Mesh: Codable {
        enum CodingKeys: String, CodingKey {
            case name
            case vertexCount
            
            case hasNormals
            case hasTangent
            case hasTextureCoordinate
            case hasVertexColor
            case hasOcclusion
            case meshes
        }
        
        let name: String
        let vertexCount: Int
        
        let hasNormals: Bool
        let hasTangent: Bool
        let hasTextureCoordinate: Bool
        let hasVertexColor: Bool
        let hasOcclusion: Bool
        
        var meshes: [SubMesh] = []
                
        init(name: String, vertexCount: Int, hasNormals: Bool, hasTangent: Bool, hasTextureCoordinate: Bool, hasVertexColor: Bool, hasOcclusion: Bool) {
            self.name = name
            self.vertexCount = vertexCount
            self.hasNormals = hasNormals
            self.hasTangent = hasTangent
            self.hasTextureCoordinate = hasTextureCoordinate
            self.hasVertexColor = hasVertexColor
            self.hasOcclusion = hasOcclusion
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.vertexCount = try container.decode(Int.self, forKey: .vertexCount)
            self.hasNormals = try container.decode(Bool.self, forKey: .hasNormals)
            self.hasTangent = try container.decode(Bool.self, forKey: .hasTangent)
            self.hasTextureCoordinate = try container.decode(Bool.self, forKey: .hasTextureCoordinate)
            self.hasVertexColor = try container.decode(Bool.self, forKey: .hasVertexColor)
            self.hasOcclusion = try container.decode(Bool.self, forKey: .hasOcclusion)
            self.meshes = try container.decode([SubMesh].self, forKey: .meshes)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.name, forKey: .name)
            try container.encode(self.vertexCount, forKey: .vertexCount)
            try container.encode(self.hasNormals, forKey: .hasNormals)
            try container.encode(self.hasTangent, forKey: .hasTangent)
            try container.encode(self.hasTextureCoordinate, forKey: .hasTextureCoordinate)
            try container.encode(self.hasVertexColor, forKey: .hasVertexColor)
            try container.encode(self.hasOcclusion, forKey: .hasOcclusion)
            try container.encode(self.meshes, forKey: .meshes)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case meshes
    }
    
    var meshes: [Mesh]
    var vertexCount: Int {
        return meshes.reduce(0, { $0 + $1.vertexCount })
    }
    
    var hasNormals: Bool {
        return meshes.first(where: { $0.hasNormals }) != nil
    }
    var hasTangent: Bool {
        return meshes.first(where: { $0.hasTangent }) != nil
    }
    var hasTextureCoordinate: Bool {
        return meshes.first(where: { $0.hasTextureCoordinate }) != nil
    }
    var hasVertexColor: Bool {
        return meshes.first(where: { $0.hasVertexColor }) != nil
    }
    var hasOcclusion: Bool {
        return meshes.first(where: { $0.hasOcclusion }) != nil
    }
    
    override class var infoType: Settings.SupportedFile { return .model }
    override var standardMainItem: MenuItemInfo {
        let template = "[[mesh]], [[vertex]]"
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "3d", template: template))
    }
    
    init(file: URL, meshes: [Mesh]) {
        self.meshes = meshes
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.meshes = try container.decode([Mesh].self, forKey: .meshes)
        
        try super.init(from: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.meshes, forKey: .meshes)
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
            
        case "[[mesh-count]]":
            return self.formatCount(meshes.count, noneLabel: "no Mesh", singleLabel: "1 Mesh", manyLabel: "%@ Meshs", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[vertex]]":
            return self.formatCount(vertexCount, noneLabel: "no Vertex", singleLabel: "1 Vertex", manyLabel: "%@ Vertices", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[normals]]":
            isFilled = self.hasNormals
            return NSLocalizedString(self.hasNormals ? "with normals" : "without normals", tableName: "LocalizableExt", comment: "")
        case "[[tangents]]":
            isFilled = self.hasTangent
            return NSLocalizedString(self.hasTangent ? "with tangents" : "without tangents", tableName: "LocalizableExt", comment: "")
        case "[[tex-coords]]":
            isFilled = self.hasTextureCoordinate
            return NSLocalizedString(self.hasTextureCoordinate ? "with texture coordinates" : "without texture coordinates", tableName: "LocalizableExt", comment: "")
        case "[[vertex-color]]":
            isFilled = self.hasVertexColor
            return NSLocalizedString(self.hasVertexColor ? "with vertex colors" : "without vertex colors", tableName: "LocalizableExt", comment: "")
        case "[[occlusion]]":
            isFilled = self.hasOcclusion
            return NSLocalizedString(self.hasOcclusion ? "with occlusion" : "without occlusion", tableName: "LocalizableExt", comment: "")
        default:
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        if item.menuItem.template == "[[meshes]]" {
            guard !self.meshes.isEmpty else {
                return true
            }
            let n = self.meshes.count
            let title = self.formatCount(n, noneLabel: "no Mesh", singleLabel: "1 Mesh", manyLabel: "%@ Meshes", useEmptyData: true)
            let mnu = self.createMenuItem(title: title, image: "3D", representedObject: item)
            let submenu = NSMenu(title: title)
            for mesh in self.meshes {
                let mesh_menu = n > 1 ? NSMenu() : submenu
                
                let m = createMenuItem(title: mesh.name.isEmpty ? mesh.name : "Mesh", image: mesh.meshes.first?.imageName, representedObject: item)
                submenu.addItem(m)
                
                let t = self.formatCount(mesh.vertexCount, noneLabel: "no vertex", singleLabel: "1 vertex", manyLabel: "%@ vertices", useEmptyData: true)
                mesh_menu.addItem(createMenuItem(title: t, image: nil, representedObject: item))
                mesh_menu.addItem(NSMenuItem.separator())
                if mesh.hasNormals {
                    mesh_menu.addItem(createMenuItem(title: "with normals", image: "3d_normal", representedObject: item))
                }
                if mesh.hasTangent {
                    mesh_menu.addItem(createMenuItem(title: "with tangents", image: "3d_tangent", representedObject: item))
                }
                if mesh.hasVertexColor {
                    mesh_menu.addItem(createMenuItem(title: "with vertex colors", image: "3d_color", representedObject: item))
                }
                if mesh.hasTextureCoordinate {
                    mesh_menu.addItem(createMenuItem(title: "with texture coordinates", image: "3d_uv", representedObject: item))
                }
                if mesh.hasOcclusion {
                    mesh_menu.addItem(createMenuItem(title: "with occlusion", image: "3d_occlusion", representedObject: item))
                }
                
                if n > 1 {
                    submenu.setSubmenu(mesh_menu, for: m)
                }
            }
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(submenu, for: mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
        }
    }
}
