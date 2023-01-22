//
//  CGImageUtils.swift
//  MediaInfo
//
//  Created by Sbarex on 17/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

extension FourCharCode {
    // Create a String representation of a FourCC
    func toString() -> String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xff),
            CChar((self >> 16) & 0xff),
            CChar((self >> 8) & 0xff),
            CChar(self & 0xff),
            0
        ]
        let result = String(cString: bytes)
        let characterSet = CharacterSet.whitespaces
        return result.trimmingCharacters(in: characterSet)
    }
}

extension AVAssetTrack {
    var mediaFormat: String {
        var format = ""
        let descriptions = self.formatDescriptions as! [CMFormatDescription]
        for (index, formatDesc) in descriptions.enumerated() {
            // Get String representation of media type (vide, soun, sbtl, etc.)
            let type = CMFormatDescriptionGetMediaType(formatDesc).toString()
            // Get String representation media subtype (avc1, aac, tx3g, etc.)
            let subType = CMFormatDescriptionGetMediaSubType(formatDesc).toString()
            // Format string as type/subType
            format += "\(type)/\(subType)"
            // Comma separate if more than one format description
            if index < descriptions.count - 1 {
                format += ","
            }
        }
        return format
    }
}

/// Get image info for image format supported by coregraphics.
func getCGImageInfo(forFile url: URL, processMetadata: Bool) -> ImageInfo? {
    // Create the image source
    let time = CFAbsoluteTimeGetCurrent()
    os_log("Fetch info for image %{private}@ (%{public}@) with Core Graphics…", log: OSLog.infoExtraction, type: .debug, url.path, processMetadata ? "with metadata" : "without metadata")
    guard let img_src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        os_log("Unable to open the image %{private}@ with Core Graphics!", log: OSLog.infoExtraction, type: .error, url.path)
        return nil
    }

    // Copy images properties
    guard let img_properties = CGImageSourceCopyPropertiesAtIndex(img_src, 0, nil) else {
        os_log("Unable to get image properties with Core Graphics!", log: OSLog.infoExtraction, type: .error)
        return nil
    }
    
    func getKey<T: AnyObject>(_ key: CFString, inDictionary dict: CFDictionary) -> T? {
        if let rawResult = CFDictionaryGetValue(dict, Unmanaged.passUnretained(key).toOpaque()) {
            let v = Unmanaged<T>.fromOpaque(rawResult).takeUnretainedValue()
            return v
        } else {
            return nil
        }
    }

    // Get image width
    var n: CFNumber = getKey(kCGImagePropertyPixelWidth, inDictionary: img_properties) ?? 0 as CFNumber
    var width: size_t = 0
    CFNumberGetValue(n, CFNumberType.sInt64Type, &width)

    // Get image height
    n = getKey(kCGImagePropertyPixelHeight, inDictionary: img_properties) ?? 0 as CFNumber
    var height: size_t = 0
    CFNumberGetValue(n, CFNumberType.sInt64Type, &height)

    // Get DPI
    n = getKey(kCGImagePropertyDPIWidth, inDictionary: img_properties) ?? 0 as CFNumber
    var dpi: size_t = 0
    CFNumberGetValue(n, CFNumberType.sInt64Type, &dpi)

    n = getKey(kCGImagePropertyDepth, inDictionary: img_properties) ?? 0 as CFNumber
    var depth = 0
    CFNumberGetValue(n, CFNumberType.nsIntegerType, &depth)
    
    let s: CFString = getKey(kCGImagePropertyColorModel, inDictionary: img_properties) ?? "" as CFString
    let color: String = s as String
    
    // Get the filesize, because it's not always present in the image properties dictionary :/
    // file_size = get_file_size(url)
    
    n = getKey(kCGImagePropertyHasAlpha, inDictionary: img_properties) ?? 0 as CFNumber
    var alpha: Int = 0
    CFNumberGetValue(n, CFNumberType.sInt8Type, &alpha)
    
    let images = CGImageSourceGetCount(img_src)
    
    // Get the profile name
    let cp:CFString = getKey(kCGImagePropertyProfileName, inDictionary: img_properties) ?? "" as CFString
    
    var b: CFBoolean = getKey(kCGImagePropertyIsFloat, inDictionary: img_properties) ?? kCFBooleanFalse
    let isFloat = b == kCFBooleanTrue
    b = getKey(kCGImagePropertyIsIndexed, inDictionary: img_properties) ?? kCFBooleanFalse
    let isIndexed = b == kCFBooleanTrue
    
    var metadata: [String: [MetadataInfo]] = [:]
    var metadata_raw: [String: String] = [:]
    
    if processMetadata {
        os_log("Fetch metadata…", log: OSLog.infoExtraction, type: .debug)
        if let i: CFDictionary = getKey(kCGImagePropertyExifDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Exif"] = s
            }
            let meta = ImageInfo.parseExif(dict: dict)
            if !meta.isEmpty {
                metadata["Exif"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyExifAuxDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["ExifAux"] = s
            }
            let meta = ImageInfo.parseExif(dict: dict)
            if !meta.isEmpty {
                metadata["ExifAux"] = meta
            }
        }
        
        if let i: CFDictionary = getKey(kCGImagePropertyTIFFDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["TIFF"] = s
            }
            let meta = ImageInfo.parseTiffDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["TIFF"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyJFIFDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["JFIF"] = s
            }
            let meta = ImageInfo.parseJfifDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["JFIF"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyGIFDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["GIF"] = s
            }
            let meta = ImageInfo.parseGifDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["GIF"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyHEICSDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["HEICS"] = s
            }
            let meta = ImageInfo.parseHeicsDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["HEICS"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyPNGDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["PNG"] = s
            }
            let meta = ImageInfo.parsePngDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["PNG"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyIPTCDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["IPTC"] = s
            }
            let meta = ImageInfo.parseIptcDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["IPTC"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyGPSDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["GPS"] = s
            }
            let meta = ImageInfo.parseGPSDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["GPS"] = meta
            }
        }
        
        if let i: CFDictionary = getKey(kCGImagePropertyRawDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["RAW"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["RAW"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyMakerCanonDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Canon"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["Canon"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyMakerNikonDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Nicon"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["Nicon"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyMakerMinoltaDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Minolta"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["Minolta"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyMakerFujiDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Fuji"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["Fuji"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyMakerOlympusDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Olympus"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["Olympus"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyMakerPentaxDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Pentax"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["Pentax"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImageProperty8BIMDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["8BIM"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["8BIM"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyDNGDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["DNG"] = s
            }
            let meta = ImageInfo.parseDNGDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["DNG"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyOpenEXRDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["OpenEXR"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["OpenEXR"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyMakerAppleDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["Apple"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["Apple"] = meta
            }
        }
        if let i: CFDictionary = getKey(kCGImagePropertyFileContentsDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
            if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                metadata_raw["File"] = s
            }
            let meta = ImageInfo.parseMetadataDictionary(dict: dict)
            if !meta.isEmpty {
                metadata["File"] = meta
            }
        }
        if #available(macOS 11.0, *) {
            if let i: CFDictionary = getKey(kCGImagePropertyWebPDictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
                if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                    metadata_raw["WebP"] = s
                }
                let meta = ImageInfo.parseMetadataDictionary(dict: dict)
                if !meta.isEmpty {
                    metadata["WebP"] = meta
                }
            }
            if let i: CFDictionary = getKey(kCGImagePropertyTGADictionary, inDictionary: img_properties), let dict = i as? [CFString: AnyHashable] {
                if JSONSerialization.isValidJSONObject(dict), let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []), let s = String(data: jsonData, encoding: .utf8) {
                    metadata_raw["TGA"] = s
                }
                let meta = ImageInfo.parseMetadataDictionary(dict: dict)
                if !meta.isEmpty {
                    metadata["TGA"] = meta
                }
            }
        }
    }
    os_log("Image info fetched with Core Graphics in %{public}lf seconds.", log: OSLog.infoExtraction, type: .info, CFAbsoluteTimeGetCurrent() - time)
    return ImageInfo(file: url, width: width, height: height, dpi: dpi, colorMode: color, depth: depth, profileName: cp as String, animated: images > 1, withAlpha: alpha > 0, colorTable: isFloat ? .float : (isIndexed ? .indexed : .regular), metadata: metadata, metadataRaw: metadata_raw)
}

func codecForVideoCode(_ code: FourCharCode?) -> String? {
    guard let code = code else {
        return nil
    }
    return NSFileTypeForHFSTypeCode(code)?.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
}

func codecForVideoAsset(asset: AVURLAsset, mediaType: CMMediaType) -> String? {
    let formatDescriptions = asset.tracks.flatMap { $0.formatDescriptions }
    let code = formatDescriptions
        .filter { CMFormatDescriptionGetMediaType($0 as! CMFormatDescription) == mediaType }
        .map { CMFormatDescriptionGetMediaSubType($0 as! CMFormatDescription) }.first
    
    if let code = code {
        return codecForVideoCode(code)
        // let a = CMFormatDescription.MediaSubType(rawValue: code)
    }
    return nil //return code?.toString()
}

func longCodecForVideoCode(_ code: FourCharCode?) -> String? {
    guard let code = code else {
        return nil
    }
    switch code {
    case kCMVideoCodecType_422YpCbCr8: return "Component Y'CbCr 8-bit 4:2:2 ordered Cb Y'0 Cr Y'1"
    case kCMVideoCodecType_Animation: return "Apple Animation"
    case kCMVideoCodecType_Cinepak: return "Cinepak"
    case kCMVideoCodecType_JPEG: return "Joint Photographic Experts Group (JPEG)"
    case kCMVideoCodecType_JPEG_OpenDML: return "JPEG format with Open-DML extensions"
    case kCMVideoCodecType_SorensonVideo: return "Sorenson video"
    case kCMVideoCodecType_SorensonVideo3: return "Sorenson 3 video"
    case kCMVideoCodecType_H263: return "H.263 format"
    case kCMVideoCodecType_H264: return "H.264 format (MPEG-4 Part 10)"
    case kCMVideoCodecType_HEVC: return "HEVC"
    case kCMVideoCodecType_HEVCWithAlpha: return "HEVC with alpha"
    case kCMVideoCodecType_DolbyVisionHEVC: return "HEVC Dolby Vision"
    case kCMVideoCodecType_MPEG4Video: return "MPEG-4 Part 2 video format"
    case kCMVideoCodecType_MPEG2Video: return "MPEG-2 video"
    case kCMVideoCodecType_MPEG1Video: return "MPEG-1 video"
    case kCMVideoCodecType_VP9: return "Google VP9"
    case kCMVideoCodecType_DVCNTSC: return "DV NTSC"
    case kCMVideoCodecType_DVCPAL: return "DV PAL"
    case kCMVideoCodecType_DVCProPAL: return "Panasonic DVCPro PAL"
    case kCMVideoCodecType_DVCPro50NTSC: return "Panasonic DVCPro-50 NTSC"
    case kCMVideoCodecType_DVCPro50PAL: return "Panasonic DVCPro-50 PAL"
    case kCMVideoCodecType_DVCPROHD720p60: return "Panasonic DVCPro-HD 720p60"
    case kCMVideoCodecType_DVCPROHD720p50: return "Panasonic DVCPro-HD 720p50"
    case kCMVideoCodecType_DVCPROHD1080i60: return "Panasonic DVCPro-HD 1080i60"
    case kCMVideoCodecType_DVCPROHD1080i50: return "Panasonic DVCPro-HD 1080i50"
    case kCMVideoCodecType_DVCPROHD1080p30: return "Panasonic DVCPro-HD 1080i30"
    case kCMVideoCodecType_DVCPROHD1080p25: return "Panasonic DVCPro-HD 1080i25"

    case kCMVideoCodecType_AppleProRes4444XQ: return "Apple ProRes 4444XQ"
    case kCMVideoCodecType_AppleProRes4444: return "Apple ProRes 4444"
    case kCMVideoCodecType_AppleProRes422HQ: return "Apple ProRes 422 HQ"
    case kCMVideoCodecType_AppleProRes422: return "Apple ProRes 422"
    case kCMVideoCodecType_AppleProRes422LT: return "Apple ProRes 422 LT"
    case kCMVideoCodecType_AppleProRes422Proxy: return "Apple ProRes 422 Proxy"

    case kCMVideoCodecType_AppleProResRAW: return "Apple ProRes RAW"
    case kCMVideoCodecType_AppleProResRAWHQ: return "Apple ProRes RAW HQ"
        
    case 1635148593: // avc1
        return "H.264 video stream"
    
        // FIXME
        /*
    case 0:
        return "MPEG-2 transport (muxed) stream"
    case -1:
        return "AAC audio stream"
 */
    default:
        return nil
    }
}

func longCodecForVideoAsset(asset: AVURLAsset, mediaType: CMMediaType) -> String? {
    let formatDescriptions = asset.tracks.flatMap { $0.formatDescriptions }
    let code = formatDescriptions
        .filter { CMFormatDescriptionGetMediaType($0 as! CMFormatDescription) == mediaType }
        .map { CMFormatDescriptionGetMediaSubType($0 as! CMFormatDescription) }.first
    
    guard let code = code else {
        return nil
    }
    return longCodecForVideoCode(code)
}

func initAudioInfo(from streams: [BaseInfo]) -> AudioInfo? {
    return streams.first(where: {$0 is AudioInfo}) as? AudioInfo
}

/// Get media info for video/audio format supported by coregraphics.
func getCMVideoInfo(forFile file: URL) -> VideoInfo? {
    return getCMMediaInfo(forFile: file) as? VideoInfo
}

func getCMAudioInfo(forFile file: URL) -> AudioInfo? {
    return getCMMediaInfo(forFile: file) as? AudioInfo
}

func getCMMediaInfo(forFile file: URL) -> MediaInfo? {
    let asset = AVURLAsset(url: file)
    let streams: [BaseInfo] = getCMMediaStreams(forFile: file)
    
    var chapters: [Chapter] = []
    
    let cc = asset.chapterMetadataGroups(bestMatchingPreferredLanguages: asset.availableChapterLocales.map( { $0.identifier }))
    for c in cc {
        for item in c.items {
            let title = item.stringValue
            let start = CMTimeGetSeconds(item.time)
            let chapter = Chapter(title: title, start: start, end: start + CMTimeGetSeconds(item.duration))
            chapters.append(chapter)
        }
    }
    
    var title: String? = nil
    var encoder: String? = nil
    for m in asset.metadata {
        if m.commonKey == .commonKeyTitle {
            title = m.stringValue
        } else if m.commonKey == .commonKeySoftware {
            encoder = m.stringValue
        } else {
            print(m.commonKey?.rawValue ?? "", m.stringValue ?? "")
        }
    }
    
    if let v = streams.first(where: {$0 is VideoTrackInfo}) as? VideoTrackInfo {
        let video = VideoInfo(
            file: file,
            width: v.width, height: v.height,
            duration: CMTimeGetSeconds(asset.duration),
            start_time: -1,
            codec_short_name: v.codec_short_name, codec_long_name: v.codec_long_name,
            profile: v.profile, pixel_format: v.pixel_format,
            color_space: v.color_space, field_order: v.field_order,
            lang: v.lang,
            bitRate: v.bitRate, fps: v.fps, frames: v.frames,
            title: title ?? v.title,
            encoder: encoder ?? v.encoder,
            isLossless: v.isLossless,
            chapters: chapters,
            video: streams.filter({ $0 is VideoTrackInfo }) as! [VideoTrackInfo],
            audio: streams.filter({ $0 is AudioTrackInfo }) as! [AudioTrackInfo],
            subtitles: streams.filter({ $0 is SubtitleTrackInfo }) as! [SubtitleTrackInfo],
            engine: .coremedia
        )
        return video
    } else if let a = streams.first(where: {$0 is AudioTrackInfo }) as? AudioTrackInfo  {
        let audio = AudioInfo(
            file: file,
            duration: CMTimeGetSeconds(asset.duration), start_time: -1,
            codec_short_name: a.codec_short_name, codec_long_name: a.codec_long_name,
            lang: a.lang,
            bitRate: a.bitRate,
            sampleRate: a.sampleRate,
            title: title ?? a.title,
            encoder: encoder ?? a.encoder,
            isLossless: a.isLossless,
            chapters: chapters,
            channels: a.channels,
            engine: .coremedia
        )
        return audio
    } else {
        return nil
    }
}

func getCMMediaStreams(forFile file: URL) -> [BaseInfo] {
    let time = CFAbsoluteTimeGetCurrent()
    os_log("Fetch info for media %{private}@ with Core Graphics…", log: OSLog.infoExtraction, type: .debug, file.path)
    
    let asset = AVURLAsset(url: file)
    var streams: [BaseInfo] = []
    
    for track in asset.tracks {
        let lang: String
        if track.languageCode != "und", let lc = track.languageCode {
            if let l = ISO649_2_to_1(code: lc) {
                lang = l
            } else {
                lang = lc
            }
        } else {
            lang = ""
        }
        
        var title: String? = nil
        var encoder: String? = nil
        for m in asset.metadata {
            if m.commonKey == .commonKeyTitle {
                title = m.stringValue
            } else if m.commonKey == .commonKeySoftware {
                encoder = m.stringValue
            } else {
                print(m.commonKey?.rawValue ?? "", m.stringValue ?? "")
            }
        }
        
        switch track.mediaType {
        case .video:
            let durationInSeconds = CMTimeGetSeconds(track.timeRange.duration)
            let startTime = CMTimeGetSeconds(track.timeRange.start)
            
            let framesPerSecond = Double(track.nominalFrameRate)
            let numberOfFrames = Int((durationInSeconds * framesPerSecond).rounded())
            // let d = track.formatDescriptions.first as! CMVideoFormatDescription
            let formatDescriptions = track.formatDescriptions as! [CMFormatDescription]
            var mediaType: FourCharCode?
            if let formatDesc = formatDescriptions.first {
                mediaType = formatDesc.mediaSubType.rawValue
            }
            
            let v = VideoTrackInfo(
                width: Int(track.naturalSize.width), height: Int(track.naturalSize.height),
                duration: durationInSeconds, start_time: startTime,
                codec_short_name: codecForVideoCode(mediaType) ?? "",
                codec_long_name: longCodecForVideoCode(mediaType),
                profile: nil,
                pixel_format: nil, color_space: nil, field_order: nil,
                lang: lang,
                bitRate: Int64(track.estimatedDataRate),
                fps: track.minFrameDuration.isNumeric ? 1 / track.minFrameDuration.seconds : 0,
                frames: numberOfFrames,
                title: title,
                encoder: encoder,
                isLossless: nil
            )
            streams.append(v)
            
        case .audio:
            let durationInSeconds = CMTimeGetSeconds(track.timeRange.duration)
            let startTime = CMTimeGetSeconds(track.timeRange.start)
            let formatDescriptions = track.formatDescriptions as! [CMFormatDescription]
            
            var channels = -1
            var mediaType: FourCharCode? = nil
            var sampleRate: Double? = nil
            if let formatDesc = formatDescriptions.first {
                if let basic = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
                    channels = Int(basic.pointee.mChannelsPerFrame)
                    sampleRate = basic.pointee.mSampleRate
                }
                mediaType = formatDesc.mediaSubType.rawValue
            }
            
            let a = AudioTrackInfo(
                duration: durationInSeconds, start_time: startTime,
                codec_short_name: codecForVideoCode(mediaType) ?? "",
                codec_long_name: longCodecForVideoCode(mediaType),
                lang: lang,
                bitRate: Int64(track.estimatedDataRate),
                sampleRate: sampleRate, 
                title: title,
                encoder: encoder,
                isLossless: nil,
                channels: channels
            )
            streams.append(a)

        case .subtitle:
            let t = SubtitleTrackInfo(title: title, lang: lang)
            streams.append(t)
            break

        default:
            break
        }
    }
    
    os_log("Media info fetched with Core Graphics in %{public}lf seconds.", log: OSLog.infoExtraction, type: .info, CFAbsoluteTimeGetCurrent() - time)
    return streams
}
