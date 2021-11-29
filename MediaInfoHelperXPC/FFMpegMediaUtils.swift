//
//  FFMpegMediaUtils.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 22/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

let AV_NOPTS_VALUE = UInt64(0x8000000000000000) // Int64.max + 1
let AV_TIME_BASE: Int64 = 1_000_000

extension VideoPixelFormat {
    init?(pix_fmt: AVPixelFormat) {
        switch pix_fmt {
        case AV_PIX_FMT_NONE: return nil
        case AV_PIX_FMT_YUV420P: self = .yuv420p
        case AV_PIX_FMT_YUYV422: self = .yuyv422
        case AV_PIX_FMT_YVYU422: self = .yvyu422
        case AV_PIX_FMT_Y210LE: self = .y210le
        case AV_PIX_FMT_Y210BE: self = .y210be
        case AV_PIX_FMT_RGB24: self = .rgb24
        case AV_PIX_FMT_BGR24: self = .bgr24
        case AV_PIX_FMT_X2RGB10LE: self = .x2rgb10le
        case AV_PIX_FMT_X2RGB10BE: self = .x2rgb10be
        case AV_PIX_FMT_YUV422P: self = .yuv422p
        case AV_PIX_FMT_YUV444P: self = .yuv444p
        case AV_PIX_FMT_YUV410P: self = .yuv410p
        case AV_PIX_FMT_YUV411P: self = .yuv411p
        case AV_PIX_FMT_YUVJ411P: self = .yuvj411p
        case AV_PIX_FMT_GRAY8: self = .gray
        case AV_PIX_FMT_MONOWHITE: self = .monow
        case AV_PIX_FMT_MONOBLACK: self = .monob
        case AV_PIX_FMT_PAL8: self = .pal8
        case AV_PIX_FMT_YUVJ420P: self = .yuvj420p
        case AV_PIX_FMT_YUVJ422P: self = .yuvj422p
        case AV_PIX_FMT_YUVJ444P: self = .yuvj444p
        case AV_PIX_FMT_XVMC: self = .xvmc
        case AV_PIX_FMT_UYVY422: self = .uyvy422
        case AV_PIX_FMT_UYYVYY411: self = .uyyvyy411
        case AV_PIX_FMT_BGR8: self = .bgr8
        case AV_PIX_FMT_BGR4: self = .bgr4
        case AV_PIX_FMT_BGR4_BYTE: self = .bgr4_byte
        case AV_PIX_FMT_RGB8: self = .rgb8
        case AV_PIX_FMT_RGB4: self = .rgb4
        case AV_PIX_FMT_RGB4_BYTE: self = .rgb4_byte
        case AV_PIX_FMT_NV12: self = .nv12
        case AV_PIX_FMT_NV21: self = .nv21
        case AV_PIX_FMT_ARGB: self = .argb
        case AV_PIX_FMT_RGBA: self = .rgba
        case AV_PIX_FMT_ABGR: self = .abgr
        case AV_PIX_FMT_BGRA: self = .bgra
        case AV_PIX_FMT_0RGB: self = .zero_rgb
        case AV_PIX_FMT_RGB0: self = .rgb0
        case AV_PIX_FMT_0BGR: self = .zero_bgr
        case AV_PIX_FMT_BGR0: self = .bgr0
        case AV_PIX_FMT_GRAY9BE: self = .gray9be
        case AV_PIX_FMT_GRAY9LE: self = .gray9le
        case AV_PIX_FMT_GRAY10BE: self = .gray10be
        case AV_PIX_FMT_GRAY10LE: self = .gray10le
        case AV_PIX_FMT_GRAY12BE: self = .gray12be
        case AV_PIX_FMT_GRAY12LE: self = .gray12le
        case AV_PIX_FMT_GRAY14BE: self = .gray14be
        case AV_PIX_FMT_GRAY14LE: self = .gray14le
        case AV_PIX_FMT_GRAY16BE: self = .gray16be
        case AV_PIX_FMT_GRAY16LE: self = .gray16le
        case AV_PIX_FMT_YUV440P: self = .yuv440p
        case AV_PIX_FMT_YUVJ440P: self = .yuvj440p
        case AV_PIX_FMT_YUV440P10LE: self = .yuv440p10le
        case AV_PIX_FMT_YUV440P10BE: self = .yuv440p10be
        case AV_PIX_FMT_YUV440P12LE: self = .yuv440p12le
        case AV_PIX_FMT_YUV440P12BE: self = .yuv440p12be
        case AV_PIX_FMT_YUVA420P: self = .yuva420p
        case AV_PIX_FMT_YUVA422P: self = .yuva422p
        case AV_PIX_FMT_YUVA444P: self = .yuva444p
        case AV_PIX_FMT_YUVA420P9BE: self = .yuva420p9be
        case AV_PIX_FMT_YUVA420P9LE: self = .yuva420p9le
        case AV_PIX_FMT_YUVA422P9BE: self = .yuva422p9be
        case AV_PIX_FMT_YUVA422P9LE: self = .yuva422p9le
        case AV_PIX_FMT_YUVA444P9BE: self = .yuva444p9be
        case AV_PIX_FMT_YUVA444P9LE: self = .yuva444p9le
        case AV_PIX_FMT_YUVA420P10BE: self = .yuva420p10be
        case AV_PIX_FMT_YUVA420P10LE: self = .yuva420p10le
        case AV_PIX_FMT_YUVA422P10BE: self = .yuva422p10be
        case AV_PIX_FMT_YUVA422P10LE: self = .yuva422p10le
        case AV_PIX_FMT_YUVA444P10BE: self = .yuva444p10be
        case AV_PIX_FMT_YUVA444P10LE: self = .yuva444p10le
        case AV_PIX_FMT_YUVA420P16BE: self = .yuva420p16be
        case AV_PIX_FMT_YUVA420P16LE: self = .yuva420p16le
        case AV_PIX_FMT_YUVA422P16BE: self = .yuva422p16be
        case AV_PIX_FMT_YUVA422P16LE: self = .yuva422p16le
        case AV_PIX_FMT_YUVA444P16BE: self = .yuva444p16be
        case AV_PIX_FMT_YUVA444P16LE: self = .yuva444p16le
        case AV_PIX_FMT_RGB48BE: self = .rgb48be
        case AV_PIX_FMT_RGB48LE: self = .rgb48le
        case AV_PIX_FMT_RGBA64BE: self = .rgba64be
        case AV_PIX_FMT_RGBA64LE: self = .rgba64le
        case AV_PIX_FMT_RGB565BE: self = .rgb565be
        case AV_PIX_FMT_RGB565LE: self = .rgb565le
        case AV_PIX_FMT_RGB555BE: self = .rgb555be
        case AV_PIX_FMT_RGB555LE: self = .rgb555le
        case AV_PIX_FMT_RGB444BE: self = .rgb444be
        case AV_PIX_FMT_RGB444LE: self = .rgb444le
        case AV_PIX_FMT_BGR48BE: self = .bgr48be
        case AV_PIX_FMT_BGR48LE: self = .bgr48le
        case AV_PIX_FMT_BGRA64BE: self = .bgra64be
        case AV_PIX_FMT_BGRA64LE: self = .bgra64le
        case AV_PIX_FMT_BGR565BE: self = .bgr565be
        case AV_PIX_FMT_BGR565LE: self = .bgr565le
        case AV_PIX_FMT_BGR555BE: self = .bgr555be
        case AV_PIX_FMT_BGR555LE: self = .bgr555le
        case AV_PIX_FMT_BGR444BE: self = .bgr444be
        case AV_PIX_FMT_BGR444LE: self = .bgr444le
        case AV_PIX_FMT_VAAPI: self = .vaapi
        case AV_PIX_FMT_YUV420P9LE: self = .yuv420p9le
        case AV_PIX_FMT_YUV420P9BE: self = .yuv420p9be
        case AV_PIX_FMT_YUV420P10LE: self = .yuv420p10le
        case AV_PIX_FMT_YUV420P10BE: self = .yuv420p10be
        case AV_PIX_FMT_YUV420P12LE: self = .yuv420p12le
        case AV_PIX_FMT_YUV420P12BE: self = .yuv420p12be
        case AV_PIX_FMT_YUV420P14LE: self = .yuv420p14le
        case AV_PIX_FMT_YUV420P14BE: self = .yuv420p14be
        case AV_PIX_FMT_YUV420P16LE: self = .yuv420p16le
        case AV_PIX_FMT_YUV420P16BE: self = .yuv420p16be
        case AV_PIX_FMT_YUV422P9LE: self = .yuv422p9le
        case AV_PIX_FMT_YUV422P9BE: self = .yuv422p9be
        case AV_PIX_FMT_YUV422P10LE: self = .yuv422p10le
        case AV_PIX_FMT_YUV422P10BE: self = .yuv422p10be
        case AV_PIX_FMT_YUV422P12LE: self = .yuv422p12le
        case AV_PIX_FMT_YUV422P12BE: self = .yuv422p12be
        case AV_PIX_FMT_YUV422P14LE: self = .yuv422p14le
        case AV_PIX_FMT_YUV422P14BE: self = .yuv422p14be
        case AV_PIX_FMT_YUV422P16LE: self = .yuv422p16le
        case AV_PIX_FMT_YUV422P16BE: self = .yuv422p16be
        case AV_PIX_FMT_YUV444P16LE: self = .yuv444p16le
        case AV_PIX_FMT_YUV444P16BE: self = .yuv444p16be
        case AV_PIX_FMT_YUV444P10LE: self = .yuv444p10le
        case AV_PIX_FMT_YUV444P10BE: self = .yuv444p10be
        case AV_PIX_FMT_YUV444P9LE: self = .yuv444p9le
        case AV_PIX_FMT_YUV444P9BE: self = .yuv444p9be
        case AV_PIX_FMT_YUV444P12LE: self = .yuv444p12le
        case AV_PIX_FMT_YUV444P12BE: self = .yuv444p12be
        case AV_PIX_FMT_YUV444P14LE: self = .yuv444p14le
        case AV_PIX_FMT_YUV444P14BE: self = .yuv444p14be
        case AV_PIX_FMT_D3D11VA_VLD: self = .d3d11va_vld
        case AV_PIX_FMT_DXVA2_VLD: self = .dxva2_vld
        case AV_PIX_FMT_YA8: self = .ya8
        case AV_PIX_FMT_YA16LE: self = .ya16le
        case AV_PIX_FMT_YA16BE: self = .ya16be
        case AV_PIX_FMT_VIDEOTOOLBOX: self = .videotoolbox_vld
        case AV_PIX_FMT_GBRP: self = .gbrp
        case AV_PIX_FMT_GBRP9LE: self = .gbrp9le
        case AV_PIX_FMT_GBRP9BE: self = .gbrp9be
        case AV_PIX_FMT_GBRP10LE: self = .gbrp10le
        case AV_PIX_FMT_GBRP10BE: self = .gbrp10be
        case AV_PIX_FMT_GBRP12LE: self = .gbrp12le
        case AV_PIX_FMT_GBRP12BE: self = .gbrp12be
        case AV_PIX_FMT_GBRP14LE: self = .gbrp14le
        case AV_PIX_FMT_GBRP14BE: self = .gbrp14be
        case AV_PIX_FMT_GBRP16LE: self = .gbrp16le
        case AV_PIX_FMT_GBRP16BE: self = .gbrp16be
        case AV_PIX_FMT_GBRAP: self = .gbrap
        case AV_PIX_FMT_GBRAP16LE: self = .gbrap16le
        case AV_PIX_FMT_GBRAP16BE: self = .gbrap16be
        case AV_PIX_FMT_VDPAU: self = .vdpau
        case AV_PIX_FMT_XYZ12LE: self = .xyz12le
        case AV_PIX_FMT_XYZ12BE: self = .xyz12be
        default: return nil
        }
    }
}

