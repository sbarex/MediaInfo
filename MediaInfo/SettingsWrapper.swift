//
//  SettingsWrapper.swift
//  MediaInfo
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import os.log

class SettingsWrapper: SettingsService {
    static let serviceName = "org.sbarex.MediaInfoSettingsXPC"
    
    static let XPCProtocol: Protocol = MediaInfoSettingsXPCProtocol.self
    
    static let connection: NSXPCConnection = SettingsWrapper.initConnection()
    
    static let service: MediaInfoSettingsXPCProtocol? = {
        let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            os_log("MediaInfo Settings - Error: %{public}@", log: OSLog.settingsXPC, type: .error, error.localizedDescription)
        } as? MediaInfoSettingsXPCProtocol
        return service
    }()
}
