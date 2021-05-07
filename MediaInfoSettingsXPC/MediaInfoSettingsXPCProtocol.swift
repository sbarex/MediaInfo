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
    
    func getSettingsWithReply(_ reply: @escaping (NSDictionary) -> Void)
    
    func setSetting(_ settings: NSDictionary, withReply reply: @escaping (Bool) -> Void)
    
    func getSettingsURL(reply: @escaping (_ url: URL?)->Void)
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     _connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"org.sbarex.MediaInfoSettingsXPC"];
     _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MediaInfoSettingsXPCProtocol)];
     [_connectionToService resume];

Once you have a connection to the service, you can use it like this:

     [[_connectionToService remoteObjectProxy] upperCaseString:@"hello" withReply:^(NSString *aString) {
         // We have received a response. Update our text field, but do it on the main thread.
         NSLog(@"Result string was: %@", aString);
     }];

 And, when you are finished with the service, clean up the connection like this:

     [_connectionToService invalidate];
*/
