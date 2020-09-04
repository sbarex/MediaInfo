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
    
    var isImagesHandled = true
    var isPrintHidden = false
    var isCustomPrintHidden = false
    var customDPI = 300
    var unit: PrintUnit = .cm
    var isColorHidden = false
    var isDepthHidden = false
    var isImageIconsHidden = false
    var isImageInfoOnSubMenu = true
    
    var isMediaHandled = true
    var isFramesHidden = true
    var isCodecHidden = true
    var isBPSHidden = true
    var isMediaIconsHidden = false
    var isMediaInfoOnSubMenu = true
    var isTracksGrouped = false
    
    var folders: [URL] = []
    
    static let SharedDomainName: String = "group.org.sbarex.MediaInfo"
    
    private init() {
        let defaults = UserDefaults(suiteName: Settings.SharedDomainName)

        var defaultsDomain: [String: Any] = [:]
        defaultsDomain["image_handled"] = true
        defaultsDomain["print_hidden"] = false
        defaultsDomain["custom_dpi_hidden"] = false
        defaultsDomain["custom_dpi"] = 300
        defaultsDomain["unit"] = 0
        defaultsDomain["color_hidden"] = 0
        defaultsDomain["depth_hidden"] = 0
        defaultsDomain["image_icons_hidden"] = false
        defaultsDomain["image_sub_menu"] = true
        
        defaultsDomain["video_handled"] = true
        defaultsDomain["frames_hidden"] = true
        defaultsDomain["codec_hidden"] = true
        defaultsDomain["bps_hidden"] = true
        defaultsDomain["media_icons_hidden"] = false
        defaultsDomain["media_sub_menu"] = true
            
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
        
        defaults?.set(self.isImagesHandled, forKey: "image_handled")
        defaults?.set(self.isPrintHidden, forKey: "print_hidden")
        defaults?.set(self.isCustomPrintHidden, forKey: "custom_dpi_hidden")
        defaults?.set(self.isColorHidden, forKey: "color_hidden")
        defaults?.set(self.isDepthHidden, forKey: "depth_hidden")
        defaults?.set(self.customDPI, forKey: "custom_dpi")
        defaults?.set(self.unit.rawValue, forKey: "unit")
        defaults?.set(self.isImageIconsHidden, forKey: "image_icons_hidden")
        defaults?.set(self.isImageInfoOnSubMenu, forKey: "image_sub_menu")
        
        defaults?.set(self.isMediaHandled, forKey: "video_handled")
        defaults?.set(self.isFramesHidden, forKey: "frames_hidden")
        defaults?.set(self.isCodecHidden, forKey: "codec_hidden")
        defaults?.set(self.isBPSHidden, forKey: "bps_hidden")
        defaults?.set(self.isTracksGrouped, forKey: "group_tracks")
        defaults?.set(self.isMediaIconsHidden, forKey: "media_icons_hidden")
        defaults?.set(self.isMediaInfoOnSubMenu, forKey: "media_sub_menu")
        
        return defaults?.synchronize() ?? false
    }
    
    func refresh() {
        let defaults = UserDefaults(suiteName: Settings.SharedDomainName)

        self.isImagesHandled = defaults?.bool(forKey: "image_handled") ?? true
        self.isPrintHidden = defaults?.bool(forKey: "print_hidden") ?? false
        self.isCustomPrintHidden = defaults?.bool(forKey: "custom_dpi_hidden") ?? false
        self.isColorHidden = defaults?.bool(forKey: "color_hidden") ?? false
        self.isDepthHidden = defaults?.bool(forKey: "depth_hidden") ?? false
        self.customDPI = defaults?.integer(forKey: "custom_dpi") ?? 300
        self.unit = PrintUnit(rawValue: defaults?.integer(forKey: "unit") ?? 0) ?? .cm
        self.isImageIconsHidden = defaults?.bool(forKey: "image_icons_hidden") ?? false
        self.isImageInfoOnSubMenu = defaults?.bool(forKey: "image_sub_menu") ?? true
        
        self.isMediaHandled = defaults?.bool(forKey: "video_handled") ?? true
        self.isFramesHidden = defaults?.bool(forKey: "frames_hidden") ?? false
        self.isCodecHidden = defaults?.bool(forKey: "codec_hidden") ?? false
        self.isBPSHidden = defaults?.bool(forKey: "bps_hidden") ?? false
        self.isTracksGrouped = defaults?.bool(forKey: "group_tracks") ?? false
        self.isMediaIconsHidden = defaults?.bool(forKey: "media_icons_hidden") ?? false
        self.isMediaInfoOnSubMenu = defaults?.bool(forKey: "media_sub_menu") ?? false
        
        if let d = defaults?.array(forKey: "folders") as? [String] {
            self.folders = d.sorted().map({ URL(fileURLWithPath: $0 )})
        }
    }
}
