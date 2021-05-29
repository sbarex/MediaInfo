//
//  SettingsService.swift
//  MediaInfo
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

protocol SettingsService {
    static var XPCProtocol: Protocol { get }
    static var serviceName: String { get }
    
    static var connection: NSXPCConnection { get }
    static var service: MediaInfoSettingsXPCProtocol? { get }
    
    static func initConnection() -> NSXPCConnection
    static func initSettings(connection: NSXPCConnection) -> MediaInfoSettingsXPCProtocol?
    
    static func getSettings(withReply reply: @escaping (Settings) -> Void)
    static func setSettings(_ settings: Settings, withReply reply: @escaping (Bool) -> Void)
}

extension SettingsService {
    static func initConnection() -> NSXPCConnection {
        NSLog("\(Self.serviceName) init connection…")
        
        let connection = NSXPCConnection(serviceName: serviceName)
        connection.interruptionHandler = {
            NSLog("\(Self.serviceName) connection interrupted!")
        }
        connection.invalidationHandler = {
            NSLog("\(Self.serviceName) connection invalidated!")
        }
        connection.remoteObjectInterface = NSXPCInterface(with: Self.XPCProtocol)
        connection.resume()
        NSLog("\(Self.serviceName) initialized (pid %d)", connection.processIdentifier)
        return connection
    }
    
    static func initSettings(connection: NSXPCConnection) -> MediaInfoSettingsXPCProtocol? {
        let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            NSLog("\(Self.serviceName) error: %@", error.localizedDescription)
            print("Received error:", error)
        } as? MediaInfoSettingsXPCProtocol
        return service
    }
    
    static func getSettings(withReply reply: @escaping (Settings) -> Void) {
        guard let service = Self.service else {
            reply(Settings(fromDict: [:]))
            return
        }
        service.getSettings(refresh: true, withReply: { dict in
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
