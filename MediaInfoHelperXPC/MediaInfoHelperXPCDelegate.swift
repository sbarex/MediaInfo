//
//  MediaInfoHelperXPCDelegate.swift
//  MediaInfoHelperXPC
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

class MediaInfoHelperXPCDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
        
        // Configure the connection.
        // First, set the interface that the exported object implements.
        
        newConnection.exportedInterface = NSXPCInterface(with: MediaInfoHelperXPCProtocol.self)
        // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
        let exportedObject = MediaInfoHelperXPC()
        
        newConnection.exportedObject = exportedObject
        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()
        // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
        return true
    }
}
