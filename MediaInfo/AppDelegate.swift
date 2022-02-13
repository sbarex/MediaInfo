//
//  AppDelegate.swift
//  MediaInfo
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import Sparkle
import Kanna

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var userDriver: SPUStandardUserDriver?
    var updater: SPUUpdater?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let hostBundle = Bundle.main
        let applicationBundle = hostBundle
        
        self.userDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil)
        self.updater = SPUUpdater(hostBundle: hostBundle, applicationBundle: applicationBundle, userDriver: self.userDriver!, delegate: nil)
        
        do {
            try self.updater!.start()
        } catch {
            // print("Failed to start updater with error: \(error)")
            
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Updater Error", comment: "")
            alert.informativeText = NSLocalizedString("The Updater failed to start. For detailed error information, check the Console.app log.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }
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
    
    @IBAction func revealSettingsFile(_ sender: Any) {
        SettingsWrapper.service?.getSettingsURL(reply: { (url) in
            if let u = url, FileManager.default.fileExists(atPath: u.path) {
                // Open the Finder to the settings file.
                NSWorkspace.shared.activateFileViewerSelecting([u])
            } else {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Settings not found!", comment: "")
                alert.informativeText = NSLocalizedString("You probably haven't customize the standard settings.", comment: "")
                alert.addButton(withTitle: NSLocalizedString("Close", comment: ""))
                alert.alertStyle = .informational
                
                alert.runModal()
            }
        })
    }
    
    @IBAction func checkForUpdates(_ sender: Any)
    {
        self.updater?.checkForUpdates()
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.action == #selector(self.checkForUpdates(_:)) {
            return self.updater?.canCheckForUpdates ?? false
        }
        return true
    }
}
