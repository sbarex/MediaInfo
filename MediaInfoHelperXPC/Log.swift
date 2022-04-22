//
//  Log.swift
//  MediaInfo
//
//  Created by Sbarex on 10/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = "org.sbarex.mediainfo"

    static let finderExtension = OSLog(subsystem: subsystem, category: "Finder Extension")
    static let infoExtraction = OSLog(subsystem: subsystem, category: "Info Extraction")
    static let menuGeneration = OSLog(subsystem: subsystem, category: "Menu Generation")
    static let helperXPC = OSLog(subsystem: subsystem, category: "Helper XPC")
    static let settingsXPC = OSLog(subsystem: subsystem, category: "Settings XPC")
}

@available(macOS 11.0, *)
extension Logger {
    private static var subsystem = "org.sbarex.mediainfo"

    static let finderExtension = Logger(subsystem: subsystem, category: "Finder Extension")
    static let infoExtraction = Logger(subsystem: subsystem, category: "Info Extraction")
    static let menuGeneration = Logger(subsystem: subsystem, category: "Menu Generation")
    static let helperXPC = Logger(subsystem: subsystem, category: "Helper XPC")
    static let settingsXPC = Logger(subsystem: subsystem, category: "Settings XPC")
}
