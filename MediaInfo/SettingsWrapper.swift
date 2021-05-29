//
//  SettingsWrapper.swift
//  MediaInfo
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class SettingsWrapper: SettingsService {
    static let serviceName = "org.sbarex.MediaInfoSettingsXPC"
    
    static let XPCProtocol: Protocol = MediaInfoSettingsXPCProtocol.self
    
    static let connection: NSXPCConnection = SettingsWrapper.initConnection()
    
    static let service: MediaInfoSettingsXPCProtocol? = {
        let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            NSLog("MediaInfoSettingsXPC error: %@", error.localizedDescription)
            print("Received error:", error)
        } as? MediaInfoSettingsXPCProtocol
        return service
    }()
}
