//
//  ViewController.swift
//  MediaInfo
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import FinderSync

class ViewController: NSViewController {
    @objc dynamic var isImageHandled: Bool = true {
        willSet {
            self.willChangeValue(forKey: "isDPIEnabled")
        }
        didSet {
            self.didChangeValue(forKey: "isDPIEnabled")
        }
    }
    @objc dynamic var isPrintedSizeHidden: Bool = false
    @objc dynamic var isCustomDPIHidden: Bool = false  {
        willSet {
            self.willChangeValue(forKey: "isDPIEnabled")
        }
        didSet {
            self.didChangeValue(forKey: "isDPIEnabled")
        }
    }
    @objc dynamic var customDPI: Int = 300
    @objc dynamic var unit: Int = 0
    @objc dynamic var isColorHidden: Bool = false
    @objc dynamic var isDepthHidden: Bool = false
    @objc dynamic var isImageIconHidden: Bool = false
    @objc dynamic var isImageInfoOnSubmenu: Bool = true
    
    @objc dynamic var isDPIEnabled: Bool {
        return isImageHandled && !isCustomDPIHidden
    }
    
    @objc dynamic var isVideoHandled: Bool = true
    @objc dynamic var isFramesHidden: Bool = false
    @objc dynamic var isCodecHidden: Bool = false
    @objc dynamic var isBPSHidden: Bool = false
    @objc dynamic var isTracksGrouped: Bool = false
    @objc dynamic var isMediaIconHidden: Bool = false
    @objc dynamic var isMediaInfoOnSubmenu: Bool = true
    
    @objc dynamic var isExtensionEnabled: Bool {
        return FIFinderSyncController.isExtensionEnabled
    }
    
    var folders: [URL] = []
    
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults(suiteName: SharedDomainName)

        var defaultsDomain: [String: Any] = [:]
        defaultsDomain["image_handled"] = true
        defaultsDomain["print_hidden"] = false
        defaultsDomain["custom_dpi_hidden"] = false
        defaultsDomain["custom_dpi"] = 300
        defaultsDomain["unit"] = 0
        defaultsDomain["color_hidden"] = 0
        defaultsDomain["depth_hidden"] = 0
        defaultsDomain["image_icons_hidden"] = false
        defaultsDomain["image_sub_menu"] = true
        
        defaultsDomain["video_handled"] = true
        defaultsDomain["frames_hidden"] = true
        defaultsDomain["codec_hidden"] = true
        defaultsDomain["bps_hidden"] = true
        defaultsDomain["media_icons_hidden"] = false
        defaultsDomain["media_sub_menu"] = true
            
        defaultsDomain["group_tracks"] = false
        
        defaultsDomain["folders"] = []
        
        defaults?.register(defaults: defaultsDomain)
        
        self.isImageHandled = defaults?.bool(forKey: "image_handled") ?? true
        self.isPrintedSizeHidden = defaults?.bool(forKey: "print_hidden") ?? false
        self.isCustomDPIHidden = defaults?.bool(forKey: "custom_dpi_hidden") ?? false
        self.isColorHidden = defaults?.bool(forKey: "color_hidden") ?? false
        self.isDepthHidden = defaults?.bool(forKey: "depth_hidden") ?? false
        self.customDPI = defaults?.integer(forKey: "custom_dpi") ?? 300
        self.unit = defaults?.integer(forKey: "unit") ?? 0
        self.isImageIconHidden = defaults?.bool(forKey: "image_icons_hidden") ?? false
        self.isImageInfoOnSubmenu = defaults?.bool(forKey: "image_sub_menu") ?? true
        
        self.isVideoHandled = defaults?.bool(forKey: "video_handled") ?? true
        self.isFramesHidden = defaults?.bool(forKey: "frames_hidden") ?? false
        self.isCodecHidden = defaults?.bool(forKey: "codec_hidden") ?? false
        self.isBPSHidden = defaults?.bool(forKey: "bps_hidden") ?? false
        self.isTracksGrouped = defaults?.bool(forKey: "group_tracks") ?? false
        self.isMediaIconHidden = defaults?.bool(forKey: "media_icons_hidden") ?? false
        self.isMediaInfoOnSubmenu = defaults?.bool(forKey: "media_sub_menu") ?? false
        