extension VideoColorSpace {
    init?(space: AVColorSpace) {
        guard space != AVCOL_SPC_NB else {
            return nil
        }
        
        switch space {
        case AVCOL_SPC_RGB: self = .gbr
        case AVCOL_SPC_BT709: self = .bt709
        case AVCOL_SPC_UNSPECIFIED: self = .unknown
        case AVCOL_SPC_RESERVED: self = .reserved
        case AVCOL_SPC_FCC: self = .fcc
        case AVCOL_SPC_BT470BG: self = .bt470bg
        case AVCOL_SPC_SMPTE170M: self = .smpte170m
        case AVCOL_SPC_SMPTE240M: self = .smpte240m
        case AVCOL_SPC_YCGCO: self = .ycgco
        case AVCOL_SPC_BT2020_NCL: self = .bt2020nc
        case AVCOL_SPC_BT2020_CL: self = .bt2020c
        case AVCOL_SPC_SMPTE2085: self = .smpte2085
        case AVCOL_SPC_CHROMA_DERIVED_NCL: self = .chroma_derived_nc
        case AVCOL_SPC_CHROMA_DERIVED_CL: self = .chroma_derived_c
        case AVCOL_SPC_ICTCP: self = .ictcp
        default:
            return nil
        }
    }
}

extension VideoFieldOrder {
    init?(order: AVFieldOrder) {
        switch order {
        case AV_FIELD_UNKNOWN: self = .unknown
        case AV_FIELD_PROGRESSIVE: self = .progressive
        case AV_FIELD_TT: self = .topFirst          //< Top coded_first, top displayed first
        case AV_FIELD_BB: self = .bottomFirst          //< Bottom coded first, bottom displayed first
        case AV_FIELD_TB: self = .topFirstSwapped          //< Top coded first, bottom displayed first
        case AV_FIELD_BT: self = .bottomFirstSwapped
        default:
            return nil
        }
    }
}

