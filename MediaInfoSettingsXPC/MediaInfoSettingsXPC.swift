//
//  MediaInfoSettingsXPC.swift
//  MediaInfoSettingsXPC
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class MediaInfoSettingsXPC: NSObject, MediaInfoSettingsXPCProtocol {
    /// Return the folder for the application support files.
    static var preferencesUrl: URL? {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Preferences")
    }
    
    override init() {
        super.init()
        Settings.initDefaults()
    }
    
    /*
    func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
        let response = string.uppercased()
        reply(response)
    }
    */
    
    func getSettingsWithReply(_ reply: @escaping (NSDictionary) -> Void) {
        let settings = Settings(fromDomain: Settings.SharedDomainName)
        reply(settings.toDictionary() as NSDictionary)
    }
    
    func setSetting(_ settings_dict: NSDictionary, withReply reply: @escaping (Bool) -> Void) {
        if let dict = settings_dict as? [String: AnyHashable] {
            let settings = Settings(fromDomain: Settings.SharedDomainName)
            settings.refresh(fromDict: dict)
            reply(settings.synchronize())
        } else {
            reply(false)
        }
    }
    
    func getSettingsURL(reply: @escaping (_ url: URL?)->Void) {
        reply(type(of: self).preferencesUrl?.appendingPathComponent(Settings.SharedDomainName + ".plist"))
    }
}
