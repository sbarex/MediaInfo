//
//  InfoItems.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 11/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

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
    
// MARK: -

protocol LanguageInfo: BaseInfo {
    var lang: String? { get }
    
    func getCountryFlag() -> String?
    func processLanguagePlaceholder(_ placeholder: String, settings: Settings, values: [String: Any]?, isFilled: inout Bool) -> String
}

extension LanguageInfo {
    static func getCountryFlag(lang: String?) -> String? {
        guard let countryCode = lang, countryCode.count == 2 else {
            return nil
        }
        if countryCode.uppercased() == "EN" {
            return "🇺🇸"
        }
        return countryCode
            .uppercased()
            .unicodeScalars
            .map({ 127397 + $0.value })
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
    
    func getCountryFlag() -> String? {
        return Self.getCountryFlag(lang: self.lang)
    }
    
    func processLanguagePlaceholder(_ placeholder: String, settings: Settings, values: [String: Any]?, isFilled: inout Bool) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[language-count]]":
            return format(value: values?["language"] ?? self.lang, isFilled: &isFilled) { v, isFilled in
                if let v = v as? [String] {
                    let langs = v.filter({ !$0.isEmpty })
                    let n = langs.count
                    isFilled = n > 0
                    if n == 1 {
                        return "1 "+NSLocalizedString("language", tableName: "LocalizableExt", comment: "")
                    } else {
                        if n == 0 && !useEmptyData {
                            return ""
                        }
                        return "\(n) "+NSLocalizedString("languages", tableName: "LocalizableExt", comment: "")
                    }
                } else if let lang = v as? String {
                    isFilled = !lang.isEmpty
                    if isFilled {
                        return "1 "+NSLocalizedString("language", tableName: "LocalizableExt", comment: "")
                    } else if useEmptyData {
                        return "0 "+NSLocalizedString("languages", tableName: "LocalizableExt", comment: "")
                    } else {
                        return ""
                    }
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        case "[[language]]", "[[languages]]":
            return format(value: values?["language"] ?? self.lang, isFilled: &isFilled) { v, isFilled in
                if let v = v as? [String] {
                    let langs = v.filter({ !$0.isEmpty })
                    guard !langs.isEmpty else {
                        isFilled = false
                        return self.formatND(useEmptyData: useEmptyData)
                    }
                    isFilled = true
                    return langs.joined(separator: " ")
                } else if let lang = v as? String, !lang.isEmpty {
                    isFilled = true
                    return lang
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        case "[[language-flag]]", "[[languages-flag]]":
            return format(value: values?["language"] ?? self.lang, isFilled: &isFilled) { v, isFilled in
                if let langs = v as? [String] {
                    guard !langs.isEmpty else {
                        isFilled = false
                        return useEmptyData ? NSLocalizedString("🏳", tableName: "LocalizableExt", comment: "") : ""
                    }
                    var s: [String] = []
                    for lang in langs {
                        guard !lang.isEmpty else {
                            continue
                        }
                        if let flag = Self.getCountryFlag(lang: lang) {
                            s.append(flag)
                        } else {
                            s.append(lang)
                        }
                    }
                    if s.isEmpty {
                        isFilled = false
                        return useEmptyData ? NSLocalizedString("🏳", tableName: "LocalizableExt", comment: "") : ""
                    } else {
                        isFilled = true
                        return s.joined(separator: " ")
                    }
                } else {
                    guard let lang = v as? String else {
                        isFilled = false
                        return self.formatND(useEmptyData: useEmptyData)
                    }
                    guard !lang.isEmpty else {
                        isFilled = false
                        return useEmptyData ? NSLocalizedString("🏳", tableName: "LocalizableExt", comment: "") : ""
                    }
                    isFilled = true
                    if let flag = Self.getCountryFlag(lang: lang) {
                        return flag
                    } else {
                        return lang
                    }
                }
            }
        default:
            return placeholder
        }
    }
    
    static func getAvailableLanguageTokens() -> [String] {
        return [
            "[[language]]",
            "[[language-flag]]",
        ]
    }
}

// MARK: -
protocol DurationInfo: BaseInfo {
    var duration: Double { get }
    var bitRate: Int64 { get }
    var start_time: Double { get }
}

extension DurationInfo {
    func processDurationPlaceholder(_ placeholder: String, values: [String: Any]?, isFilled: inout Bool) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[duration]]":
            return format(value: values?["duration"] ?? self.duration, isFilled: &isFilled) { v, isFilled in
                if let duration = v as? Double {
                    isFilled = true
                    return TimeInterval(duration).formatTime()
                } else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
            }
        case "[[seconds]]":
            return format(value: values?["duration"] ?? self.duration, isFilled: &isFilled) { (v, isFilled) in
                guard let s = v as? Double else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = s > 0
                return (Self.numberFormatter.string(from: NSNumber(floatLiteral: s)) ?? "\(s)") + " s"
            }
        case "[[start-time]]":
            return format(value: values?["start-time"] ?? self.start_time, isFilled: &isFilled) { (v, isFilled) in
                guard let s = v as? Double else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = s > 0
                if s < 0 {
                    return self.formatND(useEmptyData: useEmptyData)
                } else {
                    return (Self.numberFormatter.string(from: NSNumber(floatLiteral: s)) ?? "\(s)") + " s"
                }
            }
        case "[[start-time-s]]":
            return format(value: values?["duration"] ?? self.start_time, isFilled: &isFilled) { v, isFilled in
                if let start_time = v as? Int64 {
                    isFilled = start_time > 0
                    if start_time < 0 {
                        return self.formatND(useEmptyData: useEmptyData)
                    } else {
                        return TimeInterval(Double(start_time)).formatTime()
                    }
                } else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
            }
        
        case "[[bitrate]]":
            return format(value: values?["bitrate"] ?? self.bitRate, isFilled: &isFilled) { v, isFilled in
                guard let v = v as? Int64 else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = v > 0
                if v > 0 {
                    return Self.byteCountFormatter.string(fromByteCount: v) + "/s"
                } else {
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        default:
            return placeholder
        }
    }
    
    static func getAvailableDurationTokens() -> [String] {
        return [
            "[[duration]]",
            "[[seconds]]",
            "[[bitrate]]",
        ]
    }
}

// MARK: -
protocol CodecInfo: BaseInfo {
    var codec_short_name: String { get }
    var codec_long_name: String? { get }
    