        if let d = defaults?.array(forKey: "folders") as? [String] {
            self.folders = d.sorted().map({ URL(fileURLWithPath: $0 )})
        }
        
        DispatchQueue.main.async {
            if !FIFinderSyncController.isExtensionEnabled {
                let p = NSAlert()
                p.messageText = NSLocalizedString("Finder extension not enabled", comment: "")
                // p.informativeText = "The finder sync extension is not enabled."
                p.alertStyle = .warning
                p.addButton(withTitle: NSLocalizedString("Enable", comment: ""))
                p.addButton(withTitle: NSLocalizedString("Ignore", comment: ""))
                if p.runModal() == .alertFirstButtonReturn {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
            }
        }
        // print(FIFinderSyncController.isExtensionEnabled ? "Extension enabled" : "Extension not enabled")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func doAddFolder(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        // dialog.title                   = "Choose an archive file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles = false
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        // dialog.allowedFileTypes        = ["txt"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url {
                self.folders.append(result)
                self.folders.sort(by: { $0.path < $1.path })
                self.tableView.reloadData()
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func doRemoveFolder(_ sender: Any) {
        guard tableView.selectedRow >= 0 else {
            return
        }
        self.folders.remove(at: tableView.selectedRow)
        self.tableView.reloadData()
    }

    @IBAction func doSave(_ sender: Any) {
        let folders = Array(Set(self.folders.map({ $0.path })))
        if folders.isEmpty {
            let p = NSAlert()
            p.messageText = NSLocalizedString("No folders selected to be monitored", comment: "")
            p.informativeText = NSLocalizedString("Are you sure you want to continue?", comment: "")
            p.alertStyle = .warning
            p.addButton(withTitle: NSLocalizedString("Continue", comment: "")).keyEquivalent="\r"
            p.addButton(withTitle: NSLocalizedString("Cancel", comment: "")).keyEquivalent = "\u{1b}" // esc
            let r = p.runModal()
            if r == .alertSecondButtonReturn {
                return
            }
        }
        
        let defaults = UserDefaults(suiteName: SharedDomainName)
        let current_folders = defaults?.array(forKey: "folder") as? [String] ?? [""]
        
        defaults?.set(folders, forKey: "folders")
        
        defaults?.set(self.isImageHandled, forKey: "image_handled")
        defaults?.set(self.isPrintedSizeHidden, forKey: "print_hidden")
        defaults?.set(self.isCustomDPIHidden, forKey: "custom_dpi_hidden")
        defaults?.set(self.isColorHidden, forKey: "color_hidden")
        defaults?.set(self.isDepthHidden, forKey: "depth_hidden")
        defaults?.set(self.customDPI, forKey: "custom_dpi")
        defaults?.set(self.unit, forKey: "unit")
        defaults?.set(self.isImageIconHidden, forKey: "image_icons_hidden")
        defaults?.set(self.isImageInfoOnSubmenu, forKey: "image_sub_menu")
        
        defaults?.set(self.isVideoHandled, forKey: "video_handled")
        defaults?.set(self.isFramesHidden, forKey: "frames_hidden")
        defaults?.set(self.isCodecHidden, forKey: "codec_hidden")
        defaults?.set(self.isBPSHidden, forKey: "bps_hidden")
        defaults?.set(self.isTracksGrouped, forKey: "group_tracks")
        defaults?.set(self.isMediaIconHidden, forKey: "media_icons_hidden")
        defaults?.set(self.isMediaInfoOnSubmenu, forKey: "media_sub_menu")
        
        defaults?.synchronize()
        
        if current_folders != folders && FIFinderSyncController.isExtensionEnabled {
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(rawValue: "MediaInfoMonitoredFolderChanged"), object: Bundle.main.bundleIdentifier, userInfo: nil, options: [.deliverImmediately])
        }
    
        self.view.window?.orderOut(sender)
    }

    @IBAction func doClose(_ sender: Any) {
        self.view.window?.orderOut(sender)
    }
    
    @IBAction func openSystemPreferences(_ sender: Any) {
        FIFinderSyncController.showExtensionManagementInterface()
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.folders.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.folders[row].path
    }
}

extension ViewController: NSTableViewDelegate {
    
}

