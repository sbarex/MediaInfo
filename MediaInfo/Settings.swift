//
//  Settings.swift
//  MediaInfo
//
//  Created by Sbarex on 04/09/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Foundation

enum PrintUnit: Int {
    case cm
    case mm
    case inch
}

class Settings {
    static let shared = Settings()
    
    var isIconHidden = false
    var isInfoOnSubMenu = true
    var isInfoOnMainItem = false
    var isFileSizeHidden = true
    var isRatioHidden = false
    var isResolutionNameHidden = false
    
    var isImagesHandled = true
    var isPrintHidden = false
    var isCustomPrintHidden = false
    var customDPI = 300
    var unit: PrintUnit = .cm
    var isColorHidden = false
    var isDepthHidden = false
    
    var isMediaHandled = true
    var isFramesHidden = true
    var isCodecHidden = true
    var isBPSHidden = true
    var isTracksGrouped = false
    
    var folders: [URL] = []
    
    static let SharedDomainName: String = "group.org.sbarex.MediaInfo"
    
    private init() {
        let defaults = UserDefaults(suiteName: Settings.SharedDomainName)

        var defaultsDomain: [String: Any] = [:]
        
        defaultsDomain["icons"] = true
        defaultsDomain["sub_menu"] = true
        defaultsDomain["file_size"] = false
        defaultsDomain["ratio"] = true
        defaultsDomain["resolutio-name"] = true
        
        defaultsDomain["image_handled"] = true
        defaultsDomain["print_hidden"] = false
        defaultsDomain["custom_dpi_hidden"] = false
        defaultsDomain["custom_dpi"] = 300
        defaultsDomain["unit"] = 0
        defaultsDomain["color_hidden"] = 0
        defaultsDomain["depth_hidden"] = 0
        
        defaultsDomain["video_handled"] = true
        defaultsDomain["frames_hidden"] = true
        defaultsDomain["codec_hidden"] = true
        defaultsDomain["bps_hidden"] = true
        defaultsDomain["group_tracks"] = false
        
        defaultsDomain["folders"] = []
        
        defaults?.register(defaults: defaultsDomain)
        
        self.refresh()
    }
    
    @discardableResult
    func synchronize() -> Bool {
        let defaults = UserDefaults(suiteName: Settings.SharedDomainName)
        
        let folders = Array(Set(self.folders.map({ $0.path })))
        defaults?.set(folders, forKey: "folders")
        
        defaults?.set(!self.isIconHidden, forKey: "icons")
        defaults?.set(self.isInfoOnSubMenu, forKey: "sub_menu")
        defaults?.set(self.isInfoOnMainItem, forKey: "main_info")
        defaults?.set(!self.isFileSizeHidden, forKey: "file_size")
        defaults?.set(!self.isRatioHidden, forKey: "ratio")
        defaults?.set(!self.isResolutionNameHidden, forKey: "resolution-name")
        
        defaults?.set(self.isImagesHandled, forKey: "image_handled")
        defaults?.set(self.isPrintHidden, forKey: "print_hidden")
        defaults?.set(self.isCustomPrintHidden, forKey: "custom_dpi_hidden")
        defaults?.set(self.isColorHidden, forKey: "color_hidden")
        defaults?.set(self.isDepthHidden, forKey: "depth_hidden")
        defaults?.set(self.customDPI, forKey: "custom_dpi")
        defaults?.set(self.unit.rawValue, forKey: "unit")
        
        defaults?.set(self.isMediaHandled, forKey: "video_handled")
        defaults?.set(self.isFramesHidden, forKey: "frames_hidden")
        defaults?.set(self.isCodecHidden, forKey: "codec_hidden")
        defaults?.set(self.isBPSHidden, forKey: "bps_hidden")
        defaults?.set(self.isTracksGrouped, forKey: "group_tracks")
        
        return defaults?.synchronize() ?? false
    }
    
    func refresh() {
        let defaults = UserDefaults(suiteName: Settings.SharedDomainName)

        self.isIconHidden = !(defaults?.bool(forKey: "icons") ?? true)
        self.isInfoOnSubMenu = defaults?.bool(forKey: "sub_menu") ?? true
        self.isInfoOnMainItem = defaults?.bool(forKey: "main_info") ?? true
        self.isFileSizeHidden = !(defaults?.bool(forKey: "file_size") ?? false)
        self.isRatioHidden = !(defaults?.bool(forKey: "ratio") ?? true)
        self.isResolutionNameHidden = !(defaults?.bool(forKey: "resolution-name") ?? true)
        
        self.isImagesHandled = defaults?.bool(forKey: "image_handled") ?? true
        self.isPrintHidden = defaults?.bool(forKey: "print_hidden") ?? false
        self.isCustomPrintHidden = defaults?.bool(forKey: "custom_dpi_hidden") ?? false
        self.isColorHidden = defaults?.bool(forKey: "color_hidden") ?? false
        self.isDepthHidden = defaults?.bool(forKey: "depth_hidden") ?? false
        self.customDPI = defaults?.integer(forKey: "custom_dpi") ?? 300
        self.unit = PrintUnit(rawValue: defaults?.integer(forKey: "unit") ?? 0) ?? .cm
        
        self.isMediaHandled = defaults?.bool(forKey: "video_handled") ?? true
        self.isFramesHidden = defaults?.bool(forKey: "frames_hidden") ?? false
        self.isCodecHidden = defaults?.bool(forKey: "codec_hidden") ?? false
        self.isBPSHidden = defaults?.bool(forKey: "bps_hidden") ?? false
        self.isTracksGrouped = defaults?.bool(forKey: "group_tracks") ?? false
        
        if let d = defaults?.array(forKey: "folders") as? [String] {
            self.folders = d.sorted().map({ URL(fileURLWithPath: $0 )})
        }
    }
}