func av_rescale(_ a: Int64, _ b: Int64, _ c: Int64) -> Int64 {
    let AV_ROUND_NEAR_INF: UInt32 = 5 ///< Round to nearest and halfway cases away from zero.
    return av_rescale_rnd(a, b, c, AVRounding.init(AV_ROUND_NEAR_INF))
}

// MARK: -

func initFFMpeg(forFile file: URL) -> UnsafeMutablePointer<AVFormatContext>? {
    var pFormatCtx: UnsafeMutablePointer<AVFormatContext>! = nil
    let pFmt: UnsafeMutablePointer<AVInputFormat>? = nil
    
    var format_opts: UnsafeMutablePointer<AVDictionary>? = nil
    withUnsafeMutablePointer(to: &format_opts) { ptr in
        av_dict_set(ptr, "scan_all_pmts", "1", AV_DICT_DONT_OVERWRITE)
        let _ = avformat_open_input(&pFormatCtx, strdup(file.path), pFmt, ptr)
        av_dict_free(ptr)
    }
    
    guard pFormatCtx != nil else {
        return nil
    }
    
    // Retrieve stream information
    guard avformat_find_stream_info(pFormatCtx, nil) >= 0 else {
        avformat_close_input(&pFormatCtx)
        return nil
    }
    
    return pFormatCtx
}