    var encoder: String? { get }
    var isLossless: Bool? { get }
    
    func processPlaceholderCodec(_ placeholder: String, settings: Settings, values: [String : Any]?, isFilled: inout Bool) -> String
}

extension CodecInfo {
    func processPlaceholderCodec(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[codec-short]]":
            let s = format(value: values?["codec-short-name"] ?? self.codec_short_name, isFilled: &isFilled) { v, isFilled in
                guard let s = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !s.isEmpty
                return s
            }
            return s
            
        case "[[codec-long]]":
            let s = format(value: values?["codec-long-name"] ?? self.codec_long_name ?? self.codec_short_name, isFilled: &isFilled) { v, isFilled in
                guard let s = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !s.isEmpty
                return s
            }
            
            if values?["codec-long-name"] == nil && self.codec_long_name == nil {
                isFilled = false
            }
            return s
            
        case "[[codec]]":
            let s = format(value: values?["codec"] ?? self.codec_long_name ?? self.codec_short_name, isFilled: &isFilled) { v, isFilled in
                guard let s = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !s.isEmpty
                return s
            }
            return s
        
        case "[[encoder]]":
            let s = format(value: values?["encoder"] ?? self.encoder, isFilled: &isFilled) { v, isFilled in
                guard let s = v as? String? else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                if let s = s {
                    isFilled = !s.isEmpty
                    return s
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
            return s
        case "[[compression]]":
            let s = format(value: values?["is-lossless"] ?? self.isLossless, isFilled: &isFilled) { v, isFilled in
                guard let b = v as? Bool? else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                if let b = b {
                    isFilled = true
                    return NSLocalizedString(b ? "lossless" : "lossy", tableName: "LocalizableExt", comment: "")
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
            return s
        default:
            return placeholder
        }
    }
}

class Chapter: NSCoding, Encodable {
    enum CodingKeys: String, CodingKey {
        case title
        case start
        case end
    }
    let title: String?
    let start: Double
    let end: Double
    
    var duration: Double {
        return end - start
    }
    
    init(title: String?, start: Double, end: Double) {
        self.title = title
        self.start = start
        self.end = end
    }
    
    required init?(coder: NSCoder) {
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        self.start = coder.decodeDouble(forKey: "start")
        self.end = coder.decodeDouble(forKey: "end")
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(title as NSString?, forKey: "title")
        coder.encode(start, forKey: "start")
        coder.encode(end, forKey: "end")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.start, forKey: .start)
        try container.encode(self.end, forKey: .end)
    }
    
    var timeInterval: String {
        var s = ""
        if start >= 0 {
            s += TimeInterval(start).formatTime()
        }
        if end > start {
            s += " - " + TimeInterval(end).formatTime()
        }
        return s
    }
    
    func getTitle(index: Int) -> String {
        var s = ""
        if let t = title {
            s = t
        } else {
            s = NSLocalizedString("chapter", comment: "") + " \(index)"
        }
        let t = timeInterval
        if !t.isEmpty {
            s += ", "+timeInterval
        }
        return s
    }
}

protocol ChaptersInfo: BaseInfo {
    var chapters: [Chapter] { get }
    func processPlaceholderChapters(_ placeholder: String, settings: Settings, values: [String : Any]?, isFilled: inout Bool) -> String
    
    static func decodeChapters(from coder: NSCoder) -> [Chapter]
    func encodeChapters(in coder: NSCoder)
}

enum ChaptersCodingKeys: String, CodingKey {
    case chapters
}

extension ChaptersInfo {
    static func decodeChapters(from coder: NSCoder) -> [Chapter] {
        let n = coder.decodeInteger(forKey: "chapters_count")
        var chapters: [Chapter] = []
        for i in 0 ..< n {
            guard let d = coder.decodeObject(of: NSData.self, forKey: "chapter_\(i)") as Data?, let c = try? NSKeyedUnarchiver(forReadingFrom: d) else {
                continue
            }
            defer {
                c.finishDecoding()
            }
            guard let chapter = Chapter(coder: c) else {
                continue
            }
            chapters.append(chapter)
        }
        return chapters
    }
    
    func encodeChapters(in coder: NSCoder) {
        coder.encode(self.chapters.count, forKey: "chapters_count")
        for i in 0 ..< self.chapters.count {
            let c = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
            self.chapters[i].encode(with: c)
            coder.encode(c.encodedData, forKey: "chapter_\(i)")
        }
    }
    
