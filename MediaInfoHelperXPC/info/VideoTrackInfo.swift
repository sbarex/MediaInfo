//
//  VideoTrackInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 26/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Cocoa

class VideoTrackInfo: BaseInfo, DimensionalInfo, LanguageInfo, DurationInfo, CodecInfo {
    enum CodingKeys: String, CodingKey {
        case duration
        case startTime
        case codecShortName
        case codecLongName
        case profile
        case pixelFormat
        case pixelFormatLabel
        case fieldOrder
        case fieldOrderLabel
        case colorSpace
        case colorSpaceLabel
        case lang
        case langFlag
        case bitRate
        case frames
        case fps
        case title
        case encoder
        case isLossless
    }
    
    enum VideoColorSpace: Int {
        case gbr
        case bt709
        case unknown
        case reserved
        case fcc
        case bt470bg
        case smpte170m
        case smpte240m
        case ycgco
        case bt2020nc
        case bt2020c
        case smpte2085
        case chroma_derived_nc
        case chroma_derived_c
        case ictcp
        
        var label: String {
            switch self {
            case .gbr: return "gbr"
            case .bt709: return "bt709"
            case .unknown: return "unknown"
            case .reserved: return "reserved"
            case .fcc: return "fcc"
            case .bt470bg: return "bt470bg"
            case .smpte170m: return "smpte170m"
            case .smpte240m: return "smpte240m"
            case .ycgco: return "ycgco"
            case .bt2020nc: return "bt2020nc"
            case .bt2020c: return "bt2020c"
            case .smpte2085: return "smpte2085"
            case .chroma_derived_nc: return "chroma derived nc"
            case .chroma_derived_c: return "chroma derived c"
            case .ictcp: return "ictcp"
            }
        }
    }
    enum VideoPixelFormat: Int {
        case yuv420p
        case yuyv422
        case yvyu422
        case y210le
        case y210be
        case rgb24
        case bgr24
        case x2rgb10le
        case x2rgb10be
        case yuv422p
        case yuv444p
        case yuv410p
        case yuv411p
        case yuvj411p
        case gray
        case monow
        case monob
        case pal8
        case yuvj420p
        case yuvj422p
        case yuvj444p
        case xvmc
        case uyvy422
        case uyyvyy411
        case bgr8
        case bgr4
        case bgr4_byte
        case rgb8
        case rgb4
        case rgb4_byte
        case nv12
        case nv21
        case argb
        case rgba
        case abgr
        case bgra
        case zero_rgb
        case rgb0
        case zero_bgr
        case bgr0
        case gray9be
        case gray9le
        case gray10be
        case gray10le
        case gray12be
        case gray12le
        case gray14be
        case gray14le
        case gray16be
        case gray16le
        case yuv440p
        case yuvj440p
        case yuv440p10le
        case yuv440p10be
        case yuv440p12le
        case yuv440p12be
        case yuva420p
        case yuva422p
        case yuva444p
        case yuva420p9be
        case yuva420p9le
        case yuva422p9be
        case yuva422p9le
        case yuva444p9be
        case yuva444p9le
        case yuva420p10be
        case yuva420p10le
        case yuva422p10be
        case yuva422p10le
        case yuva444p10be
        case yuva444p10le
        case yuva420p16be
        case yuva420p16le
        case yuva422p16be
        case yuva422p16le
        case yuva444p16be
        case yuva444p16le
        case rgb48be
        case rgb48le
        case rgba64be
        case rgba64le
        case rgb565be
        case rgb565le
        case rgb555be
        case rgb555le
        case rgb444be
        case rgb444le
        case bgr48be
        case bgr48le
        case bgra64be
        case bgra64le
        case bgr565be
        case bgr565le
        case bgr555be
        case bgr555le
        case bgr444be
        case bgr444le
        case vaapi
        case yuv420p9le
        case yuv420p9be
        case yuv420p10le
        case yuv420p10be
        case yuv420p12le
        case yuv420p12be
        case yuv420p14le
        case yuv420p14be
        case yuv420p16le
        case yuv420p16be
        case yuv422p9le
        case yuv422p9be
        case yuv422p10le
        case yuv422p10be
        case yuv422p12le
        case yuv422p12be
        case yuv422p14le
        case yuv422p14be
        case yuv422p16le
        case yuv422p16be
        case yuv444p16le
        case yuv444p16be
        case yuv444p10le
        case yuv444p10be
        case yuv444p9le
        case yuv444p9be
        case yuv444p12le
        case yuv444p12be
        case yuv444p14le
        case yuv444p14be
        case d3d11va_vld
        case dxva2_vld
        case ya8
        case ya16le
        case ya16be
        case videotoolbox_vld
        case gbrp
        case gbrp9le
        case gbrp9be
        case gbrp10le
        case gbrp10be
        case gbrp12le
        case gbrp12be
        case gbrp14le
        case gbrp14be
        case gbrp16le
        case gbrp16be
        case gbrap
        case gbrap16le
        case gbrap16be
        case vdpau
        case xyz12le
        case xyz12be
        