func av_dict_get(data: UnsafeMutablePointer<AVDictionary>!, key: String, previous: UnsafePointer<AVDictionaryEntry>? = nil, flags: Int32) -> String? {
    if let s = av_dict_get(data, key, previous, flags) {
        return String(cString: s.pointee.value)
    } else {
        return nil
    }
}

func getFFMpegChapters(context pFormatCtx: UnsafeMutablePointer<AVFormatContext>!) -> [Chapter] {
    var chapters: [Chapter] = []
    let n_chapters = Int(pFormatCtx.pointee.nb_chapters)
    for i in 0 ..< n_chapters {
        guard let ch = pFormatCtx.pointee.chapters[i]?.pointee else {
            continue
        }
        
        let start = Double(ch.start) * av_q2d(ch.time_base)
        let end = Double(ch.end) * av_q2d(ch.time_base)
        let interval = String(format: "%f - %f", start, end)
        print(interval)
        let title: String?
        if let t = av_dict_get(ch.metadata, "title", nil, AV_DICT_IGNORE_SUFFIX) {
            title = String(cString: t.pointee.value)
        } else {
            title = nil
        }
        chapters.append(Chapter(title: title, start: start, end: end))
    }
    return chapters
}

func getFFMpegLang(data: UnsafeMutablePointer<AVDictionary>!) -> String? {
    let lang: String?
    if let t = av_dict_get(data, "language", nil, 0), let ll = ff_convert_lang_to(t.pointee.value, AV_LANG_ISO639_1) {
        let l = String(cString: ll)
        lang = l != "und" ? l : ""
    } else {
        lang = nil
    }
    return lang
}