    func processPlaceholderChapters(_ placeholder: String, settings: Settings, values: [String : Any]?, isFilled: inout Bool) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[chapters-count]]":
            let s = format(value: values?["chapters"] ?? self.chapters, isFilled: &isFilled) { v, isFilled in
                guard let chapters = v as? [Chapter] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let n = chapters.count
                isFilled = n > 0
                if n > 0 || useEmptyData {
                    if n == 1 {
                        return NSLocalizedString("1 Chapter", tableName: "LocalizableExt", comment: "")
                    } else {
                        return String(format: NSLocalizedString("%d Chapters", tableName: "LocalizableExt", comment: ""), n)
                    }
                } else {
                    return ""
                }
            }
            return s
        default:
            return placeholder
        }
    }
}

// MARK: -
protocol MediaInfo: LanguageInfo, DurationInfo, CodecInfo, FileInfo {
    
}

// MARK: -
class VideoTrackInfo: DimensionalInfo, LanguageInfo, DurationInfo, CodecInfo {
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
    
    let start_time: Double
    let duration: Double
    let codec_short_name: String
    let codec_long_name: String?
    let profile: String?
    let pixel_format: VideoPixelFormat?
    let field_order: VideoFieldOrder?
    let color_space: VideoColorSpace?
    
    let lang: String?
    let bitRate: Int64
    let fps: Double
    let frames: Int
    let title: String?
    let encoder: String?
    let isLossless: Bool?
    
    init(
        width: Int, height: Int,
        duration: Double,
        start_time: Double,
        codec_short_name: String, codec_long_name: String?, profile: String?,
        pixel_format: VideoPixelFormat?,
        color_space: VideoColorSpace?,
        field_order: VideoFieldOrder?,
        lang: String?,
        bitRate: Int64, fps: Double,
        frames: Int,
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
        
        super.init(width: width, height: height)
    }

    required init?(coder: NSCoder) {
        self.duration = coder.decodeDouble(forKey: "duration")
        self.start_time = coder.decodeDouble(forKey: "start_time")
        self.codec_short_name = coder.decodeObject(of: NSString.self, forKey: "codec_short_name") as String? ?? ""
        self.codec_long_name = coder.decodeObject(of: NSString.self, forKey: "codec_long_name") as String?
        self.profile = coder.decodeObject(of: NSString.self, forKey: "profile") as String?
        self.pixel_format = VideoPixelFormat(rawValue: coder.decodeInteger(forKey: "pixel_format"))
        self.field_order = VideoFieldOrder(rawValue: coder.decodeInteger(forKey: "field_order"))
        self.color_space = VideoColorSpace(rawValue: coder.decodeInteger(forKey: "color_space"))
        self.lang = coder.decodeObject(of: NSString.self, forKey: "lang") as String?
        self.bitRate = coder.decodeInt64(forKey: "bitRate")
        self.frames = coder.decodeInteger(forKey: "frames")
        self.fps = coder.decodeDouble(forKey: "fps")
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        self.encoder = coder.decodeObject(of: NSString.self, forKey: "encoder") as String?
        self.isLossless = coder.decodeObject(of: NSNumber.self, forKey: "isLossless")?.boolValue
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.duration, forKey: "duration")
        coder.encode(self.start_time, forKey: "start_time")
        coder.encode(self.codec_short_name as NSString, forKey: "codec_short_name")
        coder.encode(self.codec_long_name as NSString?, forKey: "codec_long_name")
        coder.encode(self.profile, forKey: "profile")
        coder.encode(self.pixel_format?.rawValue ?? -1, forKey: "pixel_format")
        coder.encode(self.field_order?.rawValue ?? -1, forKey: "field_order")
        coder.encode(self.color_space?.rawValue ?? -1, forKey: "color_space")
        coder.encode(self.lang as NSString?, forKey: "lang")
        coder.encode(self.bitRate, forKey: "bitRate")
        coder.encode(self.frames, forKey: "frames")
        coder.encode(self.fps, forKey: "fps")
        coder.encode(self.title as NSString?, forKey: "title")
        coder.encode(self.encoder as NSString?, forKey: "encoder")
        coder.encode(self.isLossless as NSNumber?, forKey: "isLossless")
        
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
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
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[duration]]", "[[seconds]]", "[[bitrate]]", "[[start-time]]", "[[start-time-s]]":
            return processDurationPlaceholder(placeholder, values: values, isFilled: &isFilled)
        case "[[frames]]":
            return format(value: values?["frames"] ?? self.frames, isFilled: &isFilled) { v, isFilled in
                guard let frames = v as? Int else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                
                if let s = Self.numberFormatter.string(from: NSNumber(value: frames)) {
                    return s + " " + NSLocalizedString("frames", tableName: "LocalizableExt", comment: "")
                } else {
                    return "\(frames) " + NSLocalizedString("frames", tableName: "LocalizableExt", comment: "")
                }
            }
        case "[[fps]]":
            return format(value: values?["fps"] ?? self.fps, isFilled: &isFilled) { v, isFilled in
                guard let fps = v as? Double, fps >= 0 else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = fps > 0
                
                if fps > 0 || useEmptyData {
                    return Self.numberFormatter.string(from: NSNumber(floatLiteral: fps))! + " " + NSLocalizedString("fps", tableName: "LocalizableExt", comment: "")
                } else {
                    return ""
                }
            }
        case "[[profile]]":
            return format(value: values?["profile"] ?? self.profile, isFilled: &isFilled) { v, isFilled in
                guard let profile = v as? String else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = !profile.isEmpty
                return profile
            }
        case "[[field-order]]":
            return format(value: values?["field-order"] ?? self.field_order?.rawValue, isFilled: &isFilled) { v, isFilled in
                guard let n = v as? Int, let field_order = VideoFieldOrder(rawValue: n) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return field_order.label
            }
        case "[[pixel-format]]":
            return format(value: values?["pixel-format"] ?? self.pixel_format?.rawValue, isFilled: &isFilled) { v, isFilled in
                guard let n = v as? Int, let pixel_format = VideoPixelFormat(rawValue: n) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return pixel_format.label
            }
        case "[[color-space]]":
            return format(value: values?["color-space"] ?? self.color_space?.rawValue, isFilled: &isFilled) { v, isFilled in
                guard let n = v as? Int, let color_space = VideoColorSpace(rawValue: n) else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = true
                return color_space.label
            }
        case "[[title]]":
            return format(value: values?["title"] ?? self.title, isFilled: &isFilled) { v, isFilled in
                guard let title = v as? String? else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                if let title = title {
                    isFilled = !title.isEmpty
                    return title
                } else {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                }
            }
        case "[[codec]]", "[[codec-long]]", "[[codec-short]]", "[[compression]]", "[[encoder]]":
            return self.processPlaceholderCodec(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[languages]]", "[[languages-flag]]", "[[language-count]]",
             "[[language]]", "[[language-flag]]":
            return processLanguagePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[subtitles-count]]", "[[audio-count]]", "[[video-count]]", "[[video]]", "[[audio]]", "[[subtitles]]", "[[chapters]]",
             "[[chapters-count]]",
             "[[filesize]]", "[[file-name]]", "[[file-ext]]", "[[engine]]":
            isFilled = false
            return ""
            
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
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
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.videoMenuItems, image: self.getImage(for: "video"), withSettings: settings)
    }
}

