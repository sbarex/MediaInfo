//
//  ImageVideoInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 26/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Cocoa

class ImageVideoInfo: FileInfo, DimensionalInfo, CodecInfo {
    enum CodingKeys: String, CodingKey {
        case codecShortName
        case codecLongName
        case isLossless
        case encoder
    }

    var width: Int
    var height: Int
    let unit = "px"
    
    let codec_short_name: String
    let codec_long_name: String?
    
    let isLossless: Bool?
    let encoder: String?
    
    override var infoType: Settings.SupportedFile { return .image }
    
    init(file: URL, width: Int, height: Int, codec_short_name: String, codec_long_name: String?, isLossless: Bool?, encoder: String?) {
        self.codec_short_name = codec_short_name
        self.codec_long_name = codec_long_name
        self.isLossless = isLossless
        self.encoder = encoder
        self.width = width
        self.height = height
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let dim = try Self.decodeDimension(from: decoder)
        self.width = dim.width
        self.height = dim.height
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.codec_short_name = try container.decode(String.self, forKey: .codecShortName)
        self.codec_long_name = try container.decode(String?.self, forKey: .codecLongName)
        self.isLossless = try container.decode(Bool?.self, forKey: .isLossless)
        self.encoder = try container.decode(String?.self, forKey: .encoder)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeDimension(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.codec_short_name, forKey: .codecShortName)
        try container.encode(self.codec_long_name, forKey: .codecLongName)
        try container.encode(self.isLossless, forKey: .isLossless)
        try container.encode(self.encoder, forKey: .encoder)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if let image = self.getDimensionImage(for: name) {
            return super.getImage(for: image)
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        switch placeholder {
        case "[[codec]]", "[[codec-long]]", "[[codec-short]]", "[[compression]]", "[[encoder]]":
            return self.processPlaceholderCodec(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
        case "[[size]]", "[[width]]", "[[height]]", "[[ratio]]", "[[resolution]]":
            return self.processDimensionPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
        }
    }
}
