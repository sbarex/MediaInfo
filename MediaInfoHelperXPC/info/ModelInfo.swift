//
//  ModelInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class ModelInfo: BaseInfo, FileInfo {
    class SubMesh {
        let name: String
        let material: String?
        let geometryType: Int
        
        init(name: String, material: String?, geometryType: Int) {
            self.name = name
            self.material = material
            self.geometryType = geometryType
        }
        
        required init?(coder: NSCoder) {
            if let s = coder.decodeObject(forKey: "name") as? String {
                self.name = s
            } else {
                return nil
            }
            self.material = coder.decodeObject(forKey: "material") as? String
            self.geometryType = coder.decodeInteger(forKey: "geometryType")
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(self.name, forKey: "name")
            coder.encode(self.material, forKey: "material")
            coder.encode(self.geometryType, forKey: "geometryType")
        }
        
        var imageName: String {
            switch self.geometryType {
            case 0: return "3d_point"
            case 1: return "3d_line"
            case 2: return "3d_triangle"
            case 3: return "3d_triangle_stripe"
            case 4: return "3d_quads"
            case 5: return "3d_variable" 
            default:
                return "3d"
            }
        }
    }
    
    class Mesh {
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
        
        required init?(coder: NSCoder) {
            if let s = coder.decodeObject(forKey: "name") as? String {
                self.name = s
            } else {
                return nil
            }
            self.vertexCount = coder.decodeInteger(forKey: "vertexCount")
            self.hasNormals = coder.decodeBool(forKey: "hasNormals")
            self.hasTangent = coder.decodeBool(forKey: "hasTangent")
            self.hasTextureCoordinate = coder.decodeBool(forKey: "hasTextureCoordinate")
            self.hasVertexColor = coder.decodeBool(forKey: "hasVertexColor")
            self.hasOcclusion = coder.decodeBool(forKey: "hasOcclusion")
            
            self.meshes = []
            let n = coder.decodeInteger(forKey: "submeshesCount")
            for i in 0 ..< n {
                if let data = coder.decodeObject(forKey: "submesh_\(i)") as? Data, let c = try? NSKeyedUnarchiver(forReadingFrom: data), let m = SubMesh(coder: c) {
                    meshes.append(m)
                }
            }
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(name, forKey: "name")
            
            coder.encode(vertexCount, forKey: "vertexCount")
            
            coder.encode(hasNormals, forKey: "hasNormals")
            coder.encode(hasTangent, forKey: "hasTangent")
            coder.encode(hasTextureCoordinate, forKey: "hasTextureCoordinate")
            coder.encode(hasVertexColor, forKey: "hasVertexColor")
            coder.encode(hasOcclusion, forKey: "hasOcclusion")
            
            coder.encode(self.meshes.count, forKey: "submeshesCount")
            for (i,m) in self.meshes.enumerated() {
                let c = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
                m.encode(with: c)
                coder.encode(c.encodedData, forKey: "submesh_\(i)")
            }
        }
    }
    
    let file: URL
    let fileSize: Int64
    
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
    
    
    init(file: URL, meshes: [Mesh]) {
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        
        self.meshes = meshes
        super.init()
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        
        self.meshes = []
        let n = coder.decodeInteger(forKey: "meshCount")
        for i in 0 ..< n {
            if let data = coder.decodeObject(forKey: "mesh_\(i)") as? Data, let c = try? NSKeyedUnarchiver(forReadingFrom: data), let m = Mesh(coder: c) {
                self.meshes.append(m)
            }
        }
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        coder.encode(self.meshes.count, forKey: "meshCount")
        for (i, m) in self.meshes.enumerated() {
            let c = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
            m.encode(with: c)
            coder.encode(c.encodedData, forKey: "mesh_\(i)")
        }
        
        super.encode(with: coder)
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.modelsMenuItems, image: self.getImage(for: "3d"), withSettings: settings)
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        let template = "[[mesh]], [[vertex]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled)
        return isFilled ? title : ""
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        switch placeholder {
            
        case "[[mesh-count]]":
            return format(value: values?["meshes"] ?? self.meshes, isFilled: &isFilled) { v, isFilled in
                guard let mesh = v as? [Mesh] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let n = mesh.count
                isFilled = n > 0
                if n == 0 && !useEmptyData {
                    return ""
                }
                if n == 1 {
                    return NSLocalizedString("1 Mesh", tableName: "LocalizableExt", comment: "")
                } else {
                    return String(format: NSLocalizedString("%d Meshes", tableName: "LocalizableExt", comment: ""), n)
                }
            }
        case "[[vertex]]":
            return format(value: values?["vertex"] ?? self.vertexCount, isFilled: &isFilled) { v, isFilled in
                guard let vertex = v as? Int else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = vertex > 0
                if vertex == 0 && !useEmptyData {
                    return ""
                }
                return String(format: NSLocalizedString("%@ Vertices", tableName: "LocalizableExt", comment: ""), Self.numberFormatter.string(from: NSNumber(value: vertex)) ?? "\(vertex)")
            }
        case "[[normals]]":
            return format(value: values?["normals"] ?? self.hasNormals, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Bool else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v
                return NSLocalizedString(v ? "with normals" : "without normals", tableName: "LocalizableExt", comment: "")
            }
        case "[[tangents]]":
            return format(value: values?["tangents"] ?? self.hasTangent, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Bool else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v
                return NSLocalizedString(v ? "with tangents" : "without tangents", tableName: "LocalizableExt", comment: "")
            }
        case "[[tex-coords]]":
            return format(value: values?["tex-coords"] ?? self.hasTextureCoordinate, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Bool else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v
                return NSLocalizedString(v ? "with texture coordinates" : "without texture coordinates", tableName: "LocalizableExt", comment: "")
            }
        case "[[vertex-color]]":
            return format(value: values?["vertex-color"] ?? self.hasVertexColor, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Bool else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v
                return NSLocalizedString(v ? "with vertex colors" : "without vertex colors", tableName: "LocalizableExt", comment: "")
            }
        case "[[occlusion]]":
            return format(value: values?["occlusion"] ?? self.hasOcclusion, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Bool else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v
                return NSLocalizedString(v ? "with occlusion" : "without occlusion", tableName: "LocalizableExt", comment: "")
            }
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template == "[[meshes]]" {
            guard !self.meshes.isEmpty else {
                return true
            }
            let n = self.meshes.count
            let title = n == 1 ? NSLocalizedString("1 Mesh", tableName: "LocalizableExt", comment: "") : String(format: NSLocalizedString("%d Meshes", comment: ""), n)
            let mnu = self.createMenuItem(title: title, image: "3D", settings: settings)
            let submenu = NSMenu(title: title)
            for mesh in self.meshes {
                let mesh_menu = n > 1 ? NSMenu() : submenu
                
                let m = createMenuItem(title: mesh.name.isEmpty ? mesh.name : "Mesh", image: mesh.meshes.first?.imageName, settings: settings)
                submenu.addItem(m)
                
                let t = String(format: NSLocalizedString("%@ Vertices", tableName: "LocalizableExt", comment: ""), Self.numberFormatter.string(from: NSNumber(value: mesh.vertexCount)) ?? "\(mesh.vertexCount)")
                mesh_menu.addItem(createMenuItem(title: t, image: nil, settings: settings))
                mesh_menu.addItem(NSMenuItem.separator())
                if mesh.hasNormals {
                    mesh_menu.addItem(createMenuItem(title: "with normals", image: "3d_normal", settings: settings))
                }
                if mesh.hasTangent {
                    mesh_menu.addItem(createMenuItem(title: "with tangents", image: "3d_tangent", settings: settings))
                }
                if mesh.hasVertexColor {
                    mesh_menu.addItem(createMenuItem(title: "with vertex colors", image: "3d_color", settings: settings))
                }
                if mesh.hasTextureCoordinate {
                    mesh_menu.addItem(createMenuItem(title: "with texture coordinates", image: "3d_uv", settings: settings))
                }
                if mesh.hasOcclusion {
                    mesh_menu.addItem(createMenuItem(title: "with occlusion", image: "3d_occlusion", settings: settings))
                }
                
                if n > 1 {
                    submenu.setSubmenu(mesh_menu, for: m)
                }
            }
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(submenu, for: mnu)
            
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}