        var label: String {
            switch self {
            case .yuv420p: return "yuv420p"
            case .yuyv422: return "yuyv422"
            case .yvyu422: return "yvyu422"
            case .y210le: return "y210le"
            case .y210be: return "y210be"
            case .rgb24: return "rgb24"
            case .bgr24: return "bgr24"
            case .x2rgb10le: return "x2rgb10le"
            case .x2rgb10be: return "x2rgb10be"
            case .yuv422p: return "yuv422p"
            case .yuv444p: return "yuv444p"
            case .yuv410p: return "yuv410p"
            case .yuv411p: return "yuv411p"
            case .yuvj411p: return "yuvj411p"
            case .gray: return "gray"
            case .monow: return "monow"
            case .monob: return "monob"
            case .pal8: return "pal8"
            case .yuvj420p: return "yuvj420p"
            case .yuvj422p: return "yuvj422p"
            case .yuvj444p: return "yuvj444p"
            case .xvmc: return "xvmc"
            case .uyvy422: return "uyvy422"
            case .uyyvyy411: return "uyyvyy411"
            case .bgr8: return "bgr8"
            case .bgr4: return "bgr4"
            case .bgr4_byte: return "bgr4_byte"
            case .rgb8: return "rgb8"
            case .rgb4: return "rgb4"
            case .rgb4_byte: return "rgb4_byte"
            case .nv12: return "nv12"
            case .nv21: return "nv21"
            case .argb: return "argb"
            case .rgba: return "rgba"
            case .abgr: return "abgr"
            case .bgra: return "bgra"
            case .zero_rgb: return "0rgb"
            case .rgb0: return "rgb0"
            case .zero_bgr: return "0bgr"
            case .bgr0: return "bgr0"
            case .gray9be: return "gray9be"
            case .gray9le: return "gray9le"
            case .gray10be: return "gray10be"
            case .gray10le: return "gray10le"
            case .gray12be: return "gray12be"
            case .gray12le: return "gray12le"
            case .gray14be: return "gray14be"
            case .gray14le: return "gray14le"
            case .gray16be: return "gray16be"
            case .gray16le: return "gray16le"
            case .yuv440p: return "yuv440p"
            case .yuvj440p: return "yuvj440p"
            case .yuv440p10le: return "yuv440p10le"
            case .yuv440p10be: return "yuv440p10be"
            case .yuv440p12le: return "yuv440p12le"
            case .yuv440p12be: return "yuv440p12be"
            case .yuva420p: return "yuva420p"
            case .yuva422p: return "yuva422p"
            case .yuva444p: return "yuva444p"
            case .yuva420p9be: return "yuva420p9be"
            case .yuva420p9le: return "yuva420p9le"
            case .yuva422p9be: return "yuva422p9be"
            case .yuva422p9le: return "yuva422p9le"
            case .yuva444p9be: return "yuva444p9be"
            case .yuva444p9le: return "yuva444p9le"
            case .yuva420p10be: return "yuva420p10be"
            case .yuva420p10le: return "yuva420p10le"
            case .yuva422p10be: return "yuva422p10be"
            case .yuva422p10le: return "yuva422p10le"
            case .yuva444p10be: return "yuva444p10be"
            case .yuva444p10le: return "yuva444p10le"
            case .yuva420p16be: return "yuva420p16be"
            case .yuva420p16le: return "yuva420p16le"
            case .yuva422p16be: return "yuva422p16be"
            case .yuva422p16le: return "yuva422p16le"
            case .yuva444p16be: return "yuva444p16be"
            case .yuva444p16le: return "yuva444p16le"
            case .rgb48be: return "rgb48be"
            case .rgb48le: return "rgb48le"
            case .rgba64be: return "rgba64be"
            case .rgba64le: return "rgba64le"
            case .rgb565be: return "rgb565be"
            case .rgb565le: return "rgb565le"
            case .rgb555be: return "rgb555be"
            case .rgb555le: return "rgb555le"
            case .rgb444be: return "rgb444be"
            case .rgb444le: return "rgb444le"
            case .bgr48be: return "bgr48be"
            case .bgr48le: return "bgr48le"
            case .bgra64be: return "bgra64be"
            case .bgra64le: return "bgra64le"
            case .bgr565be: return "bgr565be"
            case .bgr565le: return "bgr565le"
            case .bgr555be: return "bgr555be"
            case .bgr555le: return "bgr555le"
            case .bgr444be: return "bgr444be"
            case .bgr444le: return "bgr444le"
            case .vaapi: return "vaapi"
            case .yuv420p9le: return "yuv420p9le"
            case .yuv420p9be: return "yuv420p9be"
            case .yuv420p10le: return "yuv420p10le"
            case .yuv420p10be: return "yuv420p10be"
            case .yuv420p12le: return "yuv420p12le"
            case .yuv420p12be: return "yuv420p12be"
            case .yuv420p14le: return "yuv420p14le"
            case .yuv420p14be: return "yuv420p14be"
            case .yuv420p16le: return "yuv420p16le"
            case .yuv420p16be: return "yuv420p16be"
            case .yuv422p9le: return "yuv422p9le"
            case .yuv422p9be: return "yuv422p9be"
            case .yuv422p10le: return "yuv422p10le"
            case .yuv422p10be: return "yuv422p10be"
            case .yuv422p12le: return "yuv422p12le"
            case .yuv422p12be: return "yuv422p12be"
            case .yuv422p14le: return "yuv422p14le"
            case .yuv422p14be: return "yuv422p14be"
            case .yuv422p16le: return "yuv422p16le"
            case .yuv422p16be: return "yuv422p16be"
            case .yuv444p16le: return "yuv444p16le"
            case .yuv444p16be: return "yuv444p16be"
            case .yuv444p10le: return "yuv444p10le"
            case .yuv444p10be: return "yuv444p10be"
            case .yuv444p9le: return "yuv444p9le"
            case .yuv444p9be: return "yuv444p9be"
            case .yuv444p12le: return "yuv444p12le"
            case .yuv444p12be: return "yuv444p12be"
            case .yuv444p14le: return "yuv444p14le"
            case .yuv444p14be: return "yuv444p14be"
            case .d3d11va_vld: return "d3d11va_vld"
            case .dxva2_vld: return "dxva2_vld"
            case .ya8: return "ya8"
            case .ya16le: return "ya16le"
            case .ya16be: return "ya16be"
            case .videotoolbox_vld: return "videotoolbox_vld"
            case .gbrp: return "gbrp"
            case .gbrp9le: return "gbrp9le"
            case .gbrp9be: return "gbrp9be"
            case .gbrp10le: return "gbrp10le"
            case .gbrp10be: return "gbrp10be"
            case .gbrp12le: return "gbrp12le"
            case .gbrp12be: return "gbrp12be"
            case .gbrp14le: return "gbrp14le"
            case .gbrp14be: return "gbrp14be"
            case .gbrp16le: return "gbrp16le"
            case .gbrp16be: return "gbrp16be"
            case .gbrap: return "gbrap"
            case .gbrap16le: return "gbrap16le"
            case .gbrap16be: return "gbrap16be"
            case .vdpau: return "vdpau"
            case .xyz12le: return "xyz12le"
            case .xyz12be: return "xyz12be"
            }
        }
    }
    enum VideoFieldOrder: Int {
        case topFirst
        case bottomFirst
        case topFirstSwapped
        case bottomFirstSwapped
        case unknown
        case progressive
        