// MARK: -
class VideoInfo: VideoTrackInfo, MediaInfo, ChaptersInfo {
    enum CodingKeys: String, CodingKey {
        case chapters
        case videoTracks
        case audioTracks
        case subtitles
        case engine
    }
    
    let file: URL
    let fileSize: Int64
    let chapters: [Chapter]
    let videoTracks: [VideoTrackInfo]
    let audioTracks: [AudioTrackInfo]
    let subtitles: [SubtitleTrackInfo]
    let engine: MediaEngine
    
    init(file: URL, width: Int, height: Int, duration: Double, start_time: Double, codec_short_name: String, codec_long_name: String?, profile: String?, pixel_format: VideoPixelFormat?, color_space: VideoColorSpace?, field_order: VideoFieldOrder?, lang: String?, bitRate: Int64, fps: Double, frames: Int, title: String?, encoder: String?, isLossless: Bool?, chapters: [Chapter], video: [VideoTrackInfo], audio: [AudioTrackInfo], subtitles: [SubtitleTrackInfo], engine: MediaEngine) {
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        
        self.videoTracks = video
        self.audioTracks = audio
        self.subtitles = subtitles
        self.chapters = chapters
        self.engine = engine
        super.init(
            width: width, height: height,
            duration: duration, start_time: start_time,
            codec_short_name: codec_short_name, codec_long_name: codec_long_name,
            profile: profile,
            pixel_format: pixel_format, color_space: color_space,
            field_order: field_order,
            lang: lang,
            bitRate: bitRate, fps: fps, frames: frames,
            title: title, encoder: encoder,
            isLossless: isLossless)
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
            
        self.engine = MediaEngine(rawValue: coder.decodeInteger(forKey: "engine"))!
        
        self.chapters = Self.decodeChapters(from: coder)
        
        var n = coder.decodeInteger(forKey: "video_count")
        var videos: [VideoTrackInfo] = []
        for i in 0 ..< n {
            if let data = coder.decodeObject(of: NSData.self, forKey: "video_\(i)") as Data?, let coder1 = try? NSKeyedUnarchiver(forReadingFrom: data) {
                if let video = VideoTrackInfo(coder: coder1) {
                    videos.append(video)
                }
                coder1.finishDecoding()
            }
        }
        self.videoTracks = videos
        
        n = coder.decodeInteger(forKey: "audio_count")
        var audios: [AudioTrackInfo] = []
        for i in 0 ..< n {
            if let data = coder.decodeObject(of: NSData.self, forKey: "audio_\(i)") as Data?, let coder1 = try? NSKeyedUnarchiver(forReadingFrom: data) {
                if let audio = AudioTrackInfo(coder: coder1) {
                    audios.append(audio)
                }
                coder1.finishDecoding()
            }
        }
        self.audioTracks = audios
        
        n = coder.decodeInteger(forKey: "subtitles_count")
        var titles: [SubtitleTrackInfo] = []
        for i in 0 ..< n {
            if let data = coder.decodeObject(of: NSData.self, forKey: "subtitle_\(i)") as Data?, let coder1 = try? NSKeyedUnarchiver(forReadingFrom: data) {
                if let title = SubtitleTrackInfo(coder: coder1) {
                    titles.append(title)
                }
                coder1.finishDecoding()
            }
        }
        self.subtitles = titles
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        coder.encode(self.engine.rawValue, forKey: "engine")
        self.encodeChapters(in: coder)
        coder.encode(self.videoTracks.count, forKey: "video_count")
        for i in 0 ..< self.videoTracks.count {
            let coder1 = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
            self.videoTracks[i].encode(with: coder1)
            coder.encode(coder1.encodedData, forKey: "video_\(i)")
        }
        coder.encode(self.audioTracks.count, forKey: "audio_count")
        for i in 0 ..< self.audioTracks.count {
            let coder1 = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
            self.audioTracks[i].encode(with: coder1)
            coder.encode(coder1.encodedData, forKey: "audio_\(i)")
        }
        coder.encode(self.subtitles.count, forKey: "subtitles_count")
        for i in 0 ..< self.subtitles.count {
            let coder1 = NSKeyedArchiver(requiringSecureCoding: coder.requiresSecureCoding)
            self.subtitles[i].encode(with: coder1)
            coder.encode(coder1.encodedData, forKey: "subtitle_\(i)")
        }
        
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeFileInfo(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.engine.label, forKey: .engine)
        
        try container.encode(self.chapters, forKey: .chapters)
        try container.encode(self.videoTracks, forKey: .videoTracks)
        try container.encode(self.audioTracks, forKey: .audioTracks)
        try container.encode(self.subtitles, forKey: .subtitles)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[languages]]", "[[languages-flag]]", "[[language-count]]":
            var v = values ?? [:]
            if v["language"] as? [String] == nil {
                var languages: [String] = []
                if let lang = v["language"] as? String {
                    if !lang.isEmpty {
                        languages.append(lang)
                    }
                } else if let lang = self.lang, !lang.isEmpty {
                    languages.append(lang)
                }
                v["language"] = languages
            }
            
