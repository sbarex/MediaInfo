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
        
        if defaultsDomain["version"] as? Double == nil {
            let stdSettings = Self.getStandardSettings()
            imageMenuItems = stdSettings.imageMenuItems
            videoMenuItems = stdSettings.videoMenuItems
            audioMenuItems = stdSettings.audioMenuItems
            pdfMenuItems = stdSettings.pdfMenuItems
            officeMenuItems = stdSettings.officeMenuItems
            archiveMenuItems = stdSettings.archiveMenuItems
        }
    }
    
    static func initDefaults() {
        let settings = Self.getStandardSettings()
        
        let defaults = UserDefaults(suiteName: Settings.SharedDomainName)
        let defaultsDomain: [String: Any] = settings.toDictionary()
        
        defaults?.register(defaults: defaultsDomain)
    }
    
    @discardableResult
    func synchronize() -> Bool {
        let defaults = UserDefaults.standard
        var defaultsDomain = defaults.persistentDomain(forName: Settings.SharedDomainName) ?? [:]
        
        let d = self.toDictionary()
    
        for s in d {
            defaultsDomain[s.key] = s.value
        }
        for s in defaultsDomain {
            if !d.keys.contains(s.key) {
                defaultsDomain.removeValue(forKey: s.key)
            }
        }
        
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
