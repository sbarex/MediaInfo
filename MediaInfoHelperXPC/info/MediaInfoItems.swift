//
//  InfoItems.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 11/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

// MARK: - DurationInfo
protocol DurationInfo: BaseInfo {
    var duration: Double { get }
    var bitRate: Int64 { get }
    var start_time: Double { get }
    func processDurationPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem: MenuItemInfo?) -> String
}

extension DurationInfo {
    static func formatBits(_ bits: Int64, useDecimal: Bool) -> String {
        var i = 0
        var b = Double(bits)

        let power: Double = useDecimal ? 1000 : 1024
        while b > power {
            b /= power
            i += 1
        }
        
        if i > 0 && b < 1.5 {
            i -= 1
        }
        let j = round(Double(bits) / pow(power, Double(i)))
        let n = Self.numberFormatter.string(from: NSNumber(value: j)) ?? "\(j)"
        let bitUnits = ["bps", "kbps", "Mbps", "Gbps", "Tbps", "Pbps", "Ebps", "Zbps", "Ybps"]

        return "\(n) \(bitUnits[i])"
    }

    func processDurationPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[duration]]":
            isFilled = self.duration > 0
            return TimeInterval(duration).formatTime()
        case "[[seconds]]":
            isFilled = self.duration > 0
            return (Self.numberFormatter.string(from: NSNumber(floatLiteral: self.duration)) ?? "\(self.duration)") + " s"
        case "[[start-time]]":
            isFilled = self.start_time > 0
            if self.start_time < 0 {
                return self.formatND(useEmptyData: useEmptyData)
            } else {
                return (Self.numberFormatter.string(from: NSNumber(floatLiteral: self.start_time)) ?? "\(self.start_time)") + " s"
            }
        case "[[start-time-s]]":
            isFilled = start_time > 0
            if start_time < 0 {
                return self.formatND(useEmptyData: useEmptyData)
            } else {
                return TimeInterval(Double(start_time)).formatTime()
            }
        case "[[bitrate]]":
            isFilled = self.bitRate > 0
            if self.bitRate > 0 {
                return Self.formatBits(self.bitRate, useDecimal: (self.globalSettings?.bitsFormat ?? .decimal) == .decimal)
            } else {
                return self.formatND(useEmptyData: useEmptyData)
            }
        default:
            return placeholder
        }
    }
}

// MARK: - CodecInfo
protocol CodecInfo: BaseInfo {
    var codec_short_name: String { get }
    var codec_long_name: String? { get }
    
    var encoder: String? { get }
    var isLossless: Bool? { get }
    
    func processPlaceholderCodec(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String
}

extension CodecInfo {
    func processPlaceholderCodec(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[codec-short]]":
            isFilled = !self.codec_short_name.isEmpty
            return self.codec_short_name
            
        case "[[codec-long]]":
            guard let s = self.codec_long_name else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            isFilled = !s.isEmpty
            return s
            
        case "[[codec]]":
            let s = self.codec_long_name ?? self.codec_short_name
            isFilled = !s.isEmpty
            return s
        
        case "[[encoder]]":
            guard let s = self.encoder else {
                isFilled = false
                return self.formatERR(useEmptyData: useEmptyData)
            }
            isFilled = !s.isEmpty
            return s
        case "[[compression]]":
            if let b = self.isLossless {
                isFilled = true
                return NSLocalizedString(b ? "lossless" : "lossy", tableName: "LocalizableExt", comment: "")
            } else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
        default:
            return placeholder
        }
    }
}

// MARK: - Chapter
class Chapter: Codable {
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String?.self, forKey: .title)
        self.start = try container.decode(Double.self, forKey: .start)
        self.end = try container.decode(Double.self, forKey: .end)
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
            s = NSLocalizedString("Chapter", comment: "") + " \(index)"
        }
        let t = timeInterval
        if !t.isEmpty {
            s += ", "+timeInterval
        }
        return s
    }
}