func getFFMpegTime(t: Int64) -> Int64 {
    if abs(Double(t)) != Double(AV_NOPTS_VALUE) {
        let d = t + (t <= INT64_MAX - 5000 ? 5000 : 0)
        /*
        var hours, mins, secs, us: Int64
        secs  = d / AV_TIME_BASE
        us    = d % AV_TIME_BASE;
        mins  = secs / 60;
        secs %= 60;
        hours = mins / 60;
        mins %= 60;
        let time = String(format: "%02d:%02d:%02d.%02d", hours, mins, secs, (100 * us) / AV_TIME_BASE)
        print(time)*/
        return d
    } else {
        return -1
    }
}

func getFFMpegTime(t: Int64) -> Double? {
    let d: Int64 = getFFMpegTime(t: t)
    guard d >= 0 else { return nil }
    return Double(d) / Double(AV_TIME_BASE)
}

func getFFMpegVideoInfo(forFile file: URL) -> VideoInfo? {
    var pFormatCtx: UnsafeMutablePointer<AVFormatContext>! = initFFMpeg(forFile: file)
    guard pFormatCtx != nil else { return nil }
    
    defer {
        avformat_close_input(&pFormatCtx)
        avformat_free_context(pFormatCtx)
    }
    
    let streams = getFFMpegMediaStreams(forFile: file, with: &pFormatCtx)
    guard let v = streams.first(where: {$0 is VideoTrackInfo}) as? VideoTrackInfo else { return nil }
    
    let name: String? // A comma separated list of short names for the format.
    if let s = pFormatCtx.pointee.iformat.pointee.name {
        name = String(cString: s)
    } else {
        name = nil
    }
    
    let long_name: String? // Descriptive name for the format, meant to be more human-readable than name.
    if let s = pFormatCtx.pointee.iformat.pointee.long_name {
        long_name = String(cString: s)
    } else {
        long_name = nil
    }
    
    let title: String? = av_dict_get(data: pFormatCtx.pointee.metadata, key: "title", previous: nil, flags: AV_DICT_IGNORE_SUFFIX)
    let encoder: String? = av_dict_get(data: pFormatCtx.pointee.metadata, key: "encoder", previous: nil, flags: AV_DICT_IGNORE_SUFFIX)
    
    let lang = getFFMpegLang(data: pFormatCtx.pointee.metadata)
    
    var t: UnsafeMutablePointer<AVDictionaryEntry>?
    repeat {
        /*
         * Common keys:
         *   title
         *   encoder: "libebml v1.4.1 + libmatroska v1.6.2"
         *   creation_time: "2021-03-05T18:17:38.000000Z"
         */
        t = av_dict_get(pFormatCtx.pointee.metadata, "", t, AV_DICT_IGNORE_SUFFIX)
        if let tt = t?.pointee {
            let key = String(cString: tt.key)
            let value = String(cString: tt.value)
            print("\(key): \(value)")
        }
    } while t != nil
    
    let duration: Double? = getFFMpegTime(t:  pFormatCtx.pointee.duration)
    let start_time: Double? = getFFMpegTime(t: pFormatCtx.pointee.start_time)
    
    let chapters = getFFMpegChapters(context: pFormatCtx)
    
    let video = VideoInfo(
        file: file,
        width: v.width, height: v.height,
        duration: duration ?? v.duration, start_time: start_time ?? v.start_time,
        codec_short_name: name ?? v.codec_short_name, codec_long_name: long_name ?? v.codec_long_name,
        profile: v.profile,
        pixel_format: v.pixel_format, color_space: v.color_space, field_order: v.field_order,
        lang: lang ?? v.lang,
        bitRate: v.bitRate, fps: v.fps, frames: v.frames,
        title: title ?? v.title, encoder: encoder ?? v.encoder,
        isLossless: v.isLossless,
        chapters: chapters,
        video: streams.filter({$0 is VideoTrackInfo}) as! [VideoTrackInfo],
        audio: streams.filter({$0 is AudioTrackInfo}) as! [AudioTrackInfo],
        subtitles: streams.filter({$0 is SubtitleTrackInfo}) as! [SubtitleTrackInfo],
        engine: .ffmpeg
    )
    return video
}

