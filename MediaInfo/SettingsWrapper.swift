//
//  SettingsWrapper.swift
//  MediaInfo
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

import MediaInfoSettingsXPC

class SettingsWrapper {
    static let serviceName = "org.sbarex.MediaInfoSettingsXPC"
    static let connection: NSXPCConnection = {
        NSLog("MediaInfoSettingsXPC init connection…")
        
        let connection = NSXPCConnection(serviceName: serviceName)
        connection.interruptionHandler = {
            NSLog("MediaInfoSettingsXPC connection interrupted!")
        }
        connection.invalidationHandler = {
            NSLog("MediaInfoSettingsXPC connection invalidated!")
        }
        connection.remoteObjectInterface = NSXPCInterface(with: MediaInfoSettingsXPCProtocol.self)
        connection.resume()
        NSLog("MediaInfoSettingsXPC initialized (pid %d)", connection.processIdentifier)
        return connection
    }()
    
    static let service: MediaInfoSettingsXPCProtocol? = {
        let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            NSLog("MediaInfoSettingsXPC error: %@", error.localizedDescription)
            print("Received error:", error)
        } as? MediaInfoSettingsXPCProtocol
        return service
    }()
    
    static func getSettings(withReply reply: @escaping (Settings) -> Void) {
        guard let service = Self.service else {
            reply(Settings(fromDict: [:]))
            return
        }
        service.getSettingsWithReply({ dict in
            guard let s = dict as? [String: AnyHashable] else {
                reply(Settings(fromDict: [:]))
                return
            }
            reply(Settings(fromDict: s))
        })
    }
    
    static func setSettings(_ settings: Settings, withReply reply: @escaping (Bool) -> Void) {
        guard let service = Self.service else {
            reply(false)
            return
        }
        service.setSetting(settings.toDictionary() as NSDictionary, withReply: reply)
    }
}