            return processLanguagePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[subtitles-count]]":
            let s = format(value: values?["subtitles"] ?? self.subtitles, isFilled: &isFilled) { v, isFilled in
                guard let subtitles = v as? [SubtitleTrackInfo] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let n = subtitles.count
                isFilled = n > 0
                
                if n == 1 {
                    return NSLocalizedString("1 Subtitle", tableName: "LocalizableExt", comment: "")
                } else {
                    if n == 0 && !useEmptyData {
                        return ""
                    }
                    return String(format: NSLocalizedString("%s Subtitles", tableName: "LocalizableExt", comment: ""), n)
                }
            }
            return s
        case "[[audio-count]]":
            let s = format(value: values?["audio"] ?? self.audioTracks, isFilled: &isFilled) { v, isFilled in
                guard let audio = v as? [AudioTrackInfo] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let n = audio.count
                isFilled = n > 0
                
                if n == 1 {
                    return NSLocalizedString("1 Audio track", tableName: "LocalizableExt", comment: "")
                } else {
                    if n == 0 && !useEmptyData {
                        return ""
                    }
                    return String(format: NSLocalizedString("%d Audio tracks", tableName: "LocalizableExt", comment: ""), n)
                }
            }
            return s
        case "[[video-count]]":
            let s = format(value: values?["video"] ?? self.videoTracks, isFilled: &isFilled) { v, isFilled in
                guard let video = v as? [VideoTrackInfo] else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                let n = video.count
                isFilled = n > 0
                
                if n == 1 {
                    return NSLocalizedString("1 Video track", tableName: "LocalizableExt", comment: "")
                } else {
                    if n == 0 && !useEmptyData {
                        return ""
                    }
                    return String(format: NSLocalizedString("%d Video tracks", tableName: "LocalizableExt", comment: ""), n)
                }
            }
            return s
        case "[[chapters-count]]":
            return self.processPlaceholderChapters(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]":
            return self.processFilePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[engine]]":
            isFilled = true
            return engine.label
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        var template = "[[size]], [[duration]]"
        if self.bitRate > 0 {
            template += ", [[bitrate]]"
        }
        if !self.codec_short_name.isEmpty {
            template += " ([[codec]])"
        }
        template += " [[languages-flag]]"
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, atIndex itemIndex: Int, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        switch item.template {
        case "[[chapters]]":
            guard !self.chapters.isEmpty else {
                return true
            }
            
            var isFilled = false
            let s = self.replacePlaceholders(in: "[[chapters-count]]", settings: settings, isFilled: &isFilled, forItem: itemIndex)
            let chapters_menu = NSMenu(title: "Chapters")
            for (i, chapter) in self.chapters.enumerated() {
                chapters_menu.addItem(self.createMenuItem(title: chapter.getTitle(index: i), image: "-", settings: settings))
            }
            
            let mnu = self.createMenuItem(title: s, image: item.image, settings: settings)
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(chapters_menu, for: mnu)
        case "[[video]]":
            let n = self.videoTracks.count
            guard n > 0 else {
                return true
            }
            
            let group_tracks = settings.isTracksGrouped // FIXME: rename
            let video_sub_menu: NSMenu
            var title = ""
            if group_tracks {
                var filled = false
                title = self.replacePlaceholders(in: "[[video-count]]", settings: settings, isFilled: &filled, forItem: itemIndex)
                if !filled || title.isEmpty {
                    title = NSLocalizedString("Video", tableName: "LocalizableExt", comment: "")
                }
                video_sub_menu = NSMenu(title: title)
                
            } else {
                video_sub_menu = destination_sub_menu
            }
            for video in videoTracks {
                guard let video_menu = video.getMenu(withSettings: settings) else {
                    continue
                }
                for item in video_menu.items {
                    video_sub_menu.addItem(item.copy() as! NSMenuItem)
                }
            }
            if group_tracks {
                if n == 1 && settings.isInfoOnMainItem && video_sub_menu.items.count == 1 {
                    destination_sub_menu.addItem(video_sub_menu.items.first!.copy() as! NSMenuItem)
                } else {
                    let video_mnu = destination_sub_menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
                    video_mnu.image = self.getImage(for: "video")
                    destination_sub_menu.setSubmenu(video_sub_menu, for: video_mnu)
                }
            }
        case "[[audio]]":
            let n = audioTracks.count
            guard n > 0 else {
                return true
            }
            
            let audio_sub_menu: NSMenu
            let group_tracks = settings.isTracksGrouped
            var title = ""
            if group_tracks {
                var filled = false
                title = self.replacePlaceholders(in: "[[audio-count]]", settings: settings, isFilled: &filled, forItem: itemIndex)
                if !filled || title.isEmpty {
                    title = NSLocalizedString("Audio", tableName: "LocalizableExt", comment: "")
                }
                
                audio_sub_menu = NSMenu(title: title)
            } else {
                audio_sub_menu = destination_sub_menu
            }
            
            for audio in audioTracks {
               guard let audio_menu = audio.getMenu(withSettings: settings) else {
                   continue
               }
               for item in audio_menu.items {
                   audio_sub_menu.addItem(item.copy() as! NSMenuItem)
               }
            }
            if group_tracks {
                if n == 1 && settings.isInfoOnMainItem && audio_sub_menu.items.count == 1 {
                    destination_sub_menu.addItem(audio_sub_menu.items.first!.copy() as! NSMenuItem)
                } else {
                    let audio_mnu = destination_sub_menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
                    audio_mnu.image = self.getImage(for: "audio")
                    destination_sub_menu.setSubmenu(audio_sub_menu, for: audio_mnu)
                }
            }
        case "[[subtitles]]":
            let n = subtitles.count
            guard n > 0 else {
                return true
            }
            
            let sub_menu_txt: NSMenu
            let group_tracks = settings.isTracksGrouped // FIXME: rename
            if group_tracks {
               let mnu_txt = destination_sub_menu.addItem(withTitle: "\(n) " + NSLocalizedString("Subtitles", tableName: "LocalizableExt", comment: ""), action: nil, keyEquivalent: "")
               mnu_txt.image = self.getImage(for: "txt")
               sub_menu_txt = NSMenu(title: "\(n) " + NSLocalizedString("Subtitles", tableName: "LocalizableExt", comment: ""))
               destination_sub_menu.setSubmenu(sub_menu_txt, for: mnu_txt)
            } else {
               sub_menu_txt = destination_sub_menu
            }
            for subtitle in subtitles {
               guard let subtitle_menu = subtitle.getMenu(withSettings: settings) else {
                   continue
               }
               for item in subtitle_menu.items {
                   sub_menu_txt.addItem(item.copy() as! NSMenuItem)
               }
            }
        default:
            return super.processSpecialMenuItem(item, atIndex: itemIndex, inMenu: destination_sub_menu, withSettings: settings)
        }
        
        return true
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.videoMenuItems, image: self.getImage(for: "video"), withSettings: settings)
    }
}

