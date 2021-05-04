//
//  VideoUtils.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 26/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation


enum StreamType {
    case video(width: Int, height: Int, duration: Double, codec: String, ratio: String?, lang: String?, bit_rate: Int64, frames: Int)
    case image(width: Int, height: Int, codec: String)
    case audio(duration: Double, codec: String, lang: String?, bit_rate: Int64)
    case subtitle(title: String?, lang: String?)
    case attachment
    
    var index: Int {
        switch self {
        case .video(_, _, _, _, _, _, _, _):
            return 1
        case .image(_, _, _):
            return 2
        case .audio(_, _, _, _):
            return 3
        case .subtitle(_, _):
            return 4
        case .attachment:
            return 5
        }
    }
}
struct StreamInfo {
    let type: StreamType
    let width: Int
    let height: Int
    let duration: Double
}

func codecForVideoAsset(asset: AVURLAsset, mediaType: CMMediaType) -> String? {
    let formatDescriptions = asset.tracks.flatMap { $0.formatDescriptions }
    let mediaSubtypes = formatDescriptions
        .filter { CMFormatDescriptionGetMediaType($0 as! CMFormatDescription) == mediaType }
        .map { CMFormatDescriptionGetMediaSubType($0 as! CMFormatDescription).toString() }
    return mediaSubtypes.first
}

extension FourCharCode {
    func toString() -> String {
        let n = Int(self)
        var s: String = String (UnicodeScalar((n >> 24) & 255)!)
        s.append(String(UnicodeScalar((n >> 16) & 255)!))
        s.append(String(UnicodeScalar((n >> 8) & 255)!))
        s.append(String(UnicodeScalar(n & 255)!))
        return s.trimmingCharacters(in: .whitespaces)
    }
}

/// Get media info for video/audio format supported by system via the file metadata.
func getMetadataVideoInfo(forFile url: URL) -> [StreamType] {
    guard let metadata = MDItemCreateWithURL(nil, url as CFURL) else {
        return []
    }
    
    var r: [StreamType] = []
    
    
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
    
    for (i, type) in types.enumerated() {
        switch type {
        case "Video":
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
            
            let codec = i < codecs.count ? codecs[i] : ""
            let lang = i < langs.count ? langs[i] : nil
            
            let video = StreamType.video(width: width, height: height, duration: duration, codec: codec, ratio: nil, lang: lang, bit_rate: videoBitRate, frames: 0)
            
            r.append(video)
        case "Sound":
            let codec = i < codecs.count ? codecs[i] : ""
            let lang = i < langs.count ? langs[i] : nil
            
            var audioBitRate: Int64 = 0
            if let n = MDItemCopyAttribute(metadata, kMDItemAudioBitRate) {
                CFNumberGetValue((n as! CFNumber), CFNumberType.sInt64Type, &audioBitRate)
            }
            
            let audio = StreamType.audio(duration: duration, codec: codec, lang: lang, bit_rate: audioBitRate)
            r.append(audio)
        default:
            break
        }
    }
    
    return r
}

/// Get media info for video/audio format supported by coregraphics.
func getCMVideoInfo(forFile url: URL) -> [StreamType] {
    var streams: [StreamType] = []
    let asset = AVAsset(url: url)
    let asset2 = AVURLAsset(url: url)
    for track in asset2.tracks {
        let lang = track.languageCode != "und" ?  track.languageCode : ""
        switch track.mediaType {
        case .video:
            let durationInSeconds = CMTimeGetSeconds(asset.duration)
            let framesPerSecond = Double(track.nominalFrameRate)
            let numberOfFrames = Int((durationInSeconds * framesPerSecond).rounded())
            
            let v: StreamType = StreamType.video(width: Int(track.naturalSize.width), height: Int(track.naturalSize.height), duration: durationInSeconds, codec: codecForVideoAsset(asset: asset2, mediaType: kCMMediaType_Video) ?? "", ratio: nil, lang: lang, bit_rate: Int64(track.estimatedDataRate), frames: numberOfFrames)
            streams.append(v)
        case .audio:
            let v: StreamType = StreamType.audio(duration: CMTimeGetSeconds(asset.duration), codec: codecForVideoAsset(asset: asset2, mediaType: kCMMediaType_Video) ?? "", lang: lang, bit_rate: Int64(track.estimatedDataRate))
            streams.append(v)
        case .subtitle:
            var title: String?
            for m in track.commonMetadata {
                if m.commonKey?.rawValue == "title" {
                    title = m.value as? String
                }
            }
            let v: StreamType = StreamType.subtitle(title: title, lang: lang)
            streams.append(v)
            break
        default:
            break
        }
    }
    
    return streams
}