// MARK: - ChaptersInfo
protocol ChaptersInfo: BaseInfo {
    var chapters: [Chapter] { get }
    func processPlaceholderChapters(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String
    func processSpecialChaptersMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool
}

extension ChaptersInfo {
    func processPlaceholderChapters(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[chapters-count]]":
            return self.formatCount(chapters.count, noneLabel: "no Chapter", singleLabel: "1 Chapter", manyLabel: "%d Chapters", isFilled: &isFilled, useEmptyData: useEmptyData, formatAsString: false)
        default:
            return placeholder
        }
    }
    
    func processSpecialChaptersMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        switch item.menuItem.template {
        case "[[chapters]]":
            guard !self.chapters.isEmpty else {
                return true
            }
            
            let chapters_menu = NSMenu(title: NSLocalizedString("Chapters", comment: ""))
            for (i, chapter) in self.chapters.enumerated() {
                var info = item
                info.userInfo["chapter_index"] = i
                chapters_menu.addItem(self.createMenuItem(title: chapter.getTitle(index: i), image: "-", representedObject: info))
            }
            
            let title = self.formatCount(chapters.count, noneLabel: "no Chapter", singleLabel: "1 Chapter", manyLabel: "%d Chapters", useEmptyData: true, formatAsString: false)
            let mnu = self.createMenuItem(title: title, image: item.menuItem.image, representedObject: item)
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(chapters_menu, for: mnu)
            
            return true
        default:
            return false
        }
    }
}

// MARK: - MediaInfo
protocol MediaInfo: FileInfo, LanguageInfo, DurationInfo, CodecInfo {
    
}

// MARK: -
class VideoInfo: FileInfo, MediaInfo, ChaptersInfo, LanguagesInfo {
    var lang: String? { return self.videoTrack.lang }
    lazy var flagImage: NSImage? = {
        return self.getImageOfFlag()
    }()
    var languages: [String] {
        var languages: Set<String> = []
        if let l = self.lang, !l.isEmpty {
            languages.insert(l)
        }
        for v in self.videoTracks {
            if let l = v.lang, !l.isEmpty {
                languages.insert(l)
            }
        }
        for a in self.audioTracks {
            if let l = a.lang, !l.isEmpty {
                languages.insert(l)
            }
        }
        return Array(languages)
    }
    
    var duration: Double { return self.videoTrack.duration }
    var bitRate: Int64 { return self.videoTrack.bitRate }
    var start_time: Double { return self.videoTrack.start_time }
    var codec_short_name: String { return self.videoTrack.codec_short_name }
    var codec_long_name: String?  { return self.videoTrack.codec_long_name }
    var encoder: String? { return self.videoTrack.encoder }
    var isLossless: Bool? { return self.videoTrack.isLossless }
    
    enum CodingKeys: String, CodingKey {
        case chapters
        case videoTracks
        case audioTracks
        case subtitles
        case engine
        case engineName
        case track
    }
    
    let chapters: [Chapter]
    let videoTracks: [VideoTrackInfo]
    let audioTracks: [AudioTrackInfo]
    let subtitles: [SubtitleTrackInfo]
    let engine: Settings.MediaEngine
    let videoTrack: VideoTrackInfo
    