func getFFMpegAudioInfo(forFile file: URL) -> AudioInfo? {
    var pFormatCtx: UnsafeMutablePointer<AVFormatContext>! = initFFMpeg(forFile: file)
    guard pFormatCtx != nil else { return nil }
    
    defer {
        avformat_close_input(&pFormatCtx)
        avformat_free_context(pFormatCtx)
    }
    
    let streams = getFFMpegMediaStreams(forFile: file, with: &pFormatCtx)
    guard let a = streams.first(where: {$0 is AudioTrackInfo}) as? AudioTrackInfo else {
        return nil
    }
    
    let name: String? // A comma separated list of short names for the format.
    if let s = pFormatCtx.pointee.iformat.pointee.name {
        name = String(cString: s)
    } else {
        name = nil
    }
    
    let long_name: String? // Descriptive name for the format, meant to be more human-readable than name.
    if let s = pFormatCtx.pointee.iformat.pointee.long_name {
        long_name = String(cString: s)
    } else {
        long_name = nil
    }
    
    let title: String? = av_dict_get(data: pFormatCtx.pointee.metadata, key: "title", previous: nil, flags: AV_DICT_IGNORE_SUFFIX)
    let encoder: String? = av_dict_get(data: pFormatCtx.pointee.metadata, key: "encoder", previous: nil, flags: AV_DICT_IGNORE_SUFFIX)
    
    let lang = getFFMpegLang(data: pFormatCtx.pointee.metadata)
    
    let duration: Double? = getFFMpegTime(t: pFormatCtx.pointee.duration)
    let start_time: Double? = getFFMpegTime(t: pFormatCtx.pointee.start_time)
    
    let chapters = getFFMpegChapters(context: pFormatCtx)
    
    let audio = AudioInfo(
        file: file,
        duration: duration ?? a.duration, start_time: start_time ?? a.start_time,
        codec_short_name: name ?? a.codec_short_name, codec_long_name: long_name ?? a.codec_long_name,
        lang: lang ?? a.lang,
        bitRate: a.bitRate,
        title: title ?? a.title, encoder: encoder ?? a.encoder,
        isLossless: a.isLossless,
        chapters: chapters,
        channels: a.channels,
        engine: .ffmpeg
        )
    return audio
}

/// Get media info for video/audio format supported by ffmpeg.
func getFFMpegMediaStreams(forFile file: URL) -> [BaseInfo] {
    var pFormatCtx = initFFMpeg(forFile: file)
    
    guard pFormatCtx != nil else {
        return []
    }
    
    defer {
        avformat_close_input(&pFormatCtx)
        avformat_free_context(pFormatCtx)
    }
    
    return getFFMpegMediaStreams(forFile: file, with: &pFormatCtx)
}

