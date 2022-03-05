//
//  AudioTrackInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 26/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

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
    lazy var flagImage: NSImage? = {
        return self.getImageOfFlag()
    }()
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Double.self, forKey: .duration)
        self.start_time = try container.decode(Double.self, forKey: .startTime)
        self.codec_short_name = try container.decode(String.self, forKey: .codecShortName)
        self.codec_long_name = try container.decode(String?.self, forKey: .codecLongName)
        self.lang = try container.decode(String?.self, forKey: .lang)
        self.bitRate = try container.decode(Int64.self, forKey: .bitRate)
        self.title = try container.decode(String?.self, forKey: .title)
        self.encoder = try container.decode(String?.self, forKey: .encoder)
        self.isLossless = try container.decode(Bool?.self, forKey: .isLossless)
        self.channels = try container.decode(Int.self, forKey: .channels)
        
        try super.init(from: decoder)
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
        } else if name == "flag", let img = self.flagImage {
            return img
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        if let s = self.processAudioPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex) {
            return s
        } else {
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: itemIndex)
        }
    }
    
    internal func processAudioPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String? {
        let useEmptyData = !settings.isEmptyItemsSkipped
        switch placeholder {
        case "[[duration]]", "[[seconds]]", "[[bitrate]]", "[[start-time]]", "[[start-time-s]]":
            return processDurationPlaceholder(placeholder, settings: settings, isFilled: &isFilled)
        case "[[codec]]", "[[codec-long]]", "[[codec-short]]":
            return self.processPlaceholderCodec(placeholder, settings: settings, isFilled: &isFilled)
        case "[[language]]", "[[language-flag]]":
            return processLanguagePlaceholder(placeholder, settings: settings, isFilled: &isFilled)
        case "[[filesize]]", "[[file-name]]", "[[file-ext]]", "[[file-cdate]]", "[[file-mdate]]", "[[file-adate]]",
             "[[chapters-count]]", "[[engine]]":
            isFilled = false
            return ""
        case "[[channels]]":
            isFilled = channels > 0
            if channels <= 0 {
                return self.formatND(useEmptyData: useEmptyData)
            } else if channels == 1 {
                return NSLocalizedString("1 Channel", tableName: "LocalizableExt", comment: "")
            } else {
                return String(format: NSLocalizedString("%d Channels", tableName: "LocalizableExt", comment: ""), channels)
            }
            
        case "[[channels-name]]":
            isFilled = channels > 0
            if channels <= 0 {
                return self.formatND(useEmptyData: useEmptyData)
            } else if channels == 1 {
                return NSLocalizedString("Mono", tableName: "LocalizableExt", comment: "")
            } else if channels == 2 {
                return NSLocalizedString("Stereo", tableName: "LocalizableExt", comment: "")
            } else {
                return String(format: NSLocalizedString("%d Channels", tableName: "LocalizableExt", comment: ""), channels)
            }
        default:
            return nil
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
