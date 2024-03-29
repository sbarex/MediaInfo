//
//  ImageUtils.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 25/05/2021.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Foundation
import os.log

/// Get image info for WebP image format.
func getWebPImageInfo(forFile file: URL) -> ImageInfo? {
    let time = CFAbsoluteTimeGetCurrent()
    os_log("Fetch info for image %{private}@ with WebP…", log: OSLog.infoExtraction, type: .debug, file.path)
    
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
        os_log("Unable to decode the image with WebP!", log: OSLog.infoExtraction, type: .error)
        return nil
    }

    // Decode image, always RGBA
    webp_cfg.output.colorspace = webp_cfg.input.has_alpha != 0 ? MODE_rgbA : MODE_RGB
    webp_cfg.options.use_threads = 1
    guard let idec = data.withUnsafeBytes({ (buffer: UnsafeRawBufferPointer) -> OpaquePointer? in
        let unsafeBufferPointer = buffer.bindMemory(to: UInt8.self)

        return WebPIDecode(unsafeBufferPointer.baseAddress!, file_size, &webp_cfg) }) else {
        os_log("Unable to decode the image with WebP!", log: OSLog.infoExtraction, type: .error)
        return nil
    }
    defer {
        WebPIDelete(idec)
    }

    let width: size_t = size_t(webp_cfg.input.width)
    let height: size_t = size_t(webp_cfg.input.height)

    os_log("Image info fetched with WebP in %{public}lf seconds.", log: OSLog.infoExtraction, type: .info, CFAbsoluteTimeGetCurrent() - time)
    return ImageInfo(file: file, width: width, height: height, dpi: 0, colorMode: webp_cfg.input.has_alpha != 0 ? "RGBA" : "RGB", depth: webp_cfg.input.has_alpha != 0 ? 32 : 24, profileName: "", animated: webp_cfg.input.has_animation > 0, withAlpha: webp_cfg.input.has_alpha > 0, colorTable: .regular, metadata: [:], metadataRaw: [:])
}