// MARK: -
class ImageVideoInfo: DimensionalInfo, CodecInfo, FileInfo {
    enum CodingKeys: String, CodingKey {
        case codecShortName
        case codecLongName
        case isLossless
        case encoder
    }

    let file: URL
    let fileSize: Int64
    let codec_short_name: String
    let codec_long_name: String?
    
    let isLossless: Bool?
    let encoder: String?
    
    init(file: URL, width: Int, height: Int, codec_short_name: String, codec_long_name: String?, isLossless: Bool?, encoder: String?) {
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        self.codec_short_name = codec_short_name
        self.codec_long_name = codec_long_name
        self.isLossless = isLossless
        self.encoder = encoder
        
        super.init(width: width, height: height)
    }

    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        self.codec_short_name = coder.decodeObject(of: NSString.self, forKey: "codec_short_name") as String? ?? ""
        self.codec_long_name = coder.decodeObject(of: NSString.self, forKey: "codec_long_name") as String?
        self.encoder = coder.decodeObject(of: NSString.self, forKey: "encoder") as String?
        self.isLossless = coder.decodeObject(of: NSNumber.self, forKey: "isLossless")?.boolValue
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        coder.encode(self.codec_short_name as NSString, forKey: "codec_short_name")
        coder.encode(self.codec_long_name as NSString?, forKey: "codec_long_name")
        coder.encode(self.encoder as NSString?, forKey: "encoder")
        coder.encode(self.isLossless as NSNumber?, forKey: "isLossless")
        
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeFileInfo(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.codec_short_name, forKey: .codecShortName)
        try container.encode(self.codec_long_name, forKey: .codecLongName)
        try container.encode(self.isLossless, forKey: .isLossless)
        try container.encode(self.encoder, forKey: .encoder)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        switch placeholder {
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]":
            return self.processFilePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[codec]]", "[[codec-long]]", "[[codec-short]]", "[[compression]]", "[[encoder]]":
            return self.processPlaceholderCodec(placeholder, settings: settings, values: values, isFilled: &isFilled)
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        }
    }
}

// MARK: -
class AudioTrackInfo: BaseInfo, LanguageInfo, DurationInfo, CodecInfo {
    enum CodingKeys: String, CodingKey {
        case duration
        case startTime
        case codecShortName
        case codecLongName
        case lang
        case langFlag
        case bitRate
        case title
        case encoder
        case isLossless
        case channels
    }
    