        var label: String {
            switch self {
            case .topFirst: return "top first"
            case .bottomFirst: return "bottom first"
            case .topFirstSwapped: return "top coded first (swapped)"
            case .bottomFirstSwapped: return "bottom coded first (swapped)"
            case .unknown: return "unknown"
            case .progressive: return "progressive"
            }
        }
    }

    let start_time: Double
    let duration: Double
    let codec_short_name: String
    let codec_long_name: String?
    let profile: String?
    let pixel_format: VideoPixelFormat?
    let field_order: VideoFieldOrder?
    let color_space: VideoColorSpace?
    
    let lang: String?
    lazy var flagImage: NSImage? = {
        return self.getImageOfFlag()
    }()
    let bitRate: Int64
    let fps: Double
    let frames: Int
    let title: String?
    let encoder: String?
    let isLossless: Bool?
    
    let width: Int
    let height: Int
    let unit: String = "px"
    
    override class var infoType: Settings.SupportedFile { return .videoTrakcs }
    override var standardMainItem: MenuItemInfo {
        var template = "[[size]], [[duration]]"
        if self.fps > 0 {
            template += " [[fps]]"
        }
        if self.bitRate > 0 {
            template += ", [[bitrate]]"
        }
        if !self.codec_short_name.isEmpty {
            template += " ([[codec]])"
        }
        template += " [[language-flag]]"
        
        return MenuItemInfo(fileType: .videoTrakcs, index: -1, item: Settings.MenuItem(image: "video", template: template))
    }
    