func getFFMpegMediaStreams(forFile file: URL, with pFormatCtx: inout UnsafeMutablePointer<AVFormatContext>!) -> [BaseInfo] {
    
    guard pFormatCtx != nil else {
        return []
    }
    
    let mainDuration: Int64 = getFFMpegTime(t: pFormatCtx.pointee.duration)
    
    var streams: [BaseInfo] = []

    for i in 0 ..< Int(pFormatCtx.pointee.nb_streams) {
        guard let st = pFormatCtx.pointee.streams[i] else {
            continue
        }
        var avctx = avcodec_alloc_context3(nil)
        if avctx == nil {
            continue
        }
        defer {
            avcodec_free_context(&avctx)
        }
        avcodec_parameters_to_context(avctx, st.pointee.codecpar)
        
        let start_time: Int64 = getFFMpegTime(t: st.pointee.start_time)
        
        let codec_short_name: String
        if let s = avcodec_get_name(avctx!.pointee.codec_id) {
            codec_short_name = String(cString: s)
        } else {
            codec_short_name = ""
        }
        
        let codec_long_name: String?
        if let cd = avcodec_descriptor_get(avctx!.pointee.codec_id) {
            codec_long_name = String(cString: cd.pointee.long_name)
        } else if let codec = avcodec_find_decoder(avctx!.pointee.codec_id) {
            codec_long_name = String(cString: codec.pointee.long_name)
        } else {
            codec_long_name = nil
        }
        
        let isLossless = (Int32(avctx!.pointee.properties) & FF_CODEC_PROPERTY_LOSSLESS) != 0
        
        /*
         * Common keys:
         *   language
         *   title ("HD 720 Hevc")
         *   BPS-eng (a String of a INT64 value, like "1162383")
         *   DURATION-eng ("02:07:03.667000000")
         *   NUMBER_OF_FRAMES-eng (a String of a INT64 value, like "182968")
         *   NUMBER_OF_BYTES-eng (a String of a INT64 value, like "1107703441")
         *   _STATISTICS_WRITING_APP-eng ("mkvmerge v52.0.0 ('Secret For The Mad') 64-bit")
         *   _STATISTICS_WRITING_DATE_UTC-eng ("2021-03-05 18:17:38")
         *   _STATISTICS_TAGS-eng ("BPS DURATION NUMBER_OF_FRAMES NUMBER_OF_BYTES")
         */
        var t: UnsafeMutablePointer<AVDictionaryEntry>?
        repeat {
            t = av_dict_get(pFormatCtx.pointee.streams[i]!.pointee.metadata, "", t, AV_DICT_IGNORE_SUFFIX)
            if let tt = t?.pointee {
                let key = String(cString: tt.key)
                let value = String(cString: tt.value)
                print("\(key): \(value)")
            }
        } while t != nil
        
        let lang = getFFMpegLang(data: st.pointee.metadata)
        
        let title: String? = av_dict_get(data: st.pointee.metadata, key: "title", previous: nil, flags: AV_DICT_IGNORE_SUFFIX)
        let encoder: String? = av_dict_get(data: st.pointee.metadata, key: "encoder", previous: nil, flags: AV_DICT_IGNORE_SUFFIX)
        
        /*
        var bit_rate: Int64
        if let t = av_dict_get(pFormatCtx.pointee.streams[i]!.pointee.metadata, "BPS", nil, AV_DICT_IGNORE_SUFFIX), let n = Int64(String(cString: t.pointee.value)) {
            bit_rate = n
        } else {
            bit_rate = pFormatCtx.pointee.bit_rate
        }
        */
        
        var duration: Int64 = getFFMpegTime(t: st.pointee.duration)
        if duration < 0 {
            duration = mainDuration >= 0 ? mainDuration : 0
        }
        
        switch avctx!.pointee.codec_type {
        case AVMEDIA_TYPE_VIDEO:
            // let ratio = st.pointee.codecpar.pointee.sample_aspect_ratio.num == 0 ? "" : "\(st.pointee.codecpar.pointee.sample_aspect_ratio.num):\(st.pointee.codecpar.pointee.sample_aspect_ratio.den)"
            let width = Int(avctx!.pointee.width)
            let height = Int(avctx!.pointee.height)
            
            let sample_aspect_ratio: String
            let display_aspect_ratio: String
            if avctx!.pointee.sample_aspect_ratio.num != 0 {
                var num: Int32 = 0
                var den: Int32 = 0
                av_reduce(
                    &num, &den,
                    Int64(avctx!.pointee.width * avctx!.pointee.sample_aspect_ratio.num), Int64(avctx!.pointee.height * avctx!.pointee.sample_aspect_ratio.den),
                    1024 * 1024)
                sample_aspect_ratio = String(format: "%dx%d", avctx!.pointee.sample_aspect_ratio.num, avctx!.pointee.sample_aspect_ratio.den)
                display_aspect_ratio = String(format: "%dx%d", num, den)
            } else {
                sample_aspect_ratio = ""
                display_aspect_ratio = ""
            }
            
            let profile: String?
            if let s = avcodec_profile_name(avctx!.pointee.codec_id, avctx!.pointee.profile) {
                profile = String(cString: s)
            } else {
                profile = nil
            }
            
            var frames = st.pointee.nb_frames
            if frames == 0 && st.pointee.avg_frame_rate.num != 0 {
                frames = Int64((Double(duration) / (Double(st.pointee.avg_frame_rate.num) / Double(st.pointee.avg_frame_rate.den))).rounded())
            }
            
            let bit_rate = avctx!.pointee.bit_rate
            let fps = st.pointee.avg_frame_rate.den != 0 && st.pointee.avg_frame_rate.num != 0 ? av_q2d(st.pointee.avg_frame_rate) : 0 // 24 fps
            
            let v = VideoTrackInfo(
                width: width, height: height,
                duration: Double(duration) / Double(AV_TIME_BASE),
                start_time: Double(start_time) / Double(AV_TIME_BASE),
                codec_short_name: codec_short_name, codec_long_name: codec_long_name,
                profile: profile,
                pixel_format: VideoPixelFormat(pix_fmt: avctx!.pointee.pix_fmt), color_space: VideoColorSpace(space: avctx!.pointee.colorspace),
                field_order: VideoFieldOrder(order: avctx!.pointee.field_order),
                lang: lang,
                bitRate: bit_rate, fps: fps,
                frames: Int(frames),
                title: title, encoder: encoder,
                isLossless: isLossless
            )
            
            streams.append(v)
        case AVMEDIA_TYPE_AUDIO:
            var bit_rate: Int64 = 0
            
            let bits_per_sample = av_get_bits_per_sample(avctx!.pointee.codec_id)
            if bits_per_sample > 0 {
                bit_rate = Int64(avctx!.pointee.sample_rate * avctx!.pointee.channels)
                if bit_rate > INT64_MAX / Int64(bits_per_sample) {
                    bit_rate = 0
                } else {
                    bit_rate *= Int64(bits_per_sample)
                }
            } else {
                bit_rate = avctx!.pointee.bit_rate
            }
            
            let a = AudioTrackInfo(
                duration: Double(duration)/Double(AV_TIME_BASE),
                start_time: Double(start_time) / Double(AV_TIME_BASE),
                codec_short_name: codec_short_name, codec_long_name: codec_long_name,
                lang: lang,
                bitRate: bit_rate,
                title: title, encoder: encoder,
                isLossless: isLossless,
                channels: Int(avctx!.pointee.channels)
            )
            streams.append(a)
            
        case AVMEDIA_TYPE_SUBTITLE:
            let title: String?
            if let t = av_dict_get(pFormatCtx.pointee.streams[i]!.pointee.metadata, "title", nil, 0) {
                title = String(cString: t.pointee.value)
            } else {
                title = nil
            }
            
            streams.append(SubtitleTrackInfo(title: title, lang: lang))
            
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
    guard let video = getFFMpegMediaStreams(forFile: file).first(where: {$0 is VideoTrackInfo}) as? VideoTrackInfo else {
        return nil
    }
    
    let AV_PIX_FMT_FLAG_ALPHA = 1 << 7
    
    let isAlpha: Bool
    if video.pixel_format?.rawValue ?? 0 == AV_PIX_FMT_PAL8.rawValue {
        isAlpha = true
    } else if video.pixel_format?.rawValue ?? 0 & AV_PIX_FMT_FLAG_ALPHA != 0 {
        isAlpha = true
    } else {
        isAlpha = false
    }
    
    return ImageInfo(file: file, width: video.width, height: video.height, dpi: 0, colorMode: "", depth: 0, animated: video.frames > 1, withAlpha: isAlpha)
}