    override class var infoType: Settings.SupportedFile { return .video }
    override var standardMainItem: MenuItemInfo {
        var template = "[[size]], [[duration]]"
        if self.bitRate > 0 {
            template += ", [[bitrate]]"
        }
        if !self.codec_short_name.isEmpty {
            template += " ([[codec]])"
        }
        template += " [[languages-flag]]"
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "video", template: template))
    }
    
    init(file: URL, width: Int, height: Int, duration: Double, start_time: Double, codec_short_name: String, codec_long_name: String?, profile: String?, pixel_format: VideoTrackInfo.VideoPixelFormat?, color_space: VideoTrackInfo.VideoColorSpace?, field_order: VideoTrackInfo.VideoFieldOrder?, lang: String?, bitRate: Int64, fps: Double, frames: Int, title: String?, encoder: String?, isLossless: Bool?, chapters: [Chapter], video: [VideoTrackInfo], audio: [AudioTrackInfo], subtitles: [SubtitleTrackInfo], engine: Settings.MediaEngine) {
        
        self.videoTracks = video
        self.audioTracks = audio
        self.subtitles = subtitles
        self.chapters = chapters
        self.engine = engine
        self.videoTrack = VideoTrackInfo(
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
        
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let i = try container.decode(Int.self, forKey: .engine)
        self.engine = Settings.MediaEngine(rawValue: i)!
        self.videoTrack = try container.decode(VideoTrackInfo.self, forKey: .track)
        self.chapters = try container.decode([Chapter].self, forKey: .chapters)
        self.videoTracks = try container.decode([VideoTrackInfo].self, forKey: .videoTracks)
        self.audioTracks = try container.decode([AudioTrackInfo].self, forKey: .audioTracks)
        self.subtitles = try container.decode([SubtitleTrackInfo].self, forKey: .subtitles)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.engine.rawValue, forKey: .engine)
        try container.encode(self.videoTrack, forKey: .track)
        
        try container.encode(self.chapters, forKey: .chapters)
        try container.encode(self.videoTracks, forKey: .videoTracks)
        try container.encode(self.audioTracks, forKey: .audioTracks)
        try container.encode(self.subtitles, forKey: .subtitles)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.engine.label, forKey: .engineName)
        }
    }
    
    override func fetchMetadata(from metadata: MDItem) {
        super.fetchMetadata(from: metadata)
        
        var i: Int = 0
        if let m = MDItemCopyAttribute(metadata, kMDItemAudioBitRate), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {The audio bit rate. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemAudioBitRate as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemCodecs), CFGetTypeID(m) == CFArrayGetTypeID() {
            // {The codecs used to encode/decode the media. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemCodecs as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemDeliveryType), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The delivery type. Values are “Fast start” or “RTSP”. A CFString.
            self.spotlightMetadata[kMDItemDeliveryType as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemMediaTypes), CFGetTypeID(m) == CFArrayGetTypeID() {
            // {The media types present in the content. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemMediaTypes as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemStreamable), CFGetTypeID(m) == CFBooleanGetTypeID() {
            // {Whether the content is prepared for streaming. A CFBoolean.
            let b = CFBooleanGetValue((m as! CFBoolean))
            self.spotlightMetadata[kMDItemStreamable as String] = NSLocalizedString(b ? "Yes" : "No", tableName: "LocalizableExt", comment: "")
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemTotalBitRate), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {The total bit rate, audio and video combined, of the media. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemTotalBitRate as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemVideoBitRate), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {The video bit rate. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemVideoBitRate as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemDirector), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Directory of the movie. A CFString.
            self.spotlightMetadata[kMDItemDirector as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemProducer), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Producer of the content. A CFString.
            self.spotlightMetadata[kMDItemProducer as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemGenre), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Genre of the movie. A CFString.
            self.spotlightMetadata[kMDItemGenre as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemPerformers), CFGetTypeID(m) == CFArrayGetTypeID() {
            // {Performers in the movie. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemPerformers as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemOriginalFormat), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Original format of the movie. A CFString.
            self.spotlightMetadata[kMDItemOriginalFormat as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemOriginalSource), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Original source of the movie. A CFString.
            self.spotlightMetadata[kMDItemOriginalSource as String] = m as! String
        }
    }
    
    override func initSettings(withItemSettings itemSettings: Settings.FormatSettings? = nil, globalSettings settings: Settings) {
        super.initSettings(withItemSettings: itemSettings, globalSettings: settings)
        self.videoTrack.initSettings(globalSettings: settings)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "flag", let img = self.flagImage {
            return img
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        if let s = self.videoTrack.processVideoPlaceholder(placeholder, isFilled: &isFilled, forItem: item) {
            return s
        }
        
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        switch placeholder {
        case "[[languages]]", "[[languages-flag]]", "[[language-count]]":
            return processLanguagesPlaceholder(placeholder, isFilled: &isFilled, forItem: item) ?? placeholder
        case "[[language]]", "[[language-flag]]":
            return processLanguagePlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        case "[[subtitles-count]]":
            return self.formatCount(subtitles.count, noneLabel: "no Subtitle", singleLabel: "1 Subtitle", manyLabel: "%d Subtitles", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[audio-count]]":
            return self.formatCount(audioTracks.count, noneLabel: "no Audio track", singleLabel: "1 Audio track", manyLabel: "%d Audio tracks", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[video-count]]":
            return self.formatCount(videoTracks.count, noneLabel: "no Video track", singleLabel: "1 Video track", manyLabel: "%d Video tracks", isFilled: &isFilled, useEmptyData: useEmptyData)
        case "[[chapters-count]]":
            return self.processPlaceholderChapters(placeholder, isFilled: &isFilled, forItem: item)
        case "[[engine]]":
            isFilled = true
            return engine.label
        default:
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        if self.processSpecialChaptersMenuItem(item, inMenu: destination_sub_menu) {
            return true
        }
        
        switch item.menuItem.template {
        case "[[video]]":
            let n = self.videoTracks.count
            guard n > 0 else {
                return true
            }
            
            let group_tracks = (self.globalSettings?.isTracksGrouped ?? true) // FIXME: rename
            let video_sub_menu: NSMenu
            let title = self.formatCount(videoTracks.count, noneLabel: "no Video track", singleLabel: "1 Video track", manyLabel: "%d Video tracks", useEmptyData: true, formatAsString: false)
            if group_tracks {
                video_sub_menu = NSMenu(title: title)
            } else {
                video_sub_menu = destination_sub_menu
            }
            for video in videoTracks {
                video.initJS = { settings in
                    return self.getJSContext()
                }
                guard let video_menu = video.getMenu(withItemSettings: self.globalSettings?.videoTrackSettings, globalSettings: self.globalSettings ?? Settings.getStandardSettings()) else {
                    continue
                }
                for (i, menu_item) in video_menu.items.enumerated() {
                    let mnu = menu_item.copy() as! NSMenuItem
                    var info = mnu.representedObject as? MenuItemInfo ?? item
                    info.userInfo["video_track_index"] = i
                    mnu.representedObject = info
                    video_sub_menu.addItem(mnu)
                }
            }
            if group_tracks {
                if n == 1 && (self.globalSettings?.isInfoOnMainItem ?? false) && video_sub_menu.items.count == 1 {
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
            let group_tracks = (self.globalSettings?.isTracksGrouped ?? true)
            let title = self.formatCount(audioTracks.count, noneLabel: "no Audio track", singleLabel: "1 Audio track", manyLabel: "%d Audio tracks", useEmptyData: true, formatAsString: false)
            if group_tracks {
                audio_sub_menu = NSMenu(title: title)
            } else {
                audio_sub_menu = destination_sub_menu
            }
            
            for audio in audioTracks {
                audio.initJS = { settings in
                    return self.getJSContext()
                }
                guard let audio_menu = audio.getMenu(withItemSettings: globalSettings?.audioTrackSettings, globalSettings: self.globalSettings ?? Settings.getStandardSettings()) else {
                    continue
                }
                for (i, menu_item) in audio_menu.items.enumerated() {
                    let mnu = menu_item.copy() as! NSMenuItem
                    var info = mnu.representedObject as? MenuItemInfo ?? item
                    info.userInfo["audio_track_index"] = i
                    mnu.representedObject = info
                    audio_sub_menu.addItem(mnu)
                }
            }
            if group_tracks {
                if n == 1 && (self.globalSettings?.isInfoOnMainItem ?? false) && audio_sub_menu.items.count == 1 {
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
            let group_tracks = (self.globalSettings?.isTracksGrouped ?? true) // FIXME: rename
            if group_tracks {
                let title = self.formatCount(n, noneLabel: "no Subtitle", singleLabel: "1 Subtitle", manyLabel: "%d Subtitles", useEmptyData: true, formatAsString: false)
                let mnu_txt = destination_sub_menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
                mnu_txt.image = self.getImage(for: "txt")
                sub_menu_txt = NSMenu(title: title)
                destination_sub_menu.setSubmenu(sub_menu_txt, for: mnu_txt)
            } else {
                sub_menu_txt = destination_sub_menu
            }
            for subtitle in subtitles {
                subtitle.initJS = { settings in
                    return self.getJSContext()
                }
                guard let subtitle_menu = subtitle.getMenu(globalSettings: self.globalSettings ?? Settings.getStandardSettings()) else {
                    continue
                }
                for (i, menu_item) in subtitle_menu.items.enumerated() {
                    let mnu = menu_item.copy() as! NSMenuItem
                    var info = item
                    info.userInfo["subtitle_index"] = i
                    mnu.representedObject = info
                    mnu.tag = item.index
                    sub_menu_txt.addItem(mnu)
                }
            }
        default:
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
        }
        
        return true
    }
}

// MARK: -
class AudioInfo: FileInfo, MediaInfo, ChaptersInfo {
    enum CodingKeys: String, CodingKey {
        case chapters
        case engine
        case engineName
        case audioTrack
    }
    var lang: String? {
        return audioTrack.lang
    }
    lazy var flagImage: NSImage? = {
        return self.getImageOfFlag()
    }()
    
    var duration: Double {
        return audioTrack.duration
    }
    
    var bitRate: Int64{
        return audioTrack.bitRate
    }
    
    var start_time: Double {
        return audioTrack.start_time
    }
    
    var codec_short_name: String {
        return audioTrack.codec_short_name
    }
    
    var codec_long_name: String? {
        return audioTrack.codec_long_name
    }
    
    var encoder: String? {
        return audioTrack.encoder
    }
    
    var isLossless: Bool? {
        return audioTrack.isLossless
    }
    
    var sampleRate: Double? {
        return self.spotlightMetadata[kMDItemAudioSampleRate as String] as? Double
    }
    
    let chapters: [Chapter]
    let engine: Settings.MediaEngine
    let audioTrack: AudioTrackInfo
    
    override class var infoType: Settings.SupportedFile { return .audio }
    override var standardMainItem: MenuItemInfo {
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "audio", template: "")) // FIXME: template
    }
    
    init(file: URL, duration: Double, start_time: Double, codec_short_name: String, codec_long_name: String?, lang: String?, bitRate: Int64, sampleRate: Double?, title: String?, encoder: String?, isLossless: Bool?, chapters: [Chapter], channels: Int, engine: Settings.MediaEngine) {
        self.chapters = chapters
        self.engine = engine
        self.audioTrack = AudioTrackInfo(duration: duration, start_time: start_time, codec_short_name: codec_short_name, codec_long_name: codec_long_name, lang: lang, bitRate: bitRate, sampleRate: sampleRate, title: title, encoder: encoder, isLossless: isLossless, channels: channels)
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let i = try container.decode(Int.self, forKey: .engine)
        self.engine = Settings.MediaEngine(rawValue: i)!
        self.chapters = try container.decode([Chapter].self, forKey: .chapters)
        self.audioTrack = try container.decode(AudioTrackInfo.self, forKey: .audioTrack)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.engine.rawValue, forKey: .engine)
        try container.encode(self.chapters, forKey: .chapters)
        try container.encode(self.audioTrack, forKey: .audioTrack)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.engine.label, forKey: .engineName)
        }
    }
    
    override func fetchMetadata(from metadata: MDItem) {
        super.fetchMetadata(from: metadata)
        var i: Int = 0
        var d: Double = 0
        
        if let m = MDItemCopyAttribute(metadata, kMDItemAppleLoopDescriptors), CFGetTypeID(m) == CFArrayGetTypeID() {
            // {Specifies multiple pieces of descriptive information about a loop. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemAppleLoopDescriptors as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAppleLoopsKeyFilterType), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {Specifies key filtering information about a loop. Loops are matched against projects that often in a major or minor key. A CFString.
            self.spotlightMetadata[kMDItemAppleLoopsKeyFilterType as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAppleLoopsLoopMode), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Specifies how a file should be played. A CFString.
            self.spotlightMetadata[kMDItemAppleLoopsLoopMode as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAppleLoopsRootKey), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Specifies the loop's original key. The key is the root note or tonic for the loop, and does not include the scale type. A CFString.
            self.spotlightMetadata[kMDItemAppleLoopsRootKey as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAudioChannelCount), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {Number of channels in the audio data contained in the file. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemAudioChannelCount as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAudioEncodingApplication), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The name of the application that encoded the data contained in the audio file. A CFString.
            self.spotlightMetadata[kMDItemAudioEncodingApplication as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAudioSampleRate), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {Sample rate of the audio data contained in the file. The sample rate is a float value representing hz (audio_frames/second). For example: 44100.0, 22254.54. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemAudioSampleRate as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAudioTrackNumber), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {The track number of a song or composition when it is part of an album. A CFNumber (integer).
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemAudioTrackNumber as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemComposer), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The composer of the music contained in the audio file. A CFString.
            self.spotlightMetadata[kMDItemComposer as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemIsGeneralMIDISequence), CFGetTypeID(m) == CFBooleanGetTypeID() {
            // {Indicates whether the MIDI sequence contained in the file is setup for use with a General MIDI device. A CFBoolean.
            let b = CFBooleanGetValue((m as! CFBoolean))
            self.spotlightMetadata[kMDItemIsGeneralMIDISequence as String] = NSLocalizedString(b ? "Yes" : "No", tableName: "LocalizableExt", comment: "")
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemKeySignature), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The key of the music contained in the audio file. For example: C, Dm, F#m, Bb. A CFString.
            self.spotlightMetadata[kMDItemKeySignature as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemLyricist), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The lyricist, or text writer, of the music contained in the audio file. A CFString.
            self.spotlightMetadata[kMDItemLyricist as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemMusicalGenre), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The musical genre of the song or composition contained in the audio file. For example: Jazz, Pop, Rock, Classical. A CFString.
            self.spotlightMetadata[kMDItemMusicalGenre as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemMusicalInstrumentCategory), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Specifies the category of an instrument. A CFString.
            self.spotlightMetadata[kMDItemMusicalInstrumentCategory as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemMusicalInstrumentName), CFGetTypeID(m) == CFStringGetTypeID() {
            // {Specifies the name of instrument relative to the instrument category. A CFString.
            self.spotlightMetadata[kMDItemMusicalInstrumentName as String] = m as! String
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemRecordingDate), CFGetTypeID(m) == CFDateGetTypeID() {
            // {The recording date of the song or composition.
            self.spotlightMetadata[kMDItemRecordingDate as String] = m as! Date
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemRecordingYear), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {Indicates the year the item was recorded. For example, 1964, 2003, etc. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &i)
            self.spotlightMetadata[kMDItemRecordingYear as String] = i
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemTempo), CFGetTypeID(m) == CFNumberGetTypeID() {
            // {A float value that specifies the beats per minute of the music contained in the audio file. A CFNumber.
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &d)
            self.spotlightMetadata[kMDItemTempo as String] = d
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemTimeSignature), CFGetTypeID(m) == CFStringGetTypeID() {
            // {The time signature of the musical composition contained in the audio/MIDI file. For example: "4/4", "7/8". A CFString.
            self.spotlightMetadata[kMDItemTimeSignature as String] = m as! String
        }
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "flag", let img = self.flagImage {
            return img
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        if let s = self.audioTrack.processAudioPlaceholder(placeholder, isFilled: &isFilled, forItem: item) {
            return s
        } else {
            switch placeholder {
            case "[[chapters-count]]":
                return self.processPlaceholderChapters(placeholder, isFilled: &isFilled, forItem: item)
            case "[[engine]]":
                isFilled = true
                return engine.label
            case "[[sample-rate]]":
                if let sampleRate = self.sampleRate {
                    isFilled = true;
                    if sampleRate > 1000 {
                        return String(format: "%.1f kHz", sampleRate/1000)
                    } else {
                        return String(format: "%.1f Hz", sampleRate)
                    }
                } else {
                    isFilled = false
                    return "? Hz"
                }
            default:
                return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
            }
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        
        if self.processSpecialChaptersMenuItem(item, inMenu: destination_sub_menu) {
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
        }
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
    lazy var flagImage: NSImage? = {
        return self.getImageOfFlag()
    }()
    

    override var standardMainItem: MenuItemInfo {
        let template = "[[title]] [[language-flag]]"
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "txt", template: template))
    }
    
    init(title: String?, lang: String?) {
        self.title = title
        self.lang = lang
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String?.self, forKey: .title)
        self.lang = try container.decode(String?.self, forKey: .lang)
        
        try super.init(from: decoder)
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
    
    override func getImage(for name: String) -> NSImage? {
        if name == "flag", let img = self.flagImage {
            return img
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        switch placeholder {
        case "[[title]]":
            isFilled = !(title?.isEmpty ?? true)
            return title ?? NSLocalizedString("Subtitle", comment: "")
        case "[[language]]", "[[language-flag]]":
            return processLanguagePlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        default:
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
    
    override func getStandardTitle() -> String {
        var item = standardMainItem
        if !(self.lang?.isEmpty ?? true) && !(self.globalSettings?.isIconHidden ?? false) && flagImage != nil {
            let template = item.menuItem.template.replacingOccurrences(of: "[[language-flag]]", with: "")
            item = MenuItemInfo(fileType: item.fileType, index: item.index, item: Settings.MenuItem(image: item.menuItem.image, template: template))
        }
        
        var isFilled = false
        let title: String = self.replacePlaceholders(in: item.menuItem.template, isFilled: &isFilled, forItem: item)
        return isFilled ? title : ""
    }
    
    override func getMenu(withItemSettings itemSettings: Settings.FormatSettings? = nil, globalSettings settings: Settings) -> NSMenu? {
        self.globalSettings = settings
        self.currentSettings = itemSettings
        
        let menu = NSMenu(title: NSLocalizedString("Subtitle", comment: ""))
        menu.autoenablesItems = false
        
        guard !((title?.isEmpty ?? true) && self.lang == nil) else {
            return nil
        }
        
        let destination_sub_menu: NSMenu = menu
        let title = self.getStandardTitle()
        if !title.isEmpty {
            let mnu = createMenuItem(title: title, image: "txt", representedObject: self.standardMainItem)
            if let image = self.flagImage {
                mnu.image = image
            }
            destination_sub_menu.addItem(mnu)
        }
        return menu
    }
}