    init(
        width: Int, height: Int,
        duration: Double, start_time: Double,
        codec_short_name: String, codec_long_name: String?, profile: String?,
        pixel_format: VideoPixelFormat?, color_space: VideoColorSpace?, field_order: VideoFieldOrder?,
        lang: String?,
        bitRate: Int64, fps: Double, frames: Int,
        title: String?, encoder: String?,
        isLossless: Bool?
    ) {
        self.duration = duration
        self.start_time = start_time
        self.codec_short_name = codec_short_name
        self.codec_long_name = codec_long_name
        self.profile = profile
        self.pixel_format = pixel_format
        self.field_order = field_order
        self.color_space = color_space
        
        self.lang = lang
        self.bitRate = bitRate
        self.frames = frames
        self.fps = fps
        
        self.title = title
        self.encoder = encoder
        
        self.isLossless = isLossless
        
        self.width = width
        self.height = height
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let dim = try Self.decodeDimension(from: decoder)
        width = dim.width
        height = dim.height
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Double.self, forKey: .duration)
        self.start_time = try container.decode(Double.self, forKey: .startTime)
        self.codec_short_name = try container.decode(String.self, forKey: .codecShortName)
        self.codec_long_name = try container.decode(String?.self, forKey: .codecLongName)
        self.profile = try container.decode(String?.self, forKey: .profile)
        if let i = try container.decode(Int?.self, forKey: .pixelFormat) {
            self.pixel_format = VideoPixelFormat(rawValue: i)
        } else {
            self.pixel_format = nil
        }
        if let i = try container.decode(Int?.self, forKey: .fieldOrder) {
            self.field_order = VideoFieldOrder(rawValue: i)
        } else {
            self.field_order = nil
        }
        if let i = try container.decode(Int?.self, forKey: .colorSpace) {
            self.color_space = VideoColorSpace(rawValue: i)
        } else {
            self.color_space = nil
        }
        self.lang = try container.decode(String?.self, forKey: .lang)
        self.bitRate = try container.decode(Int64.self, forKey: .bitRate)
        self.frames = try container.decode(Int.self, forKey: .frames)
        self.fps = try container.decode(Double.self, forKey: .fps)
        self.title = try container.decode(String?.self, forKey: .title)
        self.encoder = try container.decode(String?.self, forKey: .encoder)
        self.isLossless = try container.decode(Bool?.self, forKey: .isLossless)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeDimension(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.duration, forKey: .duration)
        try container.encode(self.start_time, forKey: .startTime)
        try container.encode(self.codec_short_name, forKey: .codecShortName)
        try container.encode(self.codec_long_name, forKey: .codecLongName)
        try container.encode(self.profile, forKey: .profile)
        try container.encode(self.pixel_format?.rawValue, forKey: .pixelFormat)
        try container.encode(self.field_order?.rawValue, forKey: .fieldOrder)
        try container.encode(self.color_space?.rawValue, forKey: .colorSpace)
        try container.encode(self.lang, forKey: .lang)
        try container.encode(self.bitRate, forKey: .bitRate)
        try container.encode(self.frames, forKey: .frames)
        try container.encode(self.fps, forKey: .fps)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.encoder, forKey: .encoder)
        try container.encode(self.isLossless, forKey: .isLossless)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.pixel_format?.label, forKey: .pixelFormatLabel)
            try container.encode(self.field_order?.label, forKey: .fieldOrderLabel)
            try container.encode(self.color_space?.label, forKey: .colorSpaceLabel)
            try container.encode(self.getCountryFlag(), forKey: .langFlag)
        }
    }
    
    override func getImage(for name: String) -> NSImage? {
        if let image = self.getDimensionImage(for: name) {
            return super.getImage(for: image)
        } else if name == "flag", let img = self.flagImage {
            return img
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        if let s = self.processVideoPlaceholder(placeholder, isFilled: &isFilled, forItem: item) {
            return s
        } else {
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
    
    internal func processVideoPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String? {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[duration]]", "[[seconds]]", "[[bitrate]]", "[[start-time]]", "[[start-time-s]]":
            return processDurationPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        case "[[frames]]":
            isFilled = true
            let s = Self.numberFormatter.string(from: NSNumber(value: frames)) ?? "\(frames)"
            return String(format: NSLocalizedString("%@ frames", tableName: "LocalizableExt", comment: ""), s)
        case "[[fps]]":
            isFilled = fps > 0
            if fps == 0 {
                return self.formatND(useEmptyData: useEmptyData)
            } else {
                let s = Self.numberFormatter.string(from: NSNumber(floatLiteral: fps)) ?? "\(fps)"
                return String(format: NSLocalizedString("%@ fps", tableName: "LocalizableExt", comment: ""), s)
            }
        case "[[profile]]":
            isFilled = !(self.profile?.isEmpty ?? true)
            return self.profile ?? self.formatND(useEmptyData: useEmptyData)
        case "[[field-order]]":
            isFilled = self.field_order != nil
            return self.field_order?.label ?? self.formatND(useEmptyData: useEmptyData)
        case "[[pixel-format]]":
            isFilled = self.pixel_format != nil
            return self.pixel_format?.label ?? self.formatND(useEmptyData: useEmptyData)
        case "[[color-space]]":
            isFilled = self.color_space != nil
            return self.color_space?.label ?? self.formatND(useEmptyData: useEmptyData)
        case "[[title]]":
            isFilled = !(self.title?.isEmpty ?? true)
            return self.title ?? self.formatND(useEmptyData: useEmptyData)
        case "[[codec]]", "[[codec-long]]", "[[codec-short]]", "[[compression]]", "[[encoder]]":
            return self.processPlaceholderCodec(placeholder, isFilled: &isFilled, forItem: item)
        case "[[language]]", "[[language-flag]]":
            return processLanguagePlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        case "[[size]]", "[[width]]", "[[height]]", "[[ratio]]", "[[resolution]]", "[[pixel-count]]", "[[mega-pixel]]":
            return self.processDimensionPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        default:
            return nil
        }
    }
}
