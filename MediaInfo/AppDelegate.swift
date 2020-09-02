//
//  AppDelegate.swift
//  MediaInfo
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if let vc = NSApplication.shared.windows.first?.contentViewController as? ViewController {
            vc.willChangeValue(forKey: "isExtensionEnabled")
            vc.didChangeValue(forKey: "isExtensionEnabled")
        }
    }
}
