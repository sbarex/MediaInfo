//
//  MetadataMediaUtils.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 26/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation

/// Get image info for format supported by system via the file metadata.
func getMetadataImageInfo(forFile url: URL) -> ImageInfo? {
    guard let metadata = MDItemCreateWithURL(nil, url as CFURL) else {
        return nil
    }
    
    if let mdnames = MDItemCopyAttributeNames(metadata), let mdattrs: [String:Any] = MDItemCopyAttributes(metadata, mdnames) as? [String:Any] {
        print(mdattrs)
    }
    
    var width: Int = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemPixelWidth) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.intType, &width)
    }
    var height: Int = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemPixelHeight) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.intType, &height)
    }
    var dpi: Int = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemResolutionHeightDPI) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.intType, &dpi)
    }
    var colorSpace: String = ""
    if let n = MDItemCopyAttribute(metadata, kMDItemColorSpace) {
        colorSpace = n as! String
    }
    var bit: Int = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemBitsPerSample) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.intType, &bit)
    }
    var alpha = false
    if let n = MDItemCopyAttribute(metadata, kMDItemHasAlphaChannel) {
        alpha = CFBooleanGetValue((n as! CFBoolean))
    }
    
    return ImageInfo(file: url, width: width, height: height, dpi: dpi, colorMode: colorSpace, depth: bit, animated: false, withAlpha: alpha)
}


func getMetadataVideoInfo(forFile file: URL) -> VideoInfo? {
    guard let metadata = MDItemCreateWithURL(nil, file as CFURL) else {
        return nil
    }
    let streams = getMetadataMediaStreams(forFile: file, withMetadata: metadata)
    
    if let v = streams.first(where: {$0 is VideoTrackInfo}) as? VideoTrackInfo {
        let title = MDItemCopyAttribute(metadata, kMDItemTitle) as? String
        var duration = v.duration
        if let n = MDItemCopyAttribute(metadata, kMDItemDurationSeconds) {
            CFNumberGetValue((n as! CFNumber), CFNumberType.doubleType, &duration)
        }
        
        let video = VideoInfo(
            file: file,
            width: v.width, height: v.height,
            duration: duration,
            start_time: -1,
            codec_short_name: v.codec_short_name, codec_long_name: v.codec_long_name,
            profile: v.profile, pixel_format: v.pixel_format,
            color_space: v.color_space, field_order: v.field_order,
            lang: v.lang,
            bitRate: v.bitRate, fps: v.fps, frames: v.frames,
            title: title ?? v.title,
            encoder: v.encoder,
            isLossless: v.isLossless,
            chapters: [],
            video: streams.filter({ $0 is VideoTrackInfo }) as! [VideoTrackInfo],
            audio: streams.filter({ $0 is AudioTrackInfo }) as! [AudioTrackInfo],
            subtitles: streams.filter({ $0 is SubtitleTrackInfo }) as! [SubtitleTrackInfo],
            engine: .metadata
        )
        return video
    } else {
        return nil
    }
}

func getMetadataAudioInfo(forFile file: URL) -> AudioInfo? {
    guard let metadata = MDItemCreateWithURL(nil, file as CFURL) else {
        return nil
    }
    let streams = getMetadataMediaStreams(forFile: file, withMetadata: metadata)
    
    if let a =  streams.first(where: {$0 is AudioTrackInfo }) as? AudioTrackInfo  {
        let title = MDItemCopyAttribute(metadata, kMDItemTitle) as? String
        var duration = a.duration
        if let n = MDItemCopyAttribute(metadata, kMDItemDurationSeconds) {
            CFNumberGetValue((n as! CFNumber), CFNumberType.doubleType, &duration)
        }
        let audio = AudioInfo(
            file: file,
            duration: duration, start_time: -1,
            codec_short_name: a.codec_short_name, codec_long_name: a.codec_long_name,
            lang: a.lang,
            bitRate: a.bitRate,
            title: title ?? a.title,
            encoder: a.encoder,
            isLossless: a.isLossless,
            chapters: [],
            channels: a.channels,
            engine: .metadata
        )
        return audio
    } else {
        return nil
    }
}
    
/// Get media info for video/audio format supported by system via the file metadata.
func getMetadataMediaStreams(forFile file: URL) -> [BaseInfo] {
    guard let metadata = MDItemCreateWithURL(nil, file as CFURL) else {
        return []
    }
    return getMetadataMediaStreams(forFile: file, withMetadata: metadata)
}

func getMetadataMediaStreams(forFile file: URL, withMetadata metadata: MDItem) -> [BaseInfo] {
    var streams: [BaseInfo] = []
    
    if let mdnames = MDItemCopyAttributeNames(metadata), let mdattrs: [String:Any] = MDItemCopyAttributes(metadata, mdnames) as? [String:Any] {
        print(mdattrs)
    }
    
    var types: [String] = []
    if let v = MDItemCopyAttribute(metadata, kMDItemMediaTypes) {
        // Unsupported media type do not have the kMDItemMediaTypes attribute.
        if let a = v as? [CFString] {
            types = a.map({ $0 as String})
        }
    }
    
    var codecs: [String] = []
    if let n = MDItemCopyAttribute(metadata, kMDItemCodecs) {
        if let a = n as? [CFString] {
            codecs = a.map({ $0 as String})
        }
    }
    
    var langs: [String] = []
    if let n = MDItemCopyAttribute(metadata, kMDItemLanguages) {
        if let a = n as? [CFString] {
            langs = a.map({ $0 as String})
        }
    }
    
    var duration: Double = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemDurationSeconds) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.doubleType, &duration)
    }
        
    var width: Int = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemPixelWidth) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.intType, &width)
    }
    var height: Int = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemPixelHeight) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.intType, &height)
    }
    
    var videoBitRate: Int64 = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemVideoBitRate) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.sInt64Type, &videoBitRate)
    }
    
    var audioBitRate: Int64 = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemAudioBitRate) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.sInt64Type, &audioBitRate)
    }
    
    var channels: Int = 0
    if let n = MDItemCopyAttribute(metadata, kMDItemAudioChannelCount) {
        CFNumberGetValue((n as! CFNumber), CFNumberType.sInt64Type, &channels)
    }
    
    
    for (i, type) in types.enumerated() {
        let codec = i < codecs.count ? codecs[i] : ""
        let lang = i < langs.count ? langs[i] : nil
        
        switch type {
        case "Video":
            
            let v = VideoTrackInfo(
                width: width, height: height,
                duration: duration,
                start_time: 0,
                codec_short_name: codec, codec_long_name: nil,
                profile: nil,
                pixel_format: nil, color_space: nil,
                field_order: nil,
                lang: lang,
                bitRate: videoBitRate, fps: 0,
                frames: 0,
                title: nil, encoder: nil,
                isLossless: nil
            )
            streams.append(v)
        case "Sound":
            let a = AudioTrackInfo(
                duration: duration, start_time: -1,
                codec_short_name: codec, codec_long_name: nil,
                lang: lang,
                bitRate: audioBitRate,
                title: nil, encoder: nil,
                isLossless: nil,
                channels: channels
            )
            streams.append(a)
        default:
            break
        }
    }

    return streams
}
