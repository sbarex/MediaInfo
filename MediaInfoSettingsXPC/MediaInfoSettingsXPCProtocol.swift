//
//  MediaInfoSettingsXPCProtocol.swift
//  MediaInfoSettingsXPC
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@objc public protocol MediaInfoSettingsXPCProtocol {
    // func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void)
    
    func getSettings(refresh: Bool, withReply reply: @escaping (NSDictionary) -> Void)
    func setSetting(_ settings: NSDictionary, withReply reply: @escaping (Bool) -> Void)
    
    func getSettingsURL(reply: @escaping (_ url: URL?)->Void)
}
