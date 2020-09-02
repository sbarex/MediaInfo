//
//  ImageUtils.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 22/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Foundation
import ImageIO

struct ImageInfo {
    let width: Int
    let height: Int
    let dpi: Int
    let colorMode: String
    let depth: Int
}

/// Get image info for image format supported by coregraphics.
func getCGImageInfo(forFile url: URL) -> ImageInfo? {
    // Create the image source
    guard let img_src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }

    // Copy images properties
    guard let img_properties = CGImageSourceCopyPropertiesAtIndex(img_src, 0, nil) else {
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
    
    return ImageInfo(width: width, height: height, dpi: dpi, colorMode: color, depth: depth)
}

func get_file_size(_ url: URL) -> size_t {
    if let attr = try? FileManager.default.attributesOfItem(atPath: url.path), let size = attr[.size] as? size_t {
        return size
    }
    return 0
}

/// Get image info for PBM image format.
func getNetPBMImageInfo(forFile url: URL) -> ImageInfo? {
    // Read file
    
    // open the file for reading
    // note: user should be prompted the first time to allow reading from this location
    guard let filePointer:UnsafeMutablePointer<FILE> = fopen(url.path,"r") else {
        // preconditionFailure("Could not open file at \(url.absoluteString)")
        return nil
    }

    defer {
        // remember to close the file when done
        fclose(filePointer)
    }
    
    // a pointer to a null-terminated, UTF-8 encoded sequence of bytes
    var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil

    // the smallest multiple of 16 that will fit the byte array for this line
    var lineCap: Int = 0

    // initial iteration
    var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)

    
    var row = 0

    var width = 0
    var height = 0
    var status = 0
    var color = ""
    var depth = 0
                      
    while bytesRead > 0 && status < 1 {
        if row == 0 {
            // Read the magic code.
            guard let s = String.init(cString:lineByteArrayPointer!, encoding: .ascii)?.trimmingCharacters(in: .whitespaces) else {
                return nil
            }
            
            if s.first != "P" && (s[s.index(s.startIndex, offsetBy: 1)] < "1" || s[s.index(s.startIndex, offsetBy: 1)] > "6") {
                // No valid magic code founded.
                return nil
            }
            if s == "P1" || s == "P4" {
                color = "B/N"
                depth = 1
            } else if s == "P2" || s == "P5" {
                color = "GRAY"
                depth = 8
            } else if s == "P3" || s == "P6" {
                color = "RGB"
                depth = 24
            }
            // isAscii = s == "P1\n" || s == "P2\n" || s == "P3\n"
        } else {
            var n = ""
            var i = 0
            while i < bytesRead {
                var c = lineByteArrayPointer!.advanced(by: i).pointee
                i += 1
                
                var char = Character(UnicodeScalar(UInt8(c)))
                
                if char.isWhitespace {
                    continue
                }
                if char == "#" {
                    // start a comment, skip to next line.
                    break
                }
                
                if char.isNumber {
                    i -= 1
                    while char.isNumber {
                        n += String(char)
                        i += 1
                        c = lineByteArrayPointer!.advanced(by: i).pointee
                        char = Character(UnicodeScalar(UInt8(c)))
                    }
                    if let v = Int(n) {
                        if status == 0 {
                            width = v
                            status += 1
                        } else if status == 1 {
                            height = v
                            status += 1
                            break
                        }
                    }
                    n = ""
                }
            }
        }
        
        row += 1
        // updates number of bytes read, for the next iteration
        bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
    }
    
    return ImageInfo(width: width, height: height, dpi: 0, colorMode: color, depth: depth)
}

