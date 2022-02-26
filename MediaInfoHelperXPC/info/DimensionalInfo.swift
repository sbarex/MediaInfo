//
//  DimensionalInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 24/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

// MARK: - DimensionalInfo
enum Orientation {
    case landscape
    case portrait
}

enum DimensionCodingKeys: String, CodingKey {
    case width
    case height
}

protocol DimensionalInfo: BaseInfo {
    static func getRatio(width: Int, height: Int, approximate: Bool) -> String?
    static func getResolutioName(width: Int, height: Int)->String?
    
    var unit: String { get }
    
    var width: Int { get }
    var height: Int { get }
    
    var orientation: Orientation { get }
    var isLandscape: Bool { get }
    var isPortrait: Bool  { get }
    
    var resolutionName: String? { get }
    
    func encodeDimension(to encoder: Encoder) throws
    static func decodeDimension(from decoder: Decoder) throws -> (width: Int, height: Int)
    
    func getRatio(approximate: Bool) -> String?
    func processDimensionPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String
    func getDimensionImage(for name: String) -> String?
}

extension DimensionalInfo {
    static func getRatio(width: Int, height: Int, approximate: Bool) -> String? {
        var gcd = Int.gcd(width, height)
        guard gcd != 1 else {
            return nil
        }
            
        var circa = false
        if approximate, gcd < 8, let gcd1 = [Int.gcd(width+1, height), Int.gcd(width-1, height), Int.gcd(width, height+1), Int.gcd(width, height-1)].max(), gcd1 > gcd {
            gcd = gcd1 * Int.gcd(width/gcd1, height / gcd1)
            circa = true
        }
        let w = width / gcd
        let h = height / gcd
        
        guard w <= 30 && h <= 30 else {
            return nil
        }
        
        return "\(circa ? "~ " : "")\(w) : \(h)"
    }
    
    static func getResolutioName(width: Int, height: Int)->String? {
        let resolutions = [
            // Narrowscreen 4:3 computer display resolutions
            "MCGA": [320, 200],
            "QVGA" : [320, 240],
            "VGA" : [640, 480],
            "Super VGA" : [800, 600],
            "XGA" : [1024, 768],
            "SXGA" : [1280, 1024],
            "UXGA" : [1600, 1200],
            
            // Analog
            "CRT monitors": [320, 200],
            "Video CD": [352, 240],
            "VHS": [333, 480],
            "Betamax": [350, 480],
            "Super Betamax": [420, 480],
            "Betacam SP": [460, 480],
            "Super VHS": [580, 480],
            "Enhanced Definition Betamax": [700, 480],
            
            // Digital
            "Digital8": [500, 480],
            "NTSC DV": [720, 480],
            "NTSC D1": [720, 486],
            "NTSC D1 Square pixel": [720, 543],
            "NTSC D1 Widescreen Square Pixel": [782, 486],
            
            "EDTV (Enhanced Definition Television)": [854, 480],
            "D-VHS, DVD, miniDV, Digital8, Digital Betacam (PAL/SECAM)": [720, 576],
            "PAL D1/DV": [720, 576],
            "PAL D1/DV Square pixel": [788, 576],
            "PAL D1/DV Widescreen Square pixel": [1050, 576],
            
            
            "HDV/HDTV 720": [1280, 720],
            "HDTV 1080": [1440, 1080],
            "DVCPRO HD 720": [960, 720],
            "DVCPRO HD 1080": [1440, 1080],
            
            "HDTV 1080 (FullHD)": [1920, 1080],
            
            // "HDV (miniDV), AVCHD, HD DVD, Blu-ray, HDCAM SR": [1920, 1080],
            "2K Flat (1.85:1)": [1998, 1080],
            "UHD 4K": [3840, 2160],
            "UHD 8K": [7680, 4320],
            "Cineon Half": [1828, 1332],
            "Cineon Full": [3656, 2664],
            "Film (2K)": [2048, 1556],
            "Film (4K)": [4096, 3112],
            "Digital Cinema (2K)": [2048, 1080],
            "Digital Cinema (4K)": [4096, 2160],
            "Digital Cinema (16K)": [15360, 8640],
            "Digital Cinema (64K)": [61440, 34560],
        ]
        return resolutions.first(where: { $1[0] == width && $1[1] == height })?.key
    }
    
    var orientation: Orientation {
        return width < height ? .portrait : .landscape
    }
    var isLandscape: Bool {
        return orientation == .landscape
    }
    var isPortrait: Bool {
        return orientation == .portrait
    }
    
    var resolutionName: String? {
        return Self.getResolutioName(width: max(width, height), height: min(width, height))
    }
    
    func encodeDimension(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DimensionCodingKeys.self)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
    }
    
    static func decodeDimension(from decoder: Decoder) throws -> (width: Int, height: Int) {
        let container = try decoder.container(keyedBy: DimensionCodingKeys.self)
        let width = try container.decode(Int.self, forKey: .width)
        let height = try container.decode(Int.self, forKey: .height)
        return (width: width, height: height)
    }
    
    func getRatio(approximate: Bool) -> String? {
        return Self.getRatio(width: width, height: height, approximate: approximate)
    }
    
    func processDimensionPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        switch placeholder {
        case "[[size]]":
            isFilled = true
            if let w = Self.numberFormatter.string(from: NSNumber(integerLiteral: width)), let h = Self.numberFormatter.string(from: NSNumber(integerLiteral: height)) {
               return "\(w) × \(h) \(self.unit)"
           } else {
               return "\(width) × \(height) \(self.unit)"
           }
        case "[[width]]":
            if let w = Self.numberFormatter.string(from: NSNumber(integerLiteral: width)) {
                return "\(w) \(self.unit)"
            } else {
                return "\(width)"
            }
        case "[[height]]":
            if let h = Self.numberFormatter.string(from: NSNumber(integerLiteral: height)) {
                    return "\(h) \(self.unit)"
            } else {
                return "\(width)"
            }
        case "[[ratio]]":
            guard let ratio = Self.getRatio(width: width, height: height, approximate: !settings.isRatioPrecise) else {
                isFilled = false
                return ""
            }
            isFilled = true
            return ratio
        case "[[resolution]]":
            isFilled = true
            return Self.getResolutioName(width: width, height: height) ?? ""
        default:
            isFilled = false
            return ""
        }
    }
    
    func getDimensionImage(for name: String) -> String? {
        var image: String
        switch name {
        case "image":
            image = self.isPortrait ? "image_v" : "image"
        case "video":
            image = isPortrait ? "video_v" : "video"
        case "ratio":
            image = isPortrait ? "ratio_v" : "ratio"
        case "page":
            image = isPortrait ? "page_v" : "page"
        case "artbox":
            image = self.isPortrait ? "artbox_v" : "artbox"
        case "bleed":
            image = self.isPortrait ? "bleed_v" : "bleed"
        case "pdf":
            image = self.isPortrait ? "pdf_v" : "pdf"
        default:
            return nil
        }
        return image
    }
}
