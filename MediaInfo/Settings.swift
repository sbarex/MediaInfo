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
    var isIconHidden = false
    var isInfoOnSubMenu = true
    var isInfoOnMainItem = false
    var isFileSizeHidden = true
    var isRatioHidden = false
    var isRatioPrecise = false
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
    
    static let SharedDomainName: String = "org.sbarex.MediaInfo"
    
    init(fromDict dict: [String: AnyHashable]) {
        refresh(fromDict: dict)
    }
    
    func refresh(fromDict defaultsDomain: [String: AnyHashable]) {
        self.isIconHidden = !(defaultsDomain["icons"] as? Bool ?? true)
        self.isInfoOnSubMenu = defaultsDomain["sub_menu"] as? Bool ?? true
        self.isInfoOnMainItem = defaultsDomain["main_info"] as? Bool ?? true
        self.isFileSizeHidden = !(defaultsDomain["file_size"] as? Bool ?? false)
        self.isRatioHidden = !(defaultsDomain["ratio"] as? Bool ?? true)
        self.isRatioPrecise = defaultsDomain["ratio-precise"] as? Bool ?? true
        self.isResolutionNameHidden = !(defaultsDomain["resolution-name"] as? Bool ?? true)
        
        self.isImagesHandled = defaultsDomain["image_handled"] as? Bool ?? true
        self.isPrintHidden = defaultsDomain["print_hidden"] as? Bool ?? false
        self.isCustomPrintHidden = defaultsDomain["custom_dpi_hidden"] as? Bool ?? false
        self.isColorHidden = defaultsDomain["color_hidden"] as? Bool ?? false
        self.isDepthHidden = defaultsDomain["depth_hidden"] as? Bool ?? false
        self.customDPI = defaultsDomain["custom_dpi"] as? Int ?? 300
        self.unit = PrintUnit(rawValue: defaultsDomain["unit"] as? Int ?? 0) ?? .cm
        
        self.isMediaHandled = defaultsDomain["video_handled"] as? Bool ?? true
        self.isFramesHidden = defaultsDomain["frames_hidden"] as? Bool ?? false
        self.isCodecHidden = defaultsDomain["codec_hidden"] as? Bool ?? false
        self.isBPSHidden = defaultsDomain["bps_hidden"] as? Bool ?? false
        self.isTracksGrouped = defaultsDomain["group_tracks"] as? Bool ?? false
        
        if let d = defaultsDomain["folders"] as? [String] {
            self.folders = d.sorted().map({ URL(fileURLWithPath: $0 )})
        }
    }
    
    func toDictionary() -> [String: AnyHashable] {
        var dict: [String: AnyHashable] = [:]
        let folders = Array(Set(self.folders.map({ $0.path })))
        dict["folders"] = folders
        
        dict["icons"] = !self.isIconHidden
        dict["sub_menu"] = self.isInfoOnSubMenu
        dict["main_info"] = self.isInfoOnMainItem
        dict["file_size"] = !self.isFileSizeHidden
        dict["ratio"] = !self.isRatioHidden
        dict["ratio-precise"] = self.isRatioPrecise
        dict["resolution-name"] = !self.isResolutionNameHidden
        
        dict["image_handled"] = self.isImagesHandled
        dict["print_hidden"] = self.isPrintHidden
        dict["custom_dpi_hidden"] = self.isCustomPrintHidden
        dict["color_hidden"] = self.isColorHidden
        dict["depth_hidden"] = self.isDepthHidden
        dict["custom_dpi"] = self.customDPI
        dict["unit"] = self.unit.rawValue
        
        dict["video_handled"] = self.isMediaHandled
        dict["frames_hidden"] = self.isFramesHidden
        dict["codec_hidden"] = self.isCodecHidden
        dict["bps_hidden"] = self.isBPSHidden
        dict["group_tracks"] = self.isTracksGrouped
        
        return dict
    }
}