/// Get image info for WebP image format.
func getWebPImageInfo(forFile file: URL) -> ImageInfo? {
    // Init WebP decoder
    var webp_cfg = WebPDecoderConfig()
    guard WebPInitDecoderConfig(&webp_cfg) != 0 else {
        return nil
    }

    // Read file
    guard let data = try? Data(contentsOf: file), data.count > 0 else {
        return nil
    }

    let file_size = data.count
    
    guard data.withUnsafeBytes({ (buffer: UnsafeRawBufferPointer) in
        let unsafeBufferPointer = buffer.bindMemory(to: UInt8.self)

        return WebPGetFeatures(unsafeBufferPointer.baseAddress!, file_size, &webp_cfg.input) == VP8_STATUS_OK
    }) else {
        return nil
    }

    // Decode image, always RGBA
    webp_cfg.output.colorspace = webp_cfg.input.has_alpha != 0 ? MODE_rgbA : MODE_RGB
    webp_cfg.options.use_threads = 1
    guard let idec = data.withUnsafeBytes({ (buffer: UnsafeRawBufferPointer) -> OpaquePointer? in
        let unsafeBufferPointer = buffer.bindMemory(to: UInt8.self)

        return WebPIDecode(unsafeBufferPointer.baseAddress!, file_size, &webp_cfg) }) else {
        return nil
    }
    defer {
        WebPIDelete(idec)
    }

    let width: size_t = size_t(webp_cfg.input.width)
    let height: size_t = size_t(webp_cfg.input.height)

    return ImageInfo(width: width, height: height, dpi: 0, colorMode: webp_cfg.input.has_alpha != 0 ? "RGBA" : "RGB", depth: webp_cfg.input.has_alpha != 0 ? 32 : 24)
}


/// Get image info for BPG image format.
func getBPGImageInfo(forFile file: URL) -> ImageInfo? {
    // Decode image
    let bpg_ctx = bpg_decoder_open()
    defer {
        bpg_decoder_close(bpg_ctx)
    }
    
    // Read file
    guard let data = try? Data(contentsOf: file) else {
        return nil
    }
    let size = Int32(data.count)
    guard data.withUnsafeBytes({ (buffer: UnsafeRawBufferPointer) in
        return bpg_decoder_decode(bpg_ctx, buffer.bindMemory(to: UInt8.self).baseAddress!, size)
    }) >= 0 else {
        return nil
    }

    // Get image infos
    var img_info_s = BPGImageInfo()
    bpg_decoder_get_info(bpg_ctx, &img_info_s)
    let width = Int(img_info_s.width)
    let height = Int(img_info_s.height)
    
    let color: String
    let color_space = BPGColorSpaceEnum(UInt32(img_info_s.color_space))
    switch (color_space) {
        case BPG_CS_RGB:
            color = img_info_s.has_alpha != 0 ? "RGBA" : "RGB"
            break;
        case BPG_CS_YCbCr:
            color = "YCbCr"
            break;
        case BPG_CS_YCgCo:
            color = "YCgCo"
            break;
        case BPG_CS_YCbCr_BT709:
            color = "YCbCr_BT709"
            break;
        case BPG_CS_YCbCr_BT2020:
            color = "YCbCr_BT2020"
            break;
        default:
            color = ""
    }

    return ImageInfo(width: width, height: height, dpi: 0, colorMode: color, depth: Int(img_info_s.bit_depth))
}

/// Get image info for svg file format.
func getSVGImageInfo(forFile file: URL) -> ImageInfo? {
    class XMLRealParser: NSObject, XMLParserDelegate {
        var width: Int?
        var height: Int?
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "svg" {
                if let v = attributeDict["width"], let vv = Int(v) {
                    self.width = vv
                }
                if let v = attributeDict["height"], let vv = Int(v) {
                    self.height = vv
                }
                parser.abortParsing()
            }
        }
    }
    guard let parser = XMLParser(contentsOf: file) else {
        return nil
    }
    let delegate = XMLRealParser()
    parser.delegate = delegate
    parser.parse()
    if let w = delegate.width, let h = delegate.height {
        return ImageInfo(width: w, height: h, dpi: 0, colorMode: "", depth: 24)
    } else {
        return nil
    }
}
