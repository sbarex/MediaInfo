//
//  ModelInfo+ext.swift
//  MediaInfo Helper XPC
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

import ModelIO

extension ModelInfo {
    convenience init?(parseModel file: URL) {
        guard MDLAsset.canImportFileExtension(file.pathExtension) else {
            return nil
        }
        
        let asset = MDLAsset(url: file)
        
        var meshes: [Mesh] = []
        
        for object in asset.childObjects(of: MDLMesh.self) {
            guard let object = object as? MDLMesh else {
                continue
            }
            
            let hasVertexColor = object.vertexDescriptor.attributeNamed(MDLVertexAttributeColor) != nil
            let hasNormals = object.vertexDescriptor.attributeNamed(MDLVertexAttributeNormal) != nil
            let hasTangent = object.vertexDescriptor.attributeNamed(MDLVertexAttributeTangent) != nil
            let hasTextureCoordinate = object.vertexDescriptor.attributeNamed(MDLVertexAttributeTextureCoordinate) != nil
            let hasOcclusion = object.vertexDescriptor.attributeNamed(MDLVertexAttributeOcclusionValue) != nil
            
            let m = Mesh(name: object.name, vertexCount: object.vertexCount, hasNormals: hasNormals, hasTangent: hasTangent, hasTextureCoordinate: hasTextureCoordinate, hasVertexColor: hasVertexColor, hasOcclusion: hasOcclusion)
            if let meshes = object.submeshes, meshes.count > 0 {
                for m1 in meshes {
                    guard let m1 = m1 as? MDLSubmesh else {
                        continue
                    }
                    let subMesh = SubMesh(name: m1.name, material: m1.material?.name, geometryType: m1.geometryType.rawValue)
                    m.meshes.append(subMesh)
                    print(m1)
                }
            }
            meshes.append(m)
        }
        
        guard !meshes.isEmpty else {
            return nil
        }
        
        for a in asset.vertexDescriptor?.attributes as? [MDLVertexAttribute] ?? [] {
            let s = a.name
            print(s)
        }
        
        self.init(file: file, meshes: meshes)
    }
}