    let duration: Double
    let start_time: Double
    let codec_short_name: String
    let codec_long_name: String?
    let lang: String?
    let bitRate: Int64
    let title: String?
    let encoder: String?
    let isLossless: Bool?
    let channels: Int
    var isMono: Bool {
        return channels == 1
    }
    var isStereo: Bool {
        return channels == 2
    }
    
    init(duration: Double, start_time: Double, codec_short_name: String, codec_long_name: String?, lang: String?, bitRate: Int64, title: String?, encoder: String?, isLossless: Bool?, channels: Int) {
        self.duration = duration
        self.start_time = start_time
        self.codec_short_name = codec_short_name
        self.codec_long_name = codec_long_name
        self.lang = lang
        self.bitRate = bitRate
        self.isLossless = isLossless
        self.title = title
        self.encoder = encoder
        self.channels = channels
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.duration = coder.decodeDouble(forKey: "duration")
        self.start_time = coder.decodeDouble(forKey: "start_time")
        self.codec_short_name = coder.decodeObject(of: NSString.self, forKey: "codec_short_name") as String? ?? ""
        self.codec_long_name = coder.decodeObject(of: NSString.self, forKey: "codec_long_name") as String?
        self.lang = coder.decodeObject(of: NSString.self, forKey: "lang") as String?
        self.bitRate = coder.decodeInt64(forKey: "bitRate")
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        self.encoder = coder.decodeObject(of: NSString.self, forKey: "encoder") as String?
        self.isLossless = coder.decodeObject(of: NSNumber.self, forKey: "isLossless")?.boolValue
        self.channels = coder.decodeInteger(forKey: "channels")
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(self.duration, forKey: "duration")
        coder.encode(self.start_time, forKey: "start_time")
        coder.encode(self.codec_short_name as NSString, forKey: "codec_short_name")
        coder.encode(self.codec_long_name as NSString?, forKey: "codec_long_name")
        coder.encode(self.lang as NSString?, forKey: "lang")
        coder.encode(self.bitRate, forKey: "bitRate")
        coder.encode(self.title as NSString?, forKey: "title")
        coder.encode(self.encoder, forKey: "encoder")
        coder.encode(self.isLossless as NSNumber?, forKey: "isLossless")
        coder.encode(self.channels, forKey: "channels")
        
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.duration, forKey: .duration)
        try container.encode(self.start_time, forKey: .startTime)
        try container.encode(self.codec_short_name, forKey: .codecShortName)
        try container.encode(self.codec_long_name, forKey: .codecLongName)
        try container.encode(self.lang, forKey: .lang)
        try container.encode(self.bitRate, forKey: .bitRate)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.encoder, forKey: .encoder)
        try container.encode(self.isLossless, forKey: .isLossless)
        try container.encode(self.channels, forKey: .channels)
        
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.getCountryFlag(), forKey: .langFlag)
        }
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "speaker" && self.isStereo {
            return super.getImage(for: "speaker_stereo");
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let useEmptyData = false
        switch placeholder {
        case "[[duration]]", "[[seconds]]", "[[bitrate]]", "[[start-time]]", "[[start-time-s]]":
            return processDurationPlaceholder(placeholder, values: values, isFilled: &isFilled)
        case "[[codec]]", "[[codec-long]]", "[[codec-short]]":
            return self.processPlaceholderCodec(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[language]]", "[[language-flag]]":
            return processLanguagePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]",
             "[[chapters-count]]", "[[engine]]":
            isFilled = false
            return ""
        case "[[channels]]":
            return format(value: values?["channels"] ?? self.channels, isFilled: &isFilled) { v, isFilled in
                guard let channels = v as? Int else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = channels > 0
                if channels <= 0 {
                    return self.formatND(useEmptyData: useEmptyData)
                } else if channels == 1 {
                    return NSLocalizedString("1 channel", tableName: "LocalizableExt", comment: "")
                } else {
                    return String(format: NSLocalizedString("%d channels", tableName: "LocalizableExt", comment: ""), channels)
                }
            }
            
        case "[[channels-name]]":
            return format(value: values?["channels"] ?? self.channels, isFilled: &isFilled) { v, isFilled in
                guard let channels = v as? Int else {
                    isFilled = false
                    return self.formatERR(useEmptyData: useEmptyData)
                }
                isFilled = channels > 0
                if channels <= 0 {
                    return self.formatND(useEmptyData: useEmptyData)
                } else if channels == 1 {
                    return NSLocalizedString("mono", tableName: "LocalizableExt", comment: "")
                } else if channels == 2 {
                    return NSLocalizedString("stereo", tableName: "LocalizableExt", comment: "")
                } else {
                    return String(format: NSLocalizedString("%d channels", tableName: "LocalizableExt", comment: ""), channels)
                }
            }
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        var template = "[[duration]]"
        if self.bitRate > 0 {
            template += ", [[bitrate]]"
        }
        
        if !self.codec_short_name.isEmpty {
            template += " [[codec]]"
        }
        if let country = self.lang, !country.isEmpty {
            template += " [[language-flag]]"
        }
        var isFilled = false
        let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
        return isFilled ? title : ""
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.audioMenuItems, image: self.getImage(for: "audio"), withSettings: settings)
    }
}

