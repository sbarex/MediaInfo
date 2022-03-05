//
//  NSMenuItem+ext.swift
//  MediaInfo
//
//  Created by Simone Baldissini on 15/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import AppKit

extension NSMenuItem: Encodable {
    enum CodingKeys: String, CodingKey {
        case title
        case tag
        // case image
        case enabled
        case state
        case indentationLevel
        case items
        case parent
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.title, forKey: .title)
        try container.encode(self.tag, forKey: .tag)
        try container.encode(self.isEnabled, forKey: .enabled)
        try container.encode(self.state.rawValue, forKey: .state)
        try container.encode(self.indentationLevel, forKey: .indentationLevel)
        try container.encode(self.submenu?.items, forKey: .items)
        // try container.encode(self.parent, forKey: .parent)
    }
}