/// Get media info for video/audio format supported by ffmpeg.
func getFFMpegInfo(forFile file: URL) -> [StreamType] {
    var pFormatCtx: UnsafeMutablePointer<AVFormatContext>! = nil
    let pFmt: UnsafeMutablePointer<AVInputFormat>? = nil
    
    let _ = avformat_open_input(&pFormatCtx, strdup(file.path), pFmt, nil)
    guard pFormatCtx != nil else {
        return []
    }
    
    // Retrieve stream information
    guard avformat_find_stream_info(pFormatCtx, nil) >= 0 else {
        avformat_close_input(&pFormatCtx)
        return []
    }
    defer {
        avformat_close_input(&pFormatCtx)
        avformat_free_context(pFormatCtx)
    }
    
    var streams: [StreamType] = []

    for i in 0 ..< Int(pFormatCtx.pointee.nb_streams) {
        guard let pCodecCtx = pFormatCtx.pointee.streams[i]?.pointee.codecpar.pointee else {
            continue
        }
        
        var t: UnsafeMutablePointer<AVDictionaryEntry>?
        repeat {
            t = av_dict_get(pFormatCtx.pointee.streams[i]!.pointee.metadata, "", t, AV_DICT_IGNORE_SUFFIX)
            if let tt = t?.pointee {
                print("\(String(cString: tt.key)): \(String(cString: tt.value))")
            }
        } while t != nil
        
        let lang: String
        if let t = av_dict_get(pFormatCtx.pointee.streams[i]!.pointee.metadata, "language", nil, 0) {
            let l = String(cString: ff_convert_lang_to(t.pointee.value, AV_LANG_ISO639_1))
            lang = l != "und" ? l : ""
        } else {
            lang = ""
        }
        
        var bps: Int64
        if let t = av_dict_get(pFormatCtx.pointee.streams[i]!.pointee.metadata, "BPS-eng", nil, 0), let n = Int64(String(cString: t.pointee.value)) {
            bps = n
        } else {
            bps = pFormatCtx.pointee.bit_rate
        }
        
        switch pCodecCtx.codec_type {
        case AVMEDIA_TYPE_VIDEO:
            let ratio = pCodecCtx.sample_aspect_ratio.num == 0 ? "" : "\(pCodecCtx.sample_aspect_ratio.num):\(pCodecCtx.sample_aspect_ratio.den)"
            
            var duration = pFormatCtx.pointee.streams[i]!.pointee.duration
            if abs(Double(duration)) == 9223372036854775808 {
                duration = 0
            }
            if duration == 0 {
                duration = pFormatCtx.pointee.duration
            }
            
            var frames = pFormatCtx.pointee.streams[i]!.pointee.nb_frames
            if frames == 0 && pFormatCtx.pointee.streams[i]!.pointee.avg_frame_rate.num != 0 {
                frames = Int64((Double(duration) / (Double(pFormatCtx.pointee.streams[i]!.pointee.avg_frame_rate.num) / Double(pFormatCtx.pointee.streams[i]!.pointee.avg_frame_rate.den))).rounded())
            }
            streams.append(StreamType.video(width: Int(pCodecCtx.width), height: Int(pCodecCtx.height), duration: Double(duration)/1000000, codec: String(cString: avcodec_get_name(pCodecCtx.codec_id)), ratio: ratio, lang: lang, bit_rate: bps, frames: Int(frames)))
        case AVMEDIA_TYPE_AUDIO:
            var duration = pFormatCtx.pointee.streams[i]!.pointee.duration
            if abs(Double(duration)) == 9223372036854775808 {
                duration = 0
            }
            if duration == 0 {
                duration = pFormatCtx.pointee.duration
            }
            streams.append(StreamType.audio(duration: Double(duration)/1000000, codec: String(cString: avcodec_get_name(pCodecCtx.codec_id)), lang: lang, bit_rate: bps))
        case AVMEDIA_TYPE_SUBTITLE:
            let title: String?
            if let t = av_dict_get(pFormatCtx.pointee.streams[i]!.pointee.metadata, "title", nil, 0) {
                title = String(cString: t.pointee.value)
            } else {
                title = nil
            }
            
            streams.append(StreamType.subtitle(title: title, lang: lang))
        case AVMEDIA_TYPE_ATTACHMENT:
            // streams.append(StreamType.attachment)
            break
        default:
            break
        }
    }

    return streams
}

/// Get image info if the format is supported by coregraphics.
func getFFMpegImageInfo(forFile file: URL) -> ImageInfo? {
    let streams = getFFMpegInfo(forFile: file)
    for stream in streams {
        switch stream {
        case .video(let width, let height, _, _, _, _, _, let frames):
            return ImageInfo(width: width, height: height, dpi: 0, colorMode: "", depth: 0, animated: frames > 1)
        default:
            break
        }
    }
    return nil
}