class AudioInfo: AudioTrackInfo, MediaInfo, ChaptersInfo {
    enum CodingKeys: String, CodingKey {
        case chapters
        case engine
    }
    
    let file: URL
    let fileSize: Int64
    let chapters: [Chapter]
    let engine: MediaEngine
    
    init(file: URL, duration: Double, start_time: Double, codec_short_name: String, codec_long_name: String?, lang: String?, bitRate: Int64, title: String?, encoder: String?, isLossless: Bool?, chapters: [Chapter], channels: Int, engine: MediaEngine) {
        self.file = file
        self.fileSize = Self.getFileSize(file) ?? -1
        
        self.chapters = chapters
        self.engine = engine
        super.init(duration: duration, start_time: start_time, codec_short_name: codec_short_name, codec_long_name: codec_long_name, lang: lang, bitRate: bitRate, title: title, encoder: encoder, isLossless: isLossless, channels: channels)
    }
    
    required init?(coder: NSCoder) {
        guard let r = Self.decodeFileInfo(coder) else {
            return nil
        }
        self.file = r.0
        self.fileSize = r.1 ?? -1
        
        guard let e = MediaEngine(rawValue: coder.decodeInteger(forKey: "engine")) else {
            return nil
        }
        self.engine = e
        
        self.chapters = Self.decodeChapters(from: coder)
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        self.encodeFileInfo(coder)
        coder.encode(self.engine.rawValue, forKey: "engine")
        self.encodeChapters(in: coder)
        
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        try self.encodeFileInfo(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.engine.label, forKey: .engine)
        try container.encode(self.chapters, forKey: .chapters)
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        switch placeholder {
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]":
            return processFilePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[codec]]", "[[codec-long]]", "[[codec-short]]":
            return self.processPlaceholderCodec(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[chapters-count]]":
            return self.processPlaceholderChapters(placeholder, settings: settings, values: values, isFilled: &isFilled)
        case "[[engine]]":
            isFilled = true
            return engine.label
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: Settings.MenuItem, atIndex itemIndex: Int, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        switch item.template {
        case "[[chapters]]":
            guard !self.chapters.isEmpty else {
                return true
            }
            
            var isFilled = false
            let s = self.replacePlaceholders(in: "[[chapters-count]]", settings: settings, isFilled: &isFilled, forItem: itemIndex)
            let chapters_menu = NSMenu(title: "Chapters")
            for (i, chapter) in self.chapters.enumerated() {
                chapters_menu.addItem(self.createMenuItem(title: chapter.getTitle(index: i), image: "-", settings: settings))
            }
            
            let mnu = self.createMenuItem(title: s, image: item.image, settings: settings)
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(chapters_menu, for: mnu)
        default:
            return super.processSpecialMenuItem(item, atIndex: itemIndex, inMenu: destination_sub_menu, withSettings: settings)
        }
        
        return true
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        return self.generateMenu(items: settings.audioMenuItems, image: self.getImage(for: "audio"), withSettings: settings)
    }
}


// MARK: - SubtitleTrackInfo
class SubtitleTrackInfo: BaseInfo, LanguageInfo {
    enum CodingKeys: String, CodingKey {
        case title
        case lang
        case langFlag
    }
    let title: String?
    let lang: String?
    
    init(title: String?, lang: String?) {
        self.title = title
        self.lang = lang
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        self.lang = coder.decodeObject(of: NSString.self, forKey: "lang") as String?
        
        super.init(coder: coder)
    }
    override func encode(with coder: NSCoder) {
        coder.encode(self.title as NSString?, forKey: "title")
        coder.encode(self.lang as NSString?, forKey: "lang")
        super.encode(with: coder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.lang, forKey: .lang)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.getCountryFlag(), forKey: .langFlag)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, values: [String : Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        switch placeholder {
        case "[[title]]":
            let s = format(value: values?["title"] ?? title, isFilled: &isFilled)
            isFilled = title != nil && !title!.isEmpty
            return s
        case "[[language]]", "[[language-flag]]":
            return processLanguagePlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled)
        default:
            return super.processPlaceholder(placeholder, settings: settings, values: values, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    override func getStandardTitle(forSettings settings: Settings) -> String {
        var template = ""
        if let _ = self.title {
            template += "[[title]] "
        }
        if let country = self.lang, !country.isEmpty {
            template += " [[language-flag]]"
        }
        if !template.isEmpty {
            var isFilled = false
            let title: String = self.replacePlaceholders(in: template, settings: settings, isFilled: &isFilled, forItem: -1)
            return isFilled ? title : ""
        } else {
            return ""
        }
    }
    
    override func getMenu(withSettings settings: Settings) -> NSMenu? {
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
                
        let destination_sub_menu: NSMenu = menu
        /*
        if settings.isInfoOnSubMenu {
            let info_mnu = menu.addItem(withTitle: "Subtitle", action: nil, keyEquivalent: "")
            info_mnu.image = self.getImage(for: "txt")
            let info_sub_menu = NSMenu(title: "MediaInfo")
            menu.setSubmenu(info_sub_menu, for: info_mnu)
            destination_sub_menu = info_sub_menu
        } else {
            destination_sub_menu = menu
        }
        */
        
        let title = self.getStandardTitle(forSettings: settings)
        if !title.isEmpty {
            let mnu = createMenuItem(title: title, image: "txt", settings: settings)
            destination_sub_menu.addItem(mnu)
        }
        return menu
    }
}

class AttachmentTrackInfo: BaseInfo {
}
