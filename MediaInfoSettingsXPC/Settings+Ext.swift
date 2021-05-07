//
//  Settings+Ext.swift
//  MediaInfo
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

extension Settings {
    convenience init(fromDomain name: String) {
        let defaults = UserDefaults.standard
        // Remember that macOS store the precerences inside a cache. If you manual edit the preferences file you need to reset this cache:
        // $ killall -u $USER cfprefsd
        let defaultsDomain = defaults.persistentDomain(forName: name) as? [String: AnyHashable] ?? [:]
        
        self.init(fromDict: defaultsDomain)
    }
    
    static func initDefaults() {
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
    }
    
    @discardableResult
    func synchronize() -> Bool {
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: Settings.SharedDomainName) ?? [:]
                
        let folders = Array(Set(self.folders.map({ $0.path })))
        defaultsDomain["folders"] = folders
        
        defaultsDomain["icons"] = !self.isIconHidden
        defaultsDomain["sub_menu"] = self.isInfoOnSubMenu
        defaultsDomain["main_info"] = self.isInfoOnMainItem
        defaultsDomain["file_size"] = !self.isFileSizeHidden
        defaultsDomain["ratio"] = !self.isRatioHidden
        defaultsDomain["ratio-precise"] = self.isRatioPrecise
        defaultsDomain["resolution-name"] = !self.isResolutionNameHidden
        
        defaultsDomain["image_handled"] = self.isImagesHandled
        defaultsDomain["print_hidden"] = self.isPrintHidden
        defaultsDomain["custom_dpi_hidden"] = self.isCustomPrintHidden
        defaultsDomain["color_hidden"] = self.isColorHidden
        defaultsDomain["depth_hidden"] = self.isDepthHidden
        defaultsDomain["custom_dpi"] = self.customDPI
        defaultsDomain["unit"] = self.unit.rawValue
        
        defaultsDomain["video_handled"] = self.isMediaHandled
        defaultsDomain["frames_hidden"] = self.isFramesHidden
        defaultsDomain["codec_hidden"] = self.isCodecHidden
        defaultsDomain["bps_hidden"] = self.isBPSHidden
        defaultsDomain["group_tracks"] = self.isTracksGrouped
        
        let userDefaults = UserDefaults()
        userDefaults.setPersistentDomain(defaultsDomain, forName: Settings.SharedDomainName)
        
        if userDefaults.synchronize() {
            DistributedNotificationCenter.default().postNotificationName(.MediaInfoSettingsChanged, object: Bundle.main.bundleIdentifier, userInfo: nil, options: [.deliverImmediately])
            return true
        } else {
            return false
        }
    }
    
}
